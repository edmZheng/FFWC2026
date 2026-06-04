# UI 约定

面向贡献者与接手开发者的界面规范（与代码同步，2026-06-04）。

## 品牌与主题

| 项 | 值 |
|---|---|
| 安装名 / AppBar 赛程页标题 | `FFWC2026`（`AppInfo.displayName`） |
| 主题 | Mono-design 炭蓝双模（H=225）：`MonoPalette.dark` / `MonoPalette.light` |
| 跟随系统 | `MaterialApp.themeMode: ThemeMode.system`（`app.dart`） |
| 字体 | Source Sans 3（`google_fonts`） |

## Shell 导航

- **4 Tab**：赛程 / 积分榜 / 球队 / 场馆（无直播 Tab）
- **底栏**：`CapsuleNavBar` 液态玻璃胶囊，悬浮于内容之上（`Stack`），不占底部横条
- **点击**：`GestureDetector`，无涟漪/高亮，仅切换选中态
- **赛程回顶部**：赛程 Tab 列表滚过约 120px 后，第一个 Tab 变为圆圈 ↑ +「回顶部」；点击平滑滚回顶部（`scheduleScrollNavProvider` + `core/nav/schedule_scroll_nav.dart`）
- 列表底部留白：`CapsuleNavMetrics.bottomInset(context)`，避免被胶囊遮挡

## 赛程页（`/schedule`）

| 项 | 说明 |
|---|---|
| 子 Tab | `关注` · `赛中 / 未赛` · `完赛`（`TabController` length 3） |
| 默认子 Tab | `initialIndex: 1`（**赛中 / 未赛**），不是「关注」 |
| 搜索 | AppBar 右上角 → `showSearch` + `ScheduleSearchDelegate`；按球队中文/英文名、FIFA 代码、名单球员名筛已确定赛程 |
| 赛历入口 | AppBar **左上角** `calendar_month`（与右上搜索对称）；再点收起 |
| 赛历条 | Tab 下方 `ScheduleDayStrip`（`schedule_day_strip.dart`），`AnimatedSize` 约 320ms 下推 `TabBarView` |
| 日期范围 | `scheduleCalendarDays`：已确定比赛最早～最晚日，并强制包含用户当前日历日（无固定 6/11–7/19） |
| 默认选中 | `defaultCalendarSelectedDay()` → 用户当前日 |
| 高亮规则 | `highlightCountByDay`：子 Tab **关注** 用 `followedMatches` 计场，**赛中/未赛**与**完赛**用全部已确定比赛；切换 Tab 时 `setState` 刷新条 |
| 列表筛选 | 展开且已选日期时，`filterMatchesByCalendarDay` 筛三 Tab（北京时间，优先 `match_id_map` UTC） |
| 实现勿踩 | **无** `/schedule/calendar` 路由；逻辑在 `core/utils/match_calendar.dart` |
| 关注 Tab | `followedMatchesProvider`：主客队任一方为已关注 `teamId` 的 `isConfirmed` 比赛，按开赛时间排序 |

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
- `DetailScrollClipScope` 将 3D 离屏动效的有效视口上沿设为顶区底边

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
- 效果：缩小 + **绕靠近相邻卡片的一边** 倾斜（纵向 `rotateX` / 横向 `rotateY`）+ **朝邻卡叠入下层**（`maxStackPull` 靠拢 + `translateZ` 后撤），非向外推开
- 默认强度：`maxRotateX` 0.68、`perspective` 0.0018
- 滚动列表/宫格设 `clipBehavior: Clip.none`，避免 3D 被裁切
- 已用于：赛程卡、积分榜/球队/场馆宫格、比赛详情 Card

## 比赛详情 AppBar

- **未开赛**：无 `actions`（开赛时间仅在正文卡与「赛事信息」，避免与右上角重复）
- **进行中 / 完场**：`StatusChip(match:, showTime: false)`（芯片不重复显示开赛时间）
- 赛程列表卡片同理：`StatusChip(showTime: false)`，时间在 VS 下方

## 遗留

- `features/live/live_page.dart` 与 `livePollingProvider` 仍在代码库，**未挂 Shell 路由**
