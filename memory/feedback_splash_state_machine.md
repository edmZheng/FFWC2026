---
name: 启动流程必须按状态机修复
description: 修首次启动视频、欢迎页流程 bug 时，必须先定义允许的状态转换入口
type: feedback
---

修 `SplashScreen` / `WelcomePage` 前必须先写清状态与白名单入口，禁止局部假设宣称已修复。

**当前产品（2026-06-09）：无跳过。** 用户只能等封面视频播完。

**SplashScreen** 状态：`videoPlaying` → `fading` → `splashGone`
- `videoPlaying → fading`：**仅** `isCompleted` / `position>=duration`（`_onVideoTick`）或兜底 timer
- 播放期不接受触摸；**勿**恢复跳过按钮 / 全屏触屏层
- `splashGone` 后勿 `return widget.child`（WelcomePage remount）

**WelcomePage**：`MyApp` 固定槽位 + 欢迎 overlay（黑底+内容一体 `FadeTransition`）
- 点「开始使用」→ overlay 整页淡出 → `_done` 移除 overlay；**勿** `return widget.child`
- **勿**仅内容淡出、黑底留外（黑屏过渡）

**若将来恢复跳过**：真机曾出现 `GestureDetector.onTap` 幽灵触发；须用显式指针跟踪 + 按钮 `IgnorePointer`，勿信「同手势构不成 tap」。

测试：`test/splash_screen_test.dart`、`test/welcome_page_test.dart`
