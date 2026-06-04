# AGENTS.md — worldcup_tracker

2026 世界杯赛程追踪 App（Flutter）。本文件是给 AI 的规则手册：约定、红线、命令、踩坑。
项目概览见 [README.md](README.md)。Worker 部署见 [cf-worker/README.md](cf-worker/README.md)。

## 架构地图（feature-first）

- `main.dart` → 初始化 `SharedPreferences`，用 `sharedPreferencesProvider.overrideWithValue` 注入。
- `app.dart` → `MaterialApp.router` + `go_router` + `ThemeMode.system`。Tab 页走 `ShellRoute`；详情页用 `parentNavigatorKey: _rootNavKey`（全屏）。
- `providers.dart` → 全局 provider：主数据、squads、rankings、match_id_map、lineups、live polling、**关注球队**（`followed_team_ids`）、**赛程搜索索引**、**宫格球队排序**（`teamsGridProvider`）。
- `core/` 基础设施，`data/` 模型+仓库，`features/` 按页面，`shared/widgets/` 复用组件。
- `cf-worker/` 独立的 Cloudflare Worker 项目（**不是** Flutter 源码），代理 Highlightly lineups 并 KV 缓存 24h。
- `scripts/` 开发期一次性脚本（Python）：build_squads / fetch_squad_meta / refine_zh / build_match_id_map 等。

## 数据流（改取数逻辑前必读）

**主数据**（赛程/球队/场馆/小组）— `WorldCupRepository.load()` 优先级：
1. 新鲜缓存（< 5 min）→ 直接返回
2. 过期缓存 → 立即返回旧数据 + 后台刷新（SWR）
3. 无缓存且网络失败 → 回退 `assets/data/*.json`

- API：`Endpoints.baseUrl = https://worldcup26.ir`，端点 `/get/{games,teams,groups,stadiums}`。无鉴权 GET。
- 缓存：`CacheStore` (`shared_preferences`)，`_staleSecs = 300`，key 前缀 `cache_data_` / `cache_ts_`。

**辅助数据**（无 network 层，纯 asset）：
- `squads.json` → `SquadRepository`：26 人大名单 + 中文名 + 头像 URL（本版本 UI 不用头像）
- `fifa_rankings.json` → `RankingRepository.byCode`：FIFA 三字母 code → rank + points
- `match_id_map.json` → `MatchIdMapRepository`：worldcup26.ir id → `{hl: int, utc: DateTime}`，**仅 group stage 72 场覆盖**，淘汰赛敲钉后用 `scripts/build_match_id_map.py` 重建

**Lineups**（外部 API，走代理）：
- Flutter → `https://ffwc-proxy.randomdre13.workers.dev/lineups/{highlightlyId}` → Worker KV 查 → 命中返回 / 未命中转发到 Highlightly + 写 KV 24h
- 同一场比赛任意数量用户访问，上游只算 1 次（24h 内）。Highlightly Free = 100 req/天，赛事全程理论上游 < 300 次

## 命令速查

**Android Release 打包（用户说「打包」默认走此流程）** — 详见 [docs/BUILD.md](docs/BUILD.md)：

```powershell
cd G:\13_APP_Dev\20260603-FFWC
$env:PATH = 'E:\DevTools\flutter\bin;E:\AndroidSDK\platform-tools;' + $env:PATH
$env:ANDROID_HOME = 'E:\AndroidSDK'
$env:GRADLE_USER_HOME = 'E:\DevTools\android-tools\.gradle'   # 勿设为 E:\AndroidSDK
flutter pub get
flutter build apk --release
# 产物: build/app/outputs/flutter-apk/app-release.apk（快捷方式 lnk 指向该目录）
```

或 `.\scripts\build_release.ps1`。

**收尾默认**：完成 Flutter UI/功能/资源/图标/`AndroidManifest` 等可安装变更后，**在同一轮对话内自动执行上述 Release 打包**（无需用户再催「打包」）。仅改文档/注释/Worker/纯脚本且不影响 APK 时可跳过。

```bash
# Flutter（开发）
flutter pub get
flutter run
flutter test
flutter analyze

# Cloudflare Worker (在 cf-worker/ 下)
wrangler deploy                         # 重新发布 Worker
wrangler secret put HL_API_KEY          # 轮换 Highlightly key
wrangler kv key list --binding=CACHE    # 看 KV 缓存

# 数据脚本（在 scripts/ 下，按需运行）
python build_squads.py          # 从 Wikipedia MD 解析名单，保留已有 photo_url + name_zh
python fetch_squad_meta.py      # 合并抓 photo + langlinks(zh)，opencc 简化
python refine_zh.py             # 用 override 字典 + Wikipedia variant=zh-cn 修港式译名
python build_match_id_map.py    # 重建 worldcup26↔highlightly 映射（淘汰赛敲钉后跑一次）
python generate_launcher_icons.py  # 从 assets/icon/app_icon.png 生成 Android mipmap
```

## 路由清单（go_router）

| Path | 页面 | 层级 |
|------|------|------|
| `/schedule` | SchedulePage | shell（默认） |
| `/standings` | StandingsPage | shell |
| `/teams` | TeamsPage | shell |
| `/stadiums` | StadiumsPage | shell |
| `/match/:id` | MatchDetailPage | root（全屏） |
| `/team/:id` | TeamDetailPage | root（全屏） |
| `/stadium/:id` | StadiumDetailPage | root（全屏） |
| `/group/:name` | GroupDetailPage | root（全屏） |

新增 shell Tab → 改 `app.dart` 的 `routes`、`_routes`、`_tabs` 与 `CapsuleNavBar`。

## 约定与红线

- **UI 文案一律中文**（面向中文用户）。新增/改 UI 字符串保持中文。
- **比赛时间显示用北京时间**（UTC+8 硬编码，**不**走 `DateTime.toLocal()`）。优先用 `kickoffUtcByMatchIdProvider` 取 UTC + `MatchTime.formatBeijing`；映射缺失才回退 `match.localDate`（场馆本地时间）。
- **球员中文名**：`squads.json` 已预处理为简体大陆约定俗成译名。新增球员先查 `scripts/zh_overrides.py` 字典是否覆盖；港台音译（朗拿度、卡斯米路等）必须在 override 里替换。
- **国旗只能用 PNG**：`flagcdn` 默认 SVG，`CachedNetworkImage` 渲染不了。`TeamBadge` 用 `iso2` 拼 `https://flagcdn.com/w80/{iso2}.png`，无 iso2 才回退 `flagUrl`。
- **新增数据字段**两边对齐：API 结构 + `assets/data/*.json` 离线副本 + 对应 model `fromJson`。
- **JSON 解析走容错**：用 `core/utils/coerce.dart`，不要直接强转。
- **下拉刷新**：赛程/积分榜/球队详情用 `RefreshIndicator`；`refresh()` 禁止先置 `loading`；列表 `skipLoadingOnReload: true`。细则见 [docs/UI.md](docs/UI.md)。
- **分段标题**：用 `SectionTitle`，球队详情为「赛程」「出战名单」。
- **Shell 底栏**：`CapsuleNavBar` 悬浮不占位；无点击涟漪；赛程滚过 ~120px 显示「回顶部」。Mono 炭蓝亮/暗双模 + `ThemeMode.system`（`mono_palette.dart` / `app_theme.dart`）。
- **赛程子 Tab**：`关注 | 赛中/未赛 | 完赛`；**默认 `initialIndex: 1`**（赛中/未赛）。搜索见 `ScheduleSearchDelegate`。
- **关注球队**：Toggle 走 `followedTeamsProvider`；prefs key `followed_team_ids`（勿与 `cache_*` 混用）。宫格列表用 `teamsGridProvider`（已关注置顶），勿直接用 `teamsProvider`。
- **StatusChip 时间**：列表/详情 `showTime: false`；未开赛详情 AppBar 无 actions。开赛时间只在卡片正文与「赛事信息」。
- **宫格 + 关注角标**：球队 Card 内容 `Positioned.fill` 居中，角标单独 `Positioned`，避免国旗偏移。
- **详情顶区**：小组/球队详情用 `DetailFixedHeaderBody`（顶区 Stack 最上层、无底线）；小组仅积分榜固定，「赛程」随滚。细则见 [docs/UI.md](docs/UI.md)。
- **直播轮询**：`livePollingProvider` 仍保留（`live_page` 未挂 Tab）。别在普通页面常驻轮询。
- **HL_API_KEY 永远只在 Worker secret**：`wrangler secret put HL_API_KEY`，**不可**写入代码、`wrangler.toml`、git。轮换流程见 `cf-worker/README.md`。
- **Highlightly 配额硬约束**：Free = 100 req/天，整届 WC ~300 次上游消耗。Worker KV TTL 24h 是配额保护，**不要**轻易缩短。
- **match_id_map.json 覆盖范围**：72 场小组赛全覆盖，32 场淘汰赛是 worldcup26.ir 占位符（`Winner Group X`），未映射。淘汰赛对阵敲钉后跑 `build_match_id_map.py` 增量补。
- **换启动图标**：覆盖 `assets/icon/app_icon.png` → `python scripts/generate_launcher_icons.py` → Release 打包。勿只改 `mipmap-*` 不更新主图。

## 深入文档

| 主题 | 文件 |
|---|---|
| 项目概览 / 功能 / 跑起来 | `README.md` |
| Android Release 打包 / 环境变量 | `docs/BUILD.md` |
| UI / 刷新 / 导航 / 关注 / 搜索 / 动效 | `docs/UI.md` |
| Worker 部署 / 换 key / KV 调试 | `cf-worker/README.md` |
| 球员名单原始数据 | `scripts/2026_squads_wiki.md` |
