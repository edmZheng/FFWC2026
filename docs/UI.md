# UI 约定

面向贡献者与接手开发者的界面规范（与代码同步，2026-06-10）。

## 首次启动封面（SplashScreen）

`lib/features/splash/splash_screen.dart`，仅在 `main.dart` 判断首次启动（SharedPreferences key `ffwc_launched_v1` 不存在）时挂载。

| 项 | 说明 |
|---|---|
| 视频 | `assets/videos/cover.mp4`，`VideoPlayer`，`BoxFit.cover` 全屏 |
| 状态机 | `_Phase`：`videoPlaying` → `fading` → `splashGone`（见源码文件头注释） |
| 结束时机 | **仅**视频自然播完：`addListener(_onVideoTick)` 检测 `isCompleted` 或 `position >= duration - 120ms`；兜底 timer = 时长 + 800ms（未知则 15s） |
| 交互 | 播放期**不接受任何触摸**（无跳过按钮、无全屏触屏层）；用户只能等播完 |
| 淡出 | 停在最后一帧，**350ms** `easeInOut` 淡出视频层 → 露出 Stack 底层欢迎页 |
| 初始化失败 | `initialize()` 超时 **12s** 或抛异常 → `_Phase.splashGone`，直接露出欢迎页（避免黑屏卡死） |
| **Widget 树** | 始终 `Directionality → Stack`：`widget.child`（WelcomePage）占**固定槽位**；`phase != splashGone` 时叠视频层（`IgnorePointer`）。**⚠️ 勿**在 `splashGone` 后 `return widget.child`——WelcomePage 会 remount，欢迎层淡入重播 |
| 交互屏蔽 | 播放期 `IgnorePointer(ignoring: phase != splashGone)` 挡欢迎页；`splashGone` 后欢迎页可点「开始使用」 |
| **⚠️ 禁忌** | **勿**恢复跳过按钮 / 全屏触屏层（2026-06-09 产品已移除）；**勿** `splashGone` 后改树结构 remount child |
| 回归测试 | `test/splash_screen_test.dart`（无跳过 UI、触屏无效、completed/计时器转场、不 remount） |

## 欢迎页（WelcomePage）

`lib/features/splash/welcome_page.dart`，视频淡出后展示，点击「开始使用」才进主界面。

| 项 | 说明 |
|---|---|
| **Widget 树** | `MyApp` 始终在 Stack **固定槽位**；欢迎层（黑底 + 内容）叠在上方 `FadeTransition` 内，整页一体淡入/淡出 |
| 触发时机 | 自 Splash 挂载即在底层预渲染；视频 350ms 淡出后可见；去掉 overlay **不 remount** 首页 |
| 背景 | 纯黑 + 2026 美加墨主题：三国色辉光（加红左上 / 美蓝右上 / 墨绿底部，`_Glow` 径向渐变）+ 奖杯纪念徽记水印（`assets/icon/wc26_trophy_bg.webp` 660×1185，AI 重绘金杯 + 炭灰 26，`Opacity 0.30`、宽 82%、居中微偏上，辉光之上内容之下）+ 屏幕四角角旗弧线（`_CornerArcsPainter`） |
| 图标 | `assets/icon/welcome_icon.png`，88×88；呼吸辉光（`_BreathingIcon`，2.6s repeat-reverse，随 overlay 卸载停表）；背后球场线稿：中圈双同心圆 + 横贯中线两端渐隐（`_PitchMarkPainter`，溢出绘制，外层 Stack `Clip.none`） |
| 标题 / 副标题 | 词标 `_Wordmark`：`assets/icon/ffwc_wordmark.png`（AI 生成 Logo，760×272 黑底图，自带三色光晕 + 五边形「0」+ 三国色下划弧），显示宽 264，key `welcome-wordmark`（**测试定位锚点**）/ `一手掌握世界杯赛程信息`（`white60`，14px） |
| 主办国 / 数据 | `CAN · MEX · USA`（发光色点 + 代码，`_HostNation`）；`6.11 – 7.19 · 48 队 · 104 场 · 16 城` |
| 按钮 | 白底黑字「开始使用」，`GestureDetector + Container`，168×46，圆角 23，白色溢光；key `welcome-start-button` |
| 淡入 | 整页 `_fade.forward()` **300ms** `easeInOut`；内容 6 段瀑布式入场（`_intro` 1200ms，交叠 `Interval` + 淡入上移，一次性） |
| 退出 | 点按钮 → overlay 整页 `_fade.reverse()`（300ms）→ `_done = true` 移除 overlay，露出底层 `MyApp`。**勿** `return widget.child` 换树 |
| **⚠️ 禁忌** | **不能用 `Scaffold` / `ElevatedButton`**（无 MaterialApp 祖先）；**勿**仅内容参与淡出而把黑底留在外面（会黑屏过渡） |
| 回归测试 | `test/welcome_page_test.dart`（整页叠化进首页、不 remount） |

## 交互反馈

- **无 Material 水波**：`lib/core/theme/app_theme.dart` 设 `NoSplash.splashFactory`、透明 splash/highlight；`tabBarTheme` / `iconButtonTheme` 同步。新增可点控件勿单独恢复涟漪。

## 品牌与主题

| 项 | 值 |
|---|---|
| 安装名 / `MaterialApp.title` | `FFWC2026`（`AppInfo.displayName`，`app.dart`） |
| 主题 | Mono-design 炭蓝双模（H=225）：`MonoPalette.dark` / `MonoPalette.light` |
| 跟随系统 | `MaterialApp.themeMode: ThemeMode.system`（`app.dart`） |
| 字体 | Source Sans 3（`google_fonts`） |

## Mono 卡片与描边

`lib/core/theme/mono_palette.dart` + `app_theme.dart`：

| 项 | 说明 |
|---|---|
| 亮色细边 | `MonoTokens.surfaceBorder == true` 时，卡片/宫格 `CardTheme` 与 `mono.cardShape()` / `surfaceDecoration()` 带 `0.5px` `cardBorder` |
| 暗色 | 无描边；靠层级色区分 |
| 阴影 | `Card` elevation **0**；`ColorScheme.surfaceTint` **透明**——**勿**用 M3 elevation 着色（会偏橙红） |
| 自定义容器 | 关于页/规则页玻璃卡等用 `surfaceDecoration()`；默认**不**附带 `boxShadow` |
| **勿用于** | 赛程子 Tab（`ShellTabBar`）、底栏胶囊——它们不是卡片，**勿**套 `surfaceDecoration` 上下边框 |

全局 `tabBarTheme`：`dividerColor: Colors.transparent`、`dividerHeight: 0`。`ShellTabBar` 构造参数再显式设一遍。

## Shell AppBar 标题图

五个 Shell Tab 的 `AppBar.title` 为 PNG 横幅（非 `Text`），统一 `AppBarTitleImage`（`shared/widgets/app_bar_title_image.dart`）：

| Tab | 构造 | 资源 | 读屏文案 |
|---|---|---|---|
| 赛程 | `.games()` | `assets/titles/games.png` | 赛程 |
| 积分榜 | `.rank()` | `assets/titles/rank.png` | 积分榜 |
| 球队 | `.teams()` | `assets/titles/teams.png` | 球队 |
| 场馆 | `.stadium()` | `assets/titles/stadium.png` | 场馆 |
| 关于 | `.about()` | `assets/titles/about.png` | 关于 |

- 默认显示高度 **30** 逻辑像素，`BoxFit.contain`，`centerTitle: true`。
- 叠在彩色 Hero 上时**反白**显示（`Colors.white` + 柔和黑色投影），见 `_InvertedTitleGraphic`。
- 换图：覆盖对应 PNG 后 **Release 打包**（`pubspec` 注册 `assets/titles/` 目录）。
- 详情页 AppBar 仍为 `Text`（队名、小组名等）；仅 Shell 五 Tab 用横幅。
- **点击标题图回顶部**：`AppBarTitleImage` 有可选 `onTap` 参数（`GestureDetector` 包裹）。五 Tab 均已接入：积分榜/球队/场馆各自持有 `ScrollController`（已转为 `ConsumerStatefulWidget`）；关于页持有 `ScrollController`（已转为 `StatefulWidget`）；赛程页调用现有 `_scrollToTop(_tabController.index)`。新增 Tab 须一并接入 `onTap`。

## Shell 色块头图

五 Tab 用 `ShellHeroScaffold`（`shared/widgets/shell_hero_scaffold.dart`）：body 底层绘制 `WorldCupHeroBackground`（`world_cup_hero_skin.dart`），约占屏高 **25%**；透明 `AppBar` 叠于其上。

| Tab | `WorldCupTab` | 页面 |
|---|---|---|
| 赛程 | `schedule` | `features/schedule/schedule_page.dart` |
| 积分榜 | `standings` | `features/standings/standings_page.dart` |
| 球队 | `teams` | `features/teams/teams_page.dart` |
| 场馆 | `stadiums` | `features/stadiums/stadiums_page.dart` |
| 关于 | `about` | `features/about/about_page.dart` |

每个 Shell 页须：

- 根布局 `ShellHeroScaffold(tab: …, appBar: …, body: …)`
- `AppBar`：`backgroundColor: Colors.transparent`、`scrolledUnderElevation: 0`；赛程页另设 `surfaceTintColor: Colors.transparent`
- **勿**在 `AppBar` 上设 `flexibleSpace: WorldCupHeroBackground` 或加大 `toolbarHeight`

| 项 | 说明 |
|---|---|
| 默认参数 | `intensity: 0.60`；`animated: true`（60s）；`transition: 520ms` |
| 切 Tab 过渡 | `_HeroTabMemory` + 520ms 颜色/形状插值 |
| 融入正文 | 绘制层底部多段渐隐到 `MonoPalette.background` |
| 范围 | **仅 Shell 五 Tab**；详情 / 规则页等全屏路由保持炭蓝纯色 `AppBar` |
| 叠层 | `AppBarTitleImage`、`GlassIconButton`、赛程 `ShellTabBar` 等叠在透明 AppBar 上 |
| 新增 Tab | 补 `WorldCupTab` + `_composition`，再接入 `ShellHeroScaffold` |

## Shell 导航

- **5 Tab**：赛程 / 积分榜 / 球队 / 场馆 / 关于（无直播 Tab）
- **底栏**：`CapsuleNavBar` 液态玻璃胶囊，悬浮于内容之上（`Stack`），不占底部横条；双层 `boxShadow`（亮色阴影 alpha 约 0.22）
- **点击**：`GestureDetector`，无涟漪/高亮，仅切换选中态（与下文全应用 `NoSplash` 一致）
- **回顶部（双入口）**：① 赛程 Tab 专属——列表滚过约 120px 后底栏出现 ↑「回顶部」，点击平滑滚顶（`scheduleScrollNavProvider`）；离开赛程 Tab 时 `app.dart` 调 `reset()`，回来后 `SchedulePage` 在 `initState`/`activate` 首帧执行 `_syncScrollNav()`。② 所有 Tab 通用——点击 AppBar 标题图触发 `onTap`，平滑滚回顶部（400ms / `easeOutCubic`）
- 列表底部留白：`CapsuleNavMetrics.bottomInset(context)`，避免被胶囊遮挡

## 赛程页（`/schedule`）

| 项 | 说明 |
|---|---|
| 子 Tab | `ShellTabBar`：`关注` · `赛中 / 未赛` · `完赛`（`TabController` length 3） |
| 默认子 Tab | `initialIndex: 1`（**赛中 / 未赛**），不是「关注」 |
| 子 Tab 样式 | **无**上下细线边框；`dividerHeight: 0`（见 §Mono 卡片与描边） |
| 布局 | `DetailFixedHeaderBody`：赛历/搜索为 Stack **顶栏**（不透明 `Material` 最上层），列表全屏滚于下层；`padding.top = topInset + 8`；`DetailScrollClipScope` 校正离屏缩放视口上沿。**勿** `Column` + `AnimatedSize` 下推列表（`Clip.none` 卡片会盖住顶栏） |
| 搜索 | AppBar 右上角 → 顶栏展开 `ScheduleInlineSearchField` + `ScheduleSearchResults`（`topInset` 同步；与赛历互斥）；按球队中文/英文名、FIFA 代码、名单球员名筛已确定赛程 |
| 赛历入口 | AppBar **左上角** `calendar_month`（与右上搜索对称）；再点收起 |
| 赛历 ⇄ 搜索 | **互斥**：展开其一自动收起另一（含清空赛历选日 / 搜索词） |
| 赛历条 | 顶栏内 `ScheduleDayStrip`（`schedule_day_strip.dart`），`AnimatedSize` 约 320ms 展开收起 |
| 日期范围 | `scheduleCalendarDays`：已确定比赛最早～最晚日，并强制包含用户当前日历日（无固定 6/11–7/19） |
| 默认选中 | `defaultCalendarSelectedDay()` → 用户当前日 |
| 高亮规则 | `highlightCountByDay`：子 Tab **关注** / **赛中·未赛** / **完赛** 各用对应列表计场（仅有该 Tab 比赛的日期才高亮）；切换 Tab 时 `SchedulePageUiState.switchTab()` 刷新条 |
| 列表筛选 | 展开且已选日期时，`ScheduleVisibleMatches.applyDayFilter()` → `filterMatchesByCalendarDay` 筛三 Tab（北京时间，优先 `match_id_map` UTC） |
| 实现勿踩 | **无** `/schedule/calendar` 路由；赛历/搜索状态与可见列表在 `features/schedule/state/schedule_page_state.dart`；日期工具在 `core/utils/match_calendar.dart` |
| 关注 Tab | `followedMatchesProvider`：主客队任一方为已关注 `teamId` 的 `isConfirmed` 比赛，按开赛时间排序 |

## 赛程卡片（MatchTile）

`shared/widgets/match_tile.dart` — 赛程 Tab、内嵌搜索、球队/小组/场馆详情的比赛列表。

| 区域 | 内容 |
|---|---|
| 顶行左 | `kickoffText` 日期 + 周几 + `·` + 小组/阶段（如 `6月12日 周四 · A 组`） |
| 顶行右 | 未赛：`HH:mm`；进行中：蓝点 + 分钟数；完场：`完场` |
| 主行 | 主队 `[TeamBadge 28] 队名` — 居中 `ScorePill`（17px） — `队名 [TeamBadge 28]` 客队 |
| 间距 | 卡片 margin 水平 16、垂直 3；内边距 `14×12` |
| 点击 | 当前**不传** `onTap`（无比赛详情页） |

- **不用** 底部 `StatusChip`、竖排队徽+队名、左上角 live 圆点（状态并入顶行）。
- schedule 页传 `bottomFadeInset` 启用压栈动效，见 §列表卡片动效。

## 积分榜页（`/standings`）

| 项 | 说明 |
|---|---|
| 列表 | 12 组宫格预览，点进 `/group/:name` |
| 刷新 | `RefreshIndicator` 下拉刷新（无 AppBar 刷新按钮） |
| 官方规则 | AppBar 右上 `Icons.help_outline` → `context.push('/standings/rules')` |
| 规则页 | `WorldCupRulesPage`（`DetailScaffold`，AppBar 标题「规则须知」）；顶部玻璃卡片 header（APP 图标 + "2026年美加墨世界杯 / 规则须知"）；各章节用 `_SectionLabel` + `_RuleCard` 卡片排版，与关于页视觉统一；内容依据 FIFA 公布赛制整理 |

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
- 顶区高度经 `SizeChangedLayoutNotifier` 跟踪（赛历/搜索 `AnimatedSize` 动画期间同步 `topInset`）

| 页面 | 固定顶区 | 随滚动 |
|---|---|---|
| 赛程 `/schedule` | `ScheduleDayStrip` 或搜索栏（互斥，`AnimatedSize`） | `TabBarView` 三子 Tab 列表 / `ScheduleSearchResults` |
| 小组详情 `/group/:name` | 积分榜 `GroupTable` 卡片 | `SectionTitle('赛程')` + 比赛列表 |
| 球队详情 `/team/:id` | 国旗 + 小组 / FIFA 排名 | 「赛程」、比赛、「出战名单」、26 人；全页背景：国家队队徽水印（`assets/nation_logo/<fifaCode>.webp` 48 队，`Opacity 0.06`、宽 78%、居中偏上、`IgnorePointer`，缺资产时 `errorBuilder` 静默退化） |

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

只在 `SchedulePage._MatchList` 的 `MatchTile` 上生效——`MatchTile` 接到非 null `bottomFadeInset` 时**外层 `StackedEdgeFade` + 内层 `EdgeProximityScale(verticalTopOnly)`** 双层包装；其它使用 `MatchTile` 的页面不传该参数，保持默认 `EdgeProximityScale(vertical)`。

| 边 | 组件 | 行为 |
|---|---|---|
| 顶部 | `EdgeProximityScale(verticalTopOnly)` | 卡片正常滑出 viewport，按出屏比例缩到 0.88，无 alpha、无位置 clamp |
| 底部 | `StackedEdgeFade`（`shared/widgets/stacked_edge_fade.dart`） | 卡片下沿距 `contentBottom` 还有 **40dp**（`earlyTrigger`）时开始触发，scale 1.0→0.75、alpha 1.0→0.0、圆角 10→36 同步变化；卡片下沿越过 `contentBottom` 时开始**硬停**（`Transform.translate` clamp）；累计"虚拟位移" = `卡片高度 × 2.5` 时完全淡尽（形成"残影"）。alpha < 0.5 时 `IgnorePointer` 防误触；`scrollPosition.pixels < 0`（下拉刷新 overscroll）时不 clamp。曲线 Linear |

底部边缘**触发线**（`contentBottom`）= 屏幕物理底部（`MediaQuery.paddingOf.bottom`，仅避开手势区），不是 `CapsuleNav` 上方——卡片仍可滑入 `CapsuleNav` blur 浮层下方。`SchedulePage._MatchList` 的 sliver `padding.top` = `topInset + 8`、`padding.bottom` = `CapsuleNavMetrics.bottomInset + 8`，确保首卡不被赛历/搜索遮挡、末卡可完整滚出 TabBar 遮挡范围。

### z-order：顶栏用 `DetailFixedHeaderBody`

`Clip.none` + 离屏缩放会让卡片画出列表视口上沿。赛历/搜索若与列表同 `Column` 且列表在后绘制，滚动时卡片会盖住顶栏。赛程页须 `DetailFixedHeaderBody` 把顶栏固定在 Stack 最上层，与底部 sliver 选型无关。

### z-order：底部用反向 paint 的自定义 sliver

底部"压栈"场景下：fading 卡片（高 index）应该被上方滑下来的 normal 卡片（低 index）覆盖；但 `ListView` 默认按 index 顺序 paint，高 index 在上，正好相反。`SchedulePage._MatchList` 因此用 `ZSortedListView`（`shared/widgets/z_sorted_sliver_list.dart`，`extends BoxScrollView`）替代 `ListView.builder`——内部 sliver 是 `ZSortedSliverList`，paint 与 hit-test 都按 `lastChild → firstChild` 反向遍历：

- **底部边缘**：fading 卡片先画 → 在下层；normal 卡片后画 → 在上层覆盖 ✓
- **顶部边缘**：cards 因为 `verticalTopOnly` 仅居中 shrink、不 clamp、相邻卡片之间留出间隙不重叠，paint 顺序对视觉无影响 ✓

为什么不直接 `CustomScrollView + SliverPadding + ZSortedSliverList`：`CustomScrollView` 路径绕开了 `BoxScrollView` 内部的 MediaQuery padding 处理与一些 layout invalidation 行为，导致 calendar/search `AnimatedSize` 切换时 viewport 边界判断与 sliver 重 layout 异常（退出 calendar/search 后下方 cards 空白等）。`ZSortedListView extends BoxScrollView` 走标准 ListView 路径即可避开。顶栏被卡片遮挡须 `DetailFixedHeaderBody`（见上），与 sliver 选型无关。

## 直播跟分

- `liveScoreSyncProvider`（`MyApp` 常驻，`lib/core/live/live_score_sync.dart`）：存在 `MatchStatus.live` 时每 **30 秒** `worldCupDataProvider.refresh()`（对齐 worldcup26.ir 上游节奏；不闪 loading）
- 更新范围：赛程卡 `MatchTile`（`ScorePill`）、球队/小组详情赛程列表、积分榜等依赖主数据的页面
- 无进行中比赛时不轮询；仍可下拉刷新
- 无独立 WebSocket；比分字段来自 `/get/games` 的 `home_score` / `away_score` / `time_elapsed`

## 遗留

- `features/live/live_page.dart` 仍在代码库，**未挂 Shell 路由**（数据与全局跟分相同）
