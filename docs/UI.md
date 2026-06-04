# UI 约定

面向贡献者与接手开发者的界面规范（与代码同步，2026-06-04）。

## 交互反馈

- **无 Material 水波**：`lib/core/theme/app_theme.dart` 设 `NoSplash.splashFactory`、透明 splash/highlight；`tabBarTheme` / `iconButtonTheme` 同步。新增可点控件勿单独恢复涟漪。

## 品牌与主题

| 项 | 值 |
|---|---|
| 安装名 / `MaterialApp.title` | `FFWC2026`（`AppInfo.displayName`，`app.dart`） |
| 主题 | Mono-design 炭蓝双模（H=225）：`MonoPalette.dark` / `MonoPalette.light` |
| 跟随系统 | `MaterialApp.themeMode: ThemeMode.system`（`app.dart`） |
| 字体 | Source Sans 3（`google_fonts`） |

## Shell AppBar 标题图

四个主 Tab 的 `AppBar.title` 为 PNG 横幅（非 `Text`），统一 `AppBarTitleImage`（`shared/widgets/app_bar_title_image.dart`）：

| Tab | 构造 | 资源 | 读屏文案 |
|---|---|---|---|
| 赛程 | `.games()` | `assets/titles/games.png` | 赛程 |
| 积分榜 | `.rank()` | `assets/titles/rank.png` | 积分榜 |
| 球队 | `.teams()` | `assets/titles/teams.png` | 球队 |
| 场馆 | `.stadium()` | `assets/titles/stadium.png` | 场馆 |

- 默认显示高度 **30** 逻辑像素，`BoxFit.contain`，`centerTitle: true`。
- 换图：覆盖对应 PNG 后 **Release 打包**（`pubspec` 注册 `assets/titles/` 目录）。
- 详情页 AppBar 仍为 `Text`（队名、小组名等）；仅 Shell 四 Tab 用横幅。

## Shell 导航

- **4 Tab**：赛程 / 积分榜 / 球队 / 场馆（无直播 Tab）
- **底栏**：`CapsuleNavBar` 液态玻璃胶囊，悬浮于内容之上（`Stack`），不占底部横条
- **点击**：`GestureDetector`，无涟漪/高亮，仅切换选中态（与下文全应用 `NoSplash` 一致）
- **赛程回顶部**：赛程 Tab 列表滚过约 120px 后，第一个 Tab 变为圆圈 ↑ +「回顶部」；点击平滑滚回顶部（`scheduleScrollNavProvider` + `core/nav/schedule_scroll_nav.dart`）
- 列表底部留白：`CapsuleNavMetrics.bottomInset(context)`，避免被胶囊遮挡

## 赛程页（`/schedule`）

| 项 | 说明 |
|---|---|
| 子 Tab | `关注` · `赛中 / 未赛` · `完赛`（`TabController` length 3） |
| 默认子 Tab | `initialIndex: 1`（**赛中 / 未赛**），不是「关注」 |
| 搜索 | AppBar 右上角 → `AnimatedSize` 下推 `ScheduleInlineSearchField` + `ScheduleSearchResults`（与赛历互斥展开）；按球队中文/英文名、FIFA 代码、名单球员名筛已确定赛程 |
| 赛历入口 | AppBar **左上角** `calendar_month`（与右上搜索对称）；再点收起 |
| 赛历 ⇄ 搜索 | **互斥**：展开其一自动收起另一（含清空赛历选日 / 搜索词） |
| 赛历条 | Tab 下方 `ScheduleDayStrip`（`schedule_day_strip.dart`），`AnimatedSize` 约 320ms 下推 `TabBarView` |
| 日期范围 | `scheduleCalendarDays`：已确定比赛最早～最晚日，并强制包含用户当前日历日（无固定 6/11–7/19） |
| 默认选中 | `defaultCalendarSelectedDay()` → 用户当前日 |
| 高亮规则 | `highlightCountByDay`：子 Tab **关注** / **赛中·未赛** / **完赛** 各用对应列表计场（仅有该 Tab 比赛的日期才高亮）；切换 Tab 时 `setState` 刷新条 |
| 列表筛选 | 展开且已选日期时，`filterMatchesByCalendarDay` 筛三 Tab（北京时间，优先 `match_id_map` UTC） |
| 实现勿踩 | **无** `/schedule/calendar` 路由；逻辑在 `core/utils/match_calendar.dart` |
| 关注 Tab | `followedMatchesProvider`：主客队任一方为已关注 `teamId` 的 `isConfirmed` 比赛，按开赛时间排序 |

## 积分榜页（`/standings`）

| 项 | 说明 |
|---|---|
| 列表 | 12 组宫格预览，点进 `/group/:name` |
| 刷新 | `RefreshIndicator` 下拉刷新（无 AppBar 刷新按钮） |
| 官方规则 | AppBar 右上 `Icons.help_outline` → `context.push('/standings/rules')` |
| 规则页 | `WorldCupRulesPage`（`DetailScaffold` + 可滚动正文）；内容依据 FIFA 公布赛制整理，非应用内排序算法说明 |

## 场馆配图

| 项 | 说明 |
|---|---|
| 映射 | `lib/core/stadium/stadium_photos.dart` → `assetPath` / `networkUrls` |
| 本地 PNG 插画 | id `1`–`16`（16 座均为定制插画，含亚特兰大 Mercedes-Benz 等） |
| 本地 JPG | 无（网络回退仍可用 `_networkById`） |
| 回退 | 本地缺失时用 `_networkById` 同 id 的 Wikimedia URL |
| 换图 | 覆盖 `assets/stadiums/{id}.png` 后 **Release 打包**；id 须留在 `_pngIds`（当前 `1`–`16` 全覆盖） |

## 场馆名称

| 字段 | 含义 | 展示位置 |
|---|---|---|
| `name_en` + `ZhCn.stadiumName` | 赛事实名（如「达拉斯AT&T体育场」「休斯敦体育场」） | 列表、详情标题、赛程卡 |
| `fifa_name` | 球场日常商用名（如 `NRG Stadium`、`MetLife Stadium`） | 详情「球场常用名」 |
| `city_en` + `ZhCn.city` | 主办城市 | 详情副标题 |

数据源：`assets/data/stadiums.json`；中文映射在 `lib/core/l10n/zh_cn.dart` 的 `_stadiums`。

## 球队关注

| 项 | 说明 |
|---|---|
| 持久化 | `FollowedTeamsStore` → `SharedPreferences` key `followed_team_ids` |
| Provider | `followedTeamsProvider`（Set）、`followedMatchesProvider`、`teamsGridProvider` |
| 详情 | AppBar `TeamFollowButton`（爱心切换） |
| 宫格 | 右上角 `TeamFollowBadge`；已关注球队 **置顶**（`core/utils/teams_grid_sort.dart`，组内保持 API 顺序） |
| 宫格布局 | 内容层 `Positioned.fill` 居中，角标 `Positioned` 叠加，避免国旗被挤偏 |

## 详情页顶区固定

用 `DetailFixedHeaderBody`（`shared/widgets/detail_fixed_header_body.dart`）：

- **Stack 布局**：下层全屏滚动，上层不透明 `Material` 顶区（**无**底部分割线）
- 顶区始终在最上层；下方内容从顶区底边滚入/滚出
- `DetailScrollClipScope` 将离屏缩放的有效视口上沿设为顶区底边

| 页面 | 固定顶区 | 随滚动 |
|---|---|---|
| 小组详情 `/group/:name` | 积分榜 `GroupTable` 卡片 | `SectionTitle('赛程')` + 比赛列表 |
| 球队详情 `/team/:id` | 国旗 + 小组 / FIFA 排名 | 「赛程」、比赛、「出战名单」、26 人 |

## 刷新

- **赛程、积分榜**：AppBar 无刷新按钮；`RefreshIndicator` 下拉刷新
- **球队详情**：同上，刷新 `worldCupDataProvider`
- **数据层**：`WorldCupDataNotifier.refresh()` **不得**先 `state = loading`；失败保留旧数据
- **列表**：`async.when(..., skipLoadingOnReload: true)`，避免刷新时整页转圈

## 分段标题

统一用 `SectionTitle`（居中）：

| 场景 | 文案 |
|---|---|
| 球队详情 — 比赛列表 | 赛程 |
| 球队详情 — 26 人 | 出战名单 |
| 小组详情 — 比赛列表 | 赛程 |
| 比赛详情 — 阵容 | 首发名单 |

## 球队详情顶栏

- 国旗（96px）+ 信息（**小组**、**FIFA 排名**）左右并排
- 整块 **水平居中**（`Center` + `mainAxisSize: min`）

## 列表卡片动效

- `EdgeProximityScale`（`shared/widgets/edge_proximity_scale.dart`）：约 **1/3 出屏** 后触发
- 效果：**居中均匀缩小**（默认 `maxScale` 1.0 → `minScale` 0.88），无 3D 倾斜、位移或透明度
- 滚动跟手（`Transform.scale` + 帧内 `scheduleFrameCallback` 校正）
- 内容不足一屏（`maxScrollExtent <= 0`，如搜索短结果）时不缩放
- 列表、宫格、赛程 `TabBarView` 设 `clipBehavior: Clip.none`，避免缩放被父级裁切
- 已用于：赛程卡、积分榜/球队/场馆宫格、比赛详情 Card

## 比赛详情 AppBar

- **未开赛**（且能解析开赛时间）：右上 **铃铛** → 写入系统日历（`lib/core/calendar/match_calendar_reminder.dart`，`device_calendar`）；赛事开始时刻 + **赛前 60 分钟**提醒；首次需系统日历权限
- **未开赛**（无开赛时间）：不显示铃铛
- **进行中 / 完场**：`StatusChip(match:, showTime: false)`（芯片不重复显示开赛时间）
- 开赛时间仍在正文卡与「赛事信息」；铃铛与 `StatusChip` 不并存
- 赛程列表卡片：`StatusChip(showTime: false)`，时间在 VS 下方；进行中左上角蓝点（`MatchTile`）

## 直播跟分

- `liveScoreSyncProvider`（`MyApp` 常驻，`lib/core/live/live_score_sync.dart`）：存在 `MatchStatus.live` 时每 **30 秒** `worldCupDataProvider.refresh()`（对齐 worldcup26.ir 上游节奏；不闪 loading）
- 更新范围：赛程卡 `MatchTile`（`ScorePill`）、比赛详情、积分榜等依赖主数据的页面
- 无进行中比赛时不轮询；仍可下拉刷新
- 无独立 WebSocket；比分字段来自 `/get/games` 的 `home_score` / `away_score` / `time_elapsed`

## 遗留

- `features/live/live_page.dart` 仍在代码库，**未挂 Shell 路由**（数据与全局跟分相同）
