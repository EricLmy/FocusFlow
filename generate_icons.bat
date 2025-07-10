@echo off
setlocal

REM ==============================================================================
REM  FocusFlow App Icon Generator Script
REM  This script automatically generates app icons for Android and iOS platforms.
REM ==============================================================================

echo.
echo ========================================
echo   FocusFlow 应用图标生成工具
echo ========================================
echo.

echo 正在安装依赖包...
flutter pub get

if %errorlevel% neq 0 (
    echo 错误：依赖包安装失败！
    pause
    exit /b 1
)

echo.
echo 正在生成应用图标...
flutter pub run flutter_launcher_icons:main

if %errorlevel% neq 0 (
    echo 错误：图标生成失败！
    echo 请检查 assets/logo.svg 文件是否存在。
    pause
    exit /b 1
)

echo.
echo ========================================
echo   图标生成完成！
echo ========================================
echo.
echo 生成的图标文件位置：
echo - Android: android/app/src/main/res/mipmap-*/
echo - iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/
echo.
echo 下一步操作：
echo 1. 清理构建缓存：flutter clean
echo 2. 重新构建应用：flutter build apk --release
echo 3. 安装新版本应用以查看图标更改
echo.
echo 注意：在某些设备上，可能需要重启设备才能看到图标更改。
echo.
pause