@echo off
setlocal

REM ==============================================================================
REM  FocusFlow App Build Script
REM  This script provides commands to build Android and iOS applications.
REM ==============================================================================

:menu
echo.
echo Select the platform to build:
echo 1. Build Android APK
echo 2. Build Android App Bundle (for Google Play)
echo 3. Build iOS App (for App Store)
echo 4. Exit
echo.

set /p choice="Enter your choice: "

if not '%choice%'=='' set choice=%choice:~0,1%

if '%choice%'=='1' goto build_android_apk
if '%choice%'=='2' goto build_android_bundle
if '%choice%'=='3' goto build_ios
if '%choice%'=='4' goto exit_script

echo Invalid choice. Please try again.
goto menu

:build_android_apk
echo.
echo Building Android APK...
flutter build apk --release
echo.
echo APK build finished. You can find the file in build/app/outputs/flutter-apk/
goto end

:build_android_bundle
echo.
echo Building Android App Bundle...
flutter build appbundle --release
echo.
echo App Bundle build finished. You can find the file in build/app/outputs/bundle/release/
goto end

:build_ios
echo.
echo 错误：无法在Windows系统上构建iOS应用。
echo 请注意：构建iOS应用需要macOS系统和Xcode环境。
echo 请在Mac电脑上执行以下命令：
echo flutter build ipa --release
echo.
goto end

:exit_script
echo Exiting...
exit /b

:end
echo.
echo Build process completed.
pause