# Android Release 打包

面向本机 Windows 环境，路径与 `android/local.properties` 一致。

## 环境

| 用途 | 路径 |
|------|------|
| Flutter SDK | `E:\DevTools\flutter` |
| Android SDK | `E:\AndroidSDK` |
| Gradle 缓存（`GRADLE_USER_HOME`） | `E:\DevTools\android-tools\.gradle` |

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
| `build/app/outputs/flutter-apk/app-release.apk` | Release 单包（约 56MB，debug 签名） |
| 项目根 `flutter-apk - 快捷方式.lnk` | 指向上述目录，便于资源管理器打开 |

## 启动图标

| 项 | 说明 |
|---|---|
| 主图 | `assets/icon/app_icon.png`（建议 1024×1024 正方 PNG） |
| 设计稿 | `engineering/Appicon.psd`（可选，导出后再覆盖主图） |
| 安装名 | `AndroidManifest` → `android:label="FFWC2026"` |
| 引用 | `@mipmap/ic_launcher` → `android/app/src/main/res/mipmap-*/ic_launcher.png` |

换图标流程：**覆盖主图** → 生成各密度 → **Release 打包**（仅改 mipmap 不打包，桌面图标不会变）。

```powershell
# 需已安装 Pillow: pip install pillow
python scripts/generate_launcher_icons.py
.\scripts\build_release.ps1
```

## 签名

当前 `android/app/build.gradle.kts` 的 `release` 使用 **debug 签名**，便于本机安装测试。上架 Play 需自备 keystore 并改 `signingConfig`。

## 常见问题

- **Gradle 下载 `flutter_embedding_release` 失败 / TLS / 只下了 16KB**  
  检查 `GRADLE_USER_HOME` 是否为 `E:\DevTools\android-tools\.gradle`。不要对 release 随意 `flutter clean` 除非确需清缓存。
- **终端找不到 `flutter`**  
  把 `E:\DevTools\flutter\bin` 加入本次会话 `PATH`（见上一节），不要依赖未配置的全局 PATH。
