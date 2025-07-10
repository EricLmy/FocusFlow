@echo off
setlocal

REM ==============================================================================
REM  FocusFlow Release Preparation Script
REM  This script automates the key steps for preparing the app for release.
REM ==============================================================================

echo.
echo ========================================
echo   FocusFlow 上线准备自动化脚本
echo ========================================
echo.

echo 开始执行上线准备流程...
echo.

REM Step 1: Code Quality Check
echo [1/6] 代码质量检查...
echo 正在执行 flutter analyze...
flutter analyze

if %errorlevel% neq 0 (
    echo 警告：代码分析发现问题，请检查并修复后再继续。
    echo 是否继续执行？(Y/N)
    set /p continue=""
    if /i not "%continue%"=="Y" (
        echo 脚本已终止。
        pause
        exit /b 1
    )
)

echo.
echo [2/6] 运行单元测试...
flutter test

if %errorlevel% neq 0 (
    echo 警告：单元测试失败，请检查并修复后再继续。
    echo 是否继续执行？(Y/N)
    set /p continue=""
    if /i not "%continue%"=="Y" (
        echo 脚本已终止。
        pause
        exit /b 1
    )
)

REM Step 2: Generate App Icons
echo.
echo [3/6] 生成应用图标...
flutter pub get
flutter pub run flutter_launcher_icons:main

if %errorlevel% neq 0 (
    echo 警告：图标生成失败，请检查 assets/logo.svg 文件。
    echo 是否继续执行？(Y/N)
    set /p continue=""
    if /i not "%continue%"=="Y" (
        echo 脚本已终止。
        pause
        exit /b 1
    )
)

REM Step 3: Clean and Build
echo.
echo [4/6] 清理项目缓存...
flutter clean

echo.
echo [5/6] 重新获取依赖...
flutter pub get

echo.
echo [6/6] 构建发布版本...
flutter build apk --release

if %errorlevel% neq 0 (
    echo 错误：发布版本构建失败！
    pause
    exit /b 1
)

REM Success Message
echo.
echo ========================================
echo   上线准备完成！
echo ========================================
echo.
echo 构建成功！发布文件位置：
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo 下一步建议：
echo 1. 在真实设备上测试APK文件
echo 2. 检查应用图标是否正确显示
echo 3. 验证所有核心功能正常工作
echo 4. 准备应用商店发布资料（截图、描述等）
echo 5. 配置应用签名（参考 docs\App_Signing_Guide.md）
echo.
echo 完整的上线检查清单请参考：
echo docs\App_Launch_Checklist.md
echo.

REM Optional: Open build folder
echo 是否打开构建文件夹？(Y/N)
set /p open_folder=""
if /i "%open_folder%"=="Y" (
    explorer build\app\outputs\flutter-apk
)

echo.
echo 准备工作完成，祝您上线顺利！
pause