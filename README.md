# worldcup_tracker

2026 国际足联世界杯赛程追踪 App（Flutter）。提供赛程、实时比分、积分榜、球队与场馆信息，全中文界面，离线可用。

## 功能

- **赛程**：按阶段/小组筛选的完整比赛日程，本地时区显示
- **直播**：进行中的比赛，存在直播时每 30 秒自动轮询刷新比分
- **积分榜**：小组排名表
- **球队 / 场馆**：列表 + 详情页，球队国旗来自 [flagcdn](https://flagcdn.com)
- **离线优先**：网络不可用时回退到随 APK 打包的资产 JSON，App 始终可打开

## 技术栈

| 关注点 | 选型 |
|--------|------|
| 状态管理 | `flutter_riverpod` (AsyncNotifier) |
| 路由 | `go_router`（ShellRoute + 底部导航） |
| HTTP | `dio` |
| 本地缓存 | `shared_preferences`（SWR 模式，5 分钟过期） |
| 图片 | `cached_network_image` |
| 国际化/格式化 | `intl` |

## 运行

```bash
flutter pub get
flutter run
```

构建 Release APK：

```bash
flutter build apk --release
```

运行测试与静态检查：

```bash
flutter test
flutter analyze
```

## 数据来源

- **远程 API**：`https://worldcup26.ir`，端点 `/get/games`、`/get/teams`、`/get/groups`、`/get/stadiums`（当前为无鉴权 GET）。
- **离线回退**：`assets/data/` 下的 `games.json` / `teams.json` / `stadiums.json` / `groups.json`，反映构建时的数据状态。
- 数据加载优先级：新鲜网络 → 过期缓存（后台刷新）→ 网络失败时回退打包资产。

> 实时比分需要可访问 `worldcup26.ir` 的网络。

## 项目结构

```
lib/
├── main.dart                 # 入口：初始化 SharedPreferences + ProviderScope
├── app.dart                  # MaterialApp.router + go_router 路由 + 底部导航
├── providers.dart            # 全局 Riverpod providers（数据、派生选择器、直播轮询）
├── core/
│   ├── api/                  # ApiClient（dio）+ Endpoints 常量
│   ├── cache/                # CacheStore（SWR 缓存）
│   ├── theme/                # AppTheme（Material 3 亮/暗主题）
│   └── utils/                # coerce（容错解析）、match_time（时间格式化）
├── data/
│   ├── models/               # Match / Team / Stadium / GroupStanding
│   └── repositories/         # WorldCupRepository（取数 + 缓存 + 关联）
├── features/                 # 按功能分页：schedule / live / standings / teams / stadiums + 详情页
└── shared/widgets/           # MatchTile / TeamBadge / GroupTable / ScorePill / StatusChip
```

更多面向贡献者/AI 的约定与架构细节见 [AGENTS.md](AGENTS.md)。
