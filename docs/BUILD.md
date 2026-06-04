# Android Release 打包

面向本机 Windows 环境，路径与 `android/local.properties` 一致。

## 环境

| 用途 | 路径 |
|------|------|
| Flutter SDK | `E:\DevTools\flutter` |
| Android SDK | `E:\AndroidSDK` |
| Gradle 缓存（`GRADLE_USER_HOME`） | `E:\DevTools\android-tools\.gradle` |
| Pub 缓存（`PUB_CACHE`，与项目在 **G:** 同盘） | `G:\DevTools\pub-cache`（未设时 `build_release.ps1` 会默认写入） |

`android/local.properties` 已写 `sdk.dir` / `flutter.sdk`，一般无需再配。

**勿**把 `GRADLE_USER_HOME` 指到 `E:\AndroidSDK`：该目录是 SDK 平台/工具，不是 Gradle 缓存；会触发重新拉取 `io.flutter:*` 等依赖，经 `storage.flutter-io.cn` 时易因网络中断失败。

## 何时打包

改完会影响 APK 的代码或资源后，应在本轮工作末尾执行 Release 打包（Agent 默认行为，见 `AGENTS.md`）。

## 一键打包

PowerShell（项目根目录）：

```powershell
cd G:\13_APP_Dev\20260603-FFWC
$env:PATH = 'E:\DevTools\flutter\bin;E:\AndroidSDK\platform-tools;' + $env:PATH
$env:ANDROID_HOME = 'E:\AndroidSDK'
$env:GRADLE_USER_HOME = 'E:\DevTools\android-tools\.gradle'
flutter pub get
flutter build apk --release
```

或：

```powershell
.\scripts\build_release.ps1
```

## 产物

| 文件 | 说明 |
|------|------|
| `build/app/outputs/flutter-apk/app-release.apk` | Release 单包（约 57MB，debug 签名） |
| 项目根 `flutter-apk - 快捷方式.lnk` | 指向上述目录，便于资源管理器打开 |

## 启动图标

| 项 | 说明 |
|---|---|
| 清单引用 | `AndroidManifest` → `android:icon="@mipmap/ic_launcher"` |
| 安装名 | `android:label="FFWC2026"` |
| 资源目录 | `android/app/src/main/res/mipmap-*`（含 `mipmap-anydpi-v26` 自适应图标时会有 `.webp` / `ic_launcher.xml`） |
| 脚本主图（可选） | `assets/icon/app_icon.png`（1024×1024 PNG，仅 **脚本链路** 需要） |
| 设计稿（可选） | `engineering/Appicon.psd` |

**改完图标后必做**：`flutter build apk --release`（或 `.\scripts\build_release.ps1`）→ 安装新 APK；桌面仍旧图时先卸载再装。

### 方式 A：Android Studio Image Asset（当前常用）

1. 打开 `android` 子工程（Gradle 同步成功；项目在 G: 时须配置 `PUB_CACHE`，见下文「常见问题」）。
2. **Android** 视图 → `app` → `res` 右键 **New → Image Asset**（或 **File → New → Image Asset**），名称保持 `ic_launcher`。
3. 完成后执行 **Release 打包**（见上一节）。

勿在 A 之后直接跑 `generate_launcher_icons.py`，会覆盖 AS 生成的 `mipmap-*`。若要与仓库主图对齐，可把 `mipmap-xxxhdpi` 导出图覆盖 `assets/icon/app_icon.png` 再决定是否用脚本重建。

### 方式 B：主图 + 脚本

```powershell
# 覆盖 assets/icon/app_icon.png 后；需 Pillow: pip install pillow
python scripts/generate_launcher_icons.py
.\scripts\build_release.ps1
```

脚本只写入各密度 `ic_launcher.png`，不含自适应 `webp`；若需自适应图标请用方式 A 或自行维护 `mipmap-anydpi-v26`。

## 签名

当前 `android/app/build.gradle.kts` 的 `release` 使用 **debug 签名**，便于本机安装测试。上架 Play 需自备 keystore 并改 `signingConfig`。

## 常见问题

- **Android Studio Gradle 同步：`different roots` / `generateDebugUnitTestConfig` 失败**  
  项目在 **G:**，而默认 Pub 缓存在 **C:**（`%LOCALAPPDATA%\Pub\Cache`），AGP 无法把 `G:\...\build\shared_preferences_android` 与 `C:\...\Pub\Cache\...` 算成相对路径。  
  **处理（推荐，一次配置）：**
  1. 新建目录，例如 `G:\DevTools\pub-cache`。
  2. 系统环境变量（用户级即可）：`PUB_CACHE` = `G:\DevTools\pub-cache`（必须与项目**同一盘符**）。
  3. （可选）把原 `C:\Users\<你>\AppData\Local\Pub\Cache` 内容复制到新目录，避免重新下载。
  4. **完全退出** Android Studio，新开终端在项目根执行：`flutter clean` → `flutter pub get`。
  5. 再打开 `android` 或根工程，点 **Sync Project with Gradle Files**。  
  打包脚本已默认在未设置 `PUB_CACHE` 时使用 `G:\DevTools\pub-cache`（见 `scripts/build_release.ps1`）。IDE 仍须设系统环境变量并重启 AS。  
  **临时绕过（不稳定）：** `flutter clean` 后先只打开 `android` 做 Gradle Sync，成功后再在项目根 `flutter pub get`。
- **Gradle 下载 `flutter_embedding_release` 失败 / TLS / 只下了 16KB**  
  检查 `GRADLE_USER_HOME` 是否为 `E:\DevTools\android-tools\.gradle`。不要对 release 随意 `flutter clean` 除非确需清缓存。
- **终端找不到 `flutter`**  
  把 `E:\DevTools\flutter\bin` 加入本次会话 `PATH`（见上一节），不要依赖未配置的全局 PATH。
