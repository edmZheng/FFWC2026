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
- **赛程回顶部**：列表滚过约 120px 后，赛程 Tab 显示 ↑ +「回顶部」；点击平滑滚顶（`scheduleScrollNavProvider`，`core/nav/schedule_scroll_nav.dart`）。**离开赛程 Shell Tab** 时 `app.dart` 调用 `reset()`；回到赛程后 `SchedulePage` 在 `initState` / `activate` 首帧执行 `_syncScrollNav()`，避免列表已在顶部仍残留「回顶部」
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
| 高亮规则 | `highlightCountByDay`：子 Tab **关注** / **赛中·未赛** / **完赛** 各用对应列表计场（仅有该 Tab 比赛的日期才高亮）；切换 Tab 时 `SchedulePageUiState.switchTab()` 刷新条 |
| 列表筛选 | 展开且已选日期时，`ScheduleVisibleMatches.applyDayFilter()` → `filterMatchesByCalendarDay` 筛三 Tab（北京时间，优先 `match_id_map` UTC） |
| 实现勿踩 | **无** `/schedule/calendar` 路由；赛历/搜索状态与可见列表在 `features/schedule/state/schedule_page_state.dart`；日期工具在 `core/utils/match_calendar.dart` |
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

## 场馆宫格（`/stadiums`）

| 项 | 说明 |
|---|---|
| 布局 | `GridView` + `EdgeProximityScale`；`clipBehavior: Clip.none` |
| 封面 | `StadiumCover`：本地 PNG（`stadium_photos.dart`）；插画底部常烧录英文球场名 |
| 中文标题条 | `caption` 参数：封面底部实色条叠中文赛事实名，遮盖插画英文名 |
| 圆角 | `Card` 使用 `clipBehavior: Clip.antiAlias`（勿 `Clip.none`）；封面上沿 `borderRadius` 10，与主题卡片一致 |
| 地点行 | `ZhCn.city` · `ZhCn.country`；`maxLines: 1` + `FittedBox(scaleDown)`，单行不换行 |

## 场馆名称

| 字段 | 含义 | 展示位置 |
|---|---|---|
| `ZhCn.stadiumName` | 赛事实名（如「阿兹特克体育场」「达拉斯AT&T体育场」） | 宫格 caption、详情标题、赛程卡 |
| 映射顺序 | `_stadiumsById` → `_stadiums[name_en]` → `_stadiums[fifa_name]` | `lib/core/l10n/zh_cn.dart`；API/缓存有时把 `fifa_name` 写入 `name_en`，**勿只按 `name_en` 查表** |
| `fifa_name` | 球场日常商用名（如 `NRG Stadium`、`MetLife Stadium`） | 详情「球场常用名」 |
| `city_en` + `ZhCn.city` | 主办城市 | 宫格地点行、详情 |

离线数据源：`assets/data/stadiums.json`（`name_en` 为赛事用名）；线上 API 字段可能与打包 JSON 不一致，以 `id` 映射为准。

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

### 默认（`EdgeProximityScale`）

- `EdgeProximityScale`（`shared/widgets/edge_proximity_scale.dart`）：约 **1/3 出屏** 后触发
- 效果：**居中均匀缩小**（默认 `maxScale` 1.0 → `minScale` 0.88），无 3D 倾斜、位移或透明度
- 滚动跟手（`Transform.scale` + 帧内 `scheduleFrameCallback` 校正）
- 内容不足一屏（`maxScrollExtent <= 0`，如搜索短结果）时不缩放
- 列表、宫格、赛程 `TabBarView` 设 `clipBehavior: Clip.none`，避免缩放被父级裁切
- `axis`：`vertical`（顶+底都响应）、`horizontal`、`both`、`verticalTopOnly`、`verticalBottomOnly`（后两个为 schedule 页专用，见下）
- 已用于：积分榜/球队/场馆宫格、比赛详情 Card、`MatchTile`（默认 `vertical`，schedule 页除外）

### schedule 页特例（顶/底分边，`MatchTile.bottomFadeInset != null`）

只在 `SchedulePage._MatchList` 的 `MatchTile` 上生效——`MatchTile` 接到非 null `bottomFadeInset` 时**外层 `StackedEdgeFade` + 内层 `EdgeProximityScale(verticalTopOnly)`** 双层包装；其他 6 处使用 `MatchTile` 的页面 (`live`/`schedule_search_panel`/`team_detail`/`stadium_detail`/`group_detail`) 不传该参数，保持默认 `EdgeProximityScale(vertical)`。

| 边 | 组件 | 行为 |
|---|---|---|
| 顶部 | `EdgeProximityScale(verticalTopOnly)` | 卡片正常滑出 viewport，按出屏比例缩到 0.88，无 alpha、无位置 clamp |
| 底部 | `StackedEdgeFade`（`shared/widgets/stacked_edge_fade.dart`） | 卡片下沿触及 `viewport.bottom - bottomInset` 时**硬停**（`Transform.translate` clamp），同时 scale 1.0→0.75、alpha 1.0→0.0；累计"虚拟位移" = `卡片高度 × 1.5` 时完全淡尽（形成"残影"）。alpha < 0.5 时 `IgnorePointer` 防误触；`scrollPosition.pixels < 0`（下拉刷新 overscroll）时不 clamp。曲线 Linear |

底部边缘**位置 = 屏幕物理底部**（`MediaQuery.paddingOf.bottom`，仅避开手势区），不是 `CapsuleNav` 上方。`SchedulePage._MatchList` 的 sliver `padding.bottom` 同步设为 `systemBottom`，卡片可滑入 `CapsuleNav`（液态玻璃 `BackdropFilter(blur:24)` 浮层）下方，透过模糊可见。

### z-order：底部用反向 paint 的自定义 sliver

底部"压栈"场景下：fading 卡片（高 index）应该被上方滑下来的 normal 卡片（低 index）覆盖；但 `ListView` 默认按 index 顺序 paint，高 index 在上，正好相反。`SchedulePage._MatchList` 因此用 `ZSortedListView`（`shared/widgets/z_sorted_sliver_list.dart`，`extends BoxScrollView`）替代 `ListView.builder`——内部 sliver 是 `ZSortedSliverList`，paint 与 hit-test 都按 `lastChild → firstChild` 反向遍历：

- **底部边缘**：fading 卡片先画 → 在下层；normal 卡片后画 → 在上层覆盖 ✓
- **顶部边缘**：cards 因为 `verticalTopOnly` 仅居中 shrink、不 clamp、相邻卡片之间留出间隙不重叠，paint 顺序对视觉无影响 ✓

为什么不直接 `CustomScrollView + SliverPadding + ZSortedSliverList`：`CustomScrollView` 路径绕开了 `BoxScrollView` 内部的 MediaQuery padding 处理与一些 layout invalidation 行为，导致 calendar/search `AnimatedSize` 切换时 viewport 边界判断、`Clip.none` 行为、以及 viewport 扩大后 sliver 重 layout 触发都跟 `ListView.builder` 不一致（出现卡片画到日历栏上、退出 calendar/search 后下方 cards 空白等异常）。`ZSortedListView extends BoxScrollView` 走标准 ListView 路径即可避开这些副作用。

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
