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

- `EdgeProximityScale`：约 1/3 出屏后触发 **X 轴透视倾斜**（iTunes 唱片式）+ 缩放 + 轻微位移/透明度
- 滚动列表/宫格设 `clipBehavior: Clip.none`，避免 3D 被裁切
- 已用于：赛程卡、积分榜/球队/场馆宫格、比赛详情 Card

## 遗留

- `features/live/live_page.dart` 与 `livePollingProvider` 仍在代码库，**未挂 Shell 路由**
