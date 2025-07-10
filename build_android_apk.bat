@echo off
chcp 65001 >nul
echo ========================================
echo     FocusFlow Android APK 打包工具
echo ========================================
echo.

echo 当前工作目录: %cd%
echo.

echo 选择打包类型:
echo 1. 调试版本 (Debug APK)
echo 2. 发布版本 (Release APK)
echo 3. 分架构打包 (Split APK)
echo 4. App Bundle 格式
echo.
set /p choice=请输入选择 (1-4): 

if "%choice%"=="1" goto debug
if "%choice%"=="2" goto release
if "%choice%"=="3" goto split
if "%choice%"=="4" goto bundle
goto invalid

:debug
echo.
echo 正在构建调试版本 APK...
flutter build apk --debug
echo.
echo 构建完成！APK 文件位置:
echo %cd%\build\app\outputs\flutter-apk\app-debug.apk
goto end

:release
echo.
echo 正在构建发布版本 APK...
flutter build apk --release
echo.
echo 构建完成！APK 文件位置:
echo %cd%\build\app\outputs\flutter-apk\app-release.apk
goto end

:split
echo.
echo 正在构建分架构 APK...
flutter build apk --split-per-abi
echo.
echo 构建完成！APK 文件位置:
echo %cd%\build\app\outputs\flutter-apk\
echo 将生成多个架构的 APK 文件
goto end

:bundle
echo.
echo 正在构建 App Bundle...
flutter build appbundle --release
echo.
echo 构建完成！AAB 文件位置:
echo %cd%\build\app\outputs\bundle\release\app-release.aab
goto end

:invalid
echo 无效选择，请重新运行脚本。
goto end

:end
echo.
echo ========================================
echo 打包完成！
echo ========================================
echo.
echo 注意事项:
echo 1. 确保已安装 Flutter SDK 和 Android SDK
echo 2. 发布版本需要配置签名证书
echo 3. 生成的文件可直接安装到 Android 设备
echo.
pause