# Release APK — 与本地已验证环境一致（勿改 GRADLE_USER_HOME 为 AndroidSDK 根目录）
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$env:PATH = 'E:\DevTools\flutter\bin;E:\AndroidSDK\platform-tools;' + $env:PATH
$env:ANDROID_HOME = 'E:\AndroidSDK'
$env:GRADLE_USER_HOME = 'E:\DevTools\android-tools\.gradle'
# 项目在 G: 时 Pub 缓存也须在 G:，否则 Android Gradle 报 different roots
if (-not $env:PUB_CACHE) { $env:PUB_CACHE = 'G:\DevTools\pub-cache' }

flutter pub get
flutter build apk --release

Write-Host ''
Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk"
Write-Host "快捷方式目录: build\app\outputs\flutter-apk\"
