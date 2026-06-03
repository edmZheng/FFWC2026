# AGENTS.md — worldcup_tracker

2026 世界杯赛程追踪 App（Flutter）。本文件是给 AI 的规则手册：约定、红线、命令、踩坑。项目概览与运行说明见 [README.md](README.md)。

## 架构地图（feature-first）

- `main.dart` → 初始化 `SharedPreferences`，用 `sharedPreferencesProvider.overrideWithValue` 注入到 `ProviderScope`。
- `app.dart` → `MaterialApp.router` + `go_router`。Tab 页走 `ShellRoute`（共享底部导航）；详情页用 `parentNavigatorKey: _rootNavKey` 渲染在 shell 之上（全屏）。
- `providers.dart` → 所有全局 provider：基础设施、`worldCupDataProvider`（AsyncNotifier）、派生选择器、`livePollingProvider`。
- `core/` 基础设施，`data/` 模型+仓库，`features/` 按页面，`shared/widgets/` 复用组件。

## 数据流（改取数逻辑前必读）

`WorldCupRepository.load()` 的优先级：
1. 新鲜缓存（< 5 min）→ 直接返回
2. 过期缓存 → 立即返回旧数据 + 后台刷新（SWR）
3. 无缓存且网络失败 → 回退 `assets/data/*.json`（保证离线可用）

- 缓存在 `CacheStore`（`shared_preferences`），过期阈值 `_staleSecs = 300`，key 前缀 `cache_data_` / `cache_ts_`。
- API：`Endpoints.baseUrl = https://worldcup26.ir`，端点 `/get/{games,teams,groups,stadiums}`。无鉴权 GET。
- 四份数据（games/teams/stadiums/groups）并行拉取，在 `_parse()` 里关联：match 引用 team/stadium，standing 引用 team。

## 命令速查

```bash
flutter pub get          # 装依赖
flutter run              # 跑 App
flutter test             # 跑单测（test/ 下 5 个文件）
flutter analyze          # 静态检查（flutter_lints）
flutter build apk --release
```

## 路由清单（go_router）

| Path | 页面 | 层级 |
|------|------|------|
| `/schedule` | SchedulePage | shell（默认） |
| `/live` | LivePage | shell |
| `/standings` | StandingsPage | shell |
| `/teams` | TeamsPage | shell |
| `/stadiums` | StadiumsPage | shell |
| `/match/:id` | MatchDetailPage | root（全屏） |
| `/team/:id` | TeamDetailPage | root（全屏） |
| `/stadium/:id` | StadiumDetailPage | root（全屏） |

新增 tab → 同时改 `app.dart` 的 `routes` 和 `_tabs` 常量。

## 约定与红线

- **UI 文案一律中文**（App 面向中文用户，title「2026 世界杯」，tab 已中文化）。新增/改 UI 字符串保持中文。
- **国旗只能用 PNG**：`flagcdn` 默认返回 SVG，`CachedNetworkImage` 渲染不了。`TeamBadge` 用 `iso2` 拼 `https://flagcdn.com/w80/{iso2}.png`，无 iso2 才回退 `flagUrl`，再无则占位图。别改成 SVG URL。
- **新增数据字段**要两边对齐：API 返回结构 + `assets/data/*.json` 离线副本 + 对应 model 的 `fromJson`。
- **JSON 解析走容错**：用 `core/utils/coerce.dart`，不要直接强转，API 字段可能缺失/类型不稳。
- **JWT 鉴权**：`ApiClient` 已接好 `_JwtInterceptor`，默认 no-op。API 若开始要鉴权，调 `enableJwt(token)`，不要重写请求逻辑。
- **直播轮询**：`livePollingProvider` 是 `autoDispose`，仅在有 live 比赛时启 30s `Timer`，`onDispose` 会取消。别在普通页面常驻轮询。

## 当前进行中

- `.ccg/tasks/ui-cn-flags`：UI 美化 + 全中文本地化 + 国旗，scope `lib/**/*.dart`，状态 in_progress。
