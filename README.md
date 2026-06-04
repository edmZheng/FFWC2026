# worldcup_tracker

2026 国际足联世界杯赛程追踪 App（Flutter）。桌面安装名 **FFWC2026**。全中文界面，离线可用，首发名单通过 Cloudflare Worker 代理获取。

## 功能

- **赛程**：48 队 × 104 场；子 Tab **关注 / 赛中·未赛 / 完赛**（默认「赛中·未赛」）；右上角 **搜索**（球队名、球员名）；关注球队的赛程聚合在「关注」Tab；**开赛时间统一北京时间**（UTC+8）
- **积分榜**：12 个小组排名表
- **球队**：**关注**（爱心，持久化本地）；宫格已关注置顶 + 角标；详情顶栏队徽 + 小组 / FIFA 排名；**赛程**、**出战名单**（26 人，中文名 + 队长标）
- **首发名单**：单场比赛详情页展示双方首发 + 替补 + 阵型，赛前 30-60 分钟自动出现
- **场馆**：16 座球场详情页 + 本地预置封面图
- **离线优先**：网络不可用回退打包资产 JSON，App 始终可打开

## 技术栈

| 关注点 | 选型 |
|---|---|
| 状态管理 | `flutter_riverpod` (AsyncNotifier + Provider.family) |
| 路由 | `go_router`（ShellRoute + 悬浮胶囊底栏，4 Tab） |
| HTTP | `dio` |
| 本地缓存 | `shared_preferences`（SWR 模式，5 分钟过期） |
| 图片 | `cached_network_image` |
| 主题 / 字体 | Mono 炭蓝亮/暗双模（H=225）+ 跟随系统；Source Sans 3 |
| Lineups 后端代理 | Cloudflare Worker + KV 缓存（见 [cf-worker/](cf-worker/)） |

## 运行 / 构建

```bash
flutter pub get
flutter run
flutter test
flutter analyze
```

**Release APK（本机 Windows）**：见 [docs/BUILD.md](docs/BUILD.md)。简要：

```powershell
$env:PATH = 'E:\DevTools\flutter\bin;E:\AndroidSDK\platform-tools;' + $env:PATH
$env:ANDROID_HOME = 'E:\AndroidSDK'
$env:GRADLE_USER_HOME = 'E:\DevTools\android-tools\.gradle'
flutter pub get && flutter build apk --release
```

产物：`build/app/outputs/flutter-apk/app-release.apk`（约 56MB，debug 签名）。

## 数据来源

| 数据 | 来源 | 接入方式 |
|---|---|---|
| 赛程 / 比分 / 球队 / 球场 / 小组 | `https://worldcup26.ir`（无鉴权 GET） | `dio` 直连，SWR 缓存 |
| 26 人大名单（球员姓名 + 中文名 + 位置） | Wikipedia 抓取后预置 | `assets/data/squads.json` |
| FIFA 男足世界排名 | 手工维护（FIFA/Coca-Cola 月度更新） | `assets/data/fifa_rankings.json` |
| 首发 / 替补 / 阵型 | Highlightly Soccer API（Basic Free） | Cloudflare Worker 代理 + KV 缓存 24h |
| worldcup26 ↔ Highlightly 赛事 ID 映射 + UTC 开赛时间 | 一次性脚本拼接 | `assets/data/match_id_map.json` |

> 直连 `worldcup26.ir` 需墙外或加速。首发数据走 Worker，国内访问稳定。

## 项目结构

```
lib/
├── main.dart / app.dart / providers.dart    # 入口 + 路由 + 全局 provider
├── core/
│   ├── api/                                 # ApiClient + Endpoints（含 workerBaseUrl）
│   ├── cache/                               # CacheStore（SWR）
│   ├── l10n/zh_cn.dart                      # 球队/球场中文名映射
│   ├── stadium/stadium_photos.dart          # 本地球场图映射
│   ├── constants/app_info.dart              # 显示名 FFWC2026
│   ├── nav/schedule_scroll_nav.dart         # 赛程页 → 底栏「回顶部」状态
│   ├── theme/                               # AppTheme + mono_palette（炭蓝双模）
│   └── utils/                               # coerce, match_time, teams_grid_sort, flag_url
├── data/
│   ├── models/                              # Match / Team / Stadium / GroupStanding / Player / Lineup
│   └── repositories/
│       ├── worldcup_repository.dart         # 主数据（network → cache → asset）
│       ├── squad_repository.dart            # 26 人名单（assets 离线）
│       ├── ranking_repository.dart          # FIFA 排名（assets 离线）
│       ├── match_id_map_repository.dart     # worldcup26 → Highlightly + UTC
│       ├── followed_teams_store.dart        # 关注球队 id（SharedPreferences）
│       └── lineup_repository.dart           # Worker → Highlightly /lineups
├── features/
│   ├── schedule/                            # 赛程 + 搜索 + 关注 Tab
│   └── …                                    # standings / teams / stadiums / match_detail
└── shared/widgets/                          # MatchTile / CapsuleNavBar / EdgeProximityScale / TeamFollowButton 等

UI 约定见 [docs/UI.md](docs/UI.md)。

cf-worker/                                   # Cloudflare Worker 代理（独立部署）
scripts/                                     # 数据脚本 + build_release / generate_launcher_icons
assets/
├── data/                                    # games/teams/groups/stadiums/squads/fifa_rankings/match_id_map
├── icon/app_icon.png                        # Android 启动图标主图
└── stadiums/                                # 16 张球场图
```

更多面向贡献者/AI 的约定与架构细节见 [AGENTS.md](AGENTS.md)。Worker 部署/换 key 见 [cf-worker/README.md](cf-worker/README.md)。
