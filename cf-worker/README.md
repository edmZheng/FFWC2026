# ffwc-proxy — Cloudflare Worker

代理 [Highlightly Soccer API](https://highlightly.net) 的 lineups 端点。KV 缓存把
Highlightly Basic Free 配额（100 req/天）放大成事实无限。

**生产 URL**：`https://ffwc-proxy.randomdre13.workers.dev`

## 端点

| 路径 | 上游 | 缓存 TTL |
|---|---|---|
| `GET /health` | — | 无 |
| `GET /matches?date=YYYY-MM-DD` | `/matches?leagueId=1635&season=2026&date=...` | 5 min |
| `GET /matches`（无 date 全量） | `/matches?leagueId=1635&season=2026`（自动分页聚合 100/页） | 5 min |
| `GET /lineups/:matchId` | `/lineups/:matchId` | 24 h |

所有响应头 `x-cache: HIT|MISS` 标识是否命中 KV。`leagueId` 写死 `1635`（WC 2026），`season` 写死 `2026`。

## 部署

```bash
cd cf-worker
wrangler deploy                  # 重新发布
wrangler tail                    # 看实时请求日志（调试用）
```

`wrangler deploy` 输出会显示 Worker URL 和绑定的 KV / 环境变量列表。

## 配置项

`wrangler.toml`：

| 字段 | 值 |
|---|---|
| `name` | `ffwc-proxy` |
| `main` | `src/index.js` |
| `compatibility_date` | `2026-05-01` |
| KV binding `CACHE` | namespace id（已绑） |
| `HL_BASE` | `https://soccer.highlightly.net` |
| `WC_LEAGUE_ID` | `1635` |
| `WC_SEASON` | `2026` |
| `MATCHES_TTL` | `300` |
| `LINEUPS_TTL` | `86400` |

`HL_API_KEY` **不在** `wrangler.toml`，走 secret。

## 轮换 Highlightly API key

```bash
wrangler secret put HL_API_KEY
# 粘贴新 key，回车
```

旧 key 立即失效。Worker 无需重新部署。

## KV 调试

```bash
wrangler kv key list --binding=CACHE                 # 列所有缓存 key
wrangler kv key get --binding=CACHE "l:1267497204"   # 看单条
wrangler kv key delete --binding=CACHE "m:all"       # 清单条（如想强制刷新）
```

key 命名：`m:<date|all>` = matches，`l:<highlightlyMatchId>` = lineups。

## 配额账本

| 项 | 限额 | 当前消耗 |
|---|---|---|
| Highlightly Basic | 100 req/天 | 预计 < 11/天（KV 命中保护） |
| Cloudflare Workers Free | 100k req/天 | App 实际 < 1k/天即足 |
| KV 写 | 1k/天 | 上游每次 miss 才写，远低于 |
| KV 读 | 100k/天 | 命中模式下基本不撞墙 |

千用户共用一份 KV 缓存，上游消耗 ≠ 用户量。

## 与 Flutter 端的契约

**2026-06-10 起 Flutter 端已移除 lineups 接入**（无 `lineup_repository`、无 `/match/:id` 详情页）。Worker 仍可按下列契约供将来复用或其它客户端调用：

- 客户端用 Highlightly 赛事 id 请求 `GET /lineups/{highlightlyId}`
- worldcup26.ir id → Highlightly id 映射见 `assets/data/match_id_map.json`（由 `scripts/build_match_id_map.py` 维护）
- 映射未覆盖（淘汰赛占位符）→ 客户端应静默隐藏首发块

## 重建映射表（淘汰赛对阵敲钉后）

```bash
python scripts/build_match_id_map.py
```

会重新拉 `worldcup26.ir/get/games` + Worker `/matches`，按 (date ±1d, {home, away}) 重新 join，写回 `assets/data/match_id_map.json`。需要重打 APK 才生效（数据是 bundled asset）。
