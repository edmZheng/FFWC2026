# Release APK — 与本地已验证环境一致（勿改 GRADLE_USER_HOME 为 AndroidSDK 根目录）
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$env:PATH = 'E:\DevTools\flutter\bin;E:\AndroidSDK\platform-tools;' + $env:PATH
$env:ANDROID_HOME = 'E:\AndroidSDK'
$env:GRADLE_USER_HOME = 'E:\DevTools\android-tools\.gradle'

flutter pub get
flutter build apk --release

Write-Host ''
Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk"
Write-Host "快捷方式目录: build\app\outputs\flutter-apk\"
