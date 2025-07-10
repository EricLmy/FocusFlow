@echo off
setlocal enabledelayedexpansion

REM ==============================================================================
REM  FocusFlow GitHub 上传脚本
REM  一键将项目代码上传到 GitHub
REM ==============================================================================

echo.
echo ========================================
echo   FocusFlow GitHub 上传工具
echo ========================================
echo.

REM 检查是否安装了 Git
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误：未检测到 Git，请先安装 Git for Windows
    echo 下载地址：https://git-scm.com/download/win
    pause
    exit /b 1
)

echo Git 已安装，继续执行...
echo.

REM 获取用户输入
set /p REPO_NAME="请输入 GitHub 仓库名称 (默认: FocusFlow): "
if "%REPO_NAME%"=="" set REPO_NAME=FocusFlow

set /p GITHUB_USERNAME="请输入您的 GitHub 用户名: "
if "%GITHUB_USERNAME%"=="" (
    echo 错误：GitHub 用户名不能为空
    pause
    exit /b 1
)

set /p COMMIT_MESSAGE="请输入提交信息 (默认: Initial commit): "
if "%COMMIT_MESSAGE%"=="" set COMMIT_MESSAGE=Initial commit

echo.
echo 配置信息：
echo 仓库名称: %REPO_NAME%
echo GitHub 用户名: %GITHUB_USERNAME%
echo 提交信息: %COMMIT_MESSAGE%
echo.

set /p CONFIRM="确认上传？(Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo 操作已取消
    pause
    exit /b 0
)

echo.
echo [1/8] 初始化 Git 仓库...
git init
if %errorlevel% neq 0 (
    echo 错误：Git 初始化失败
    pause
    exit /b 1
)

echo.
echo [2/8] 配置 Git 用户信息...
set /p GIT_EMAIL="请输入您的 Git 邮箱: "
if "%GIT_EMAIL%"=="" (
    echo 错误：Git 邮箱不能为空
    pause
    exit /b 1
)

git config user.name "%GITHUB_USERNAME%"
git config user.email "%GIT_EMAIL%"

echo.
echo [3/8] 添加远程仓库...
set REPO_URL=https://github.com/%GITHUB_USERNAME%/%REPO_NAME%.git
git remote add origin %REPO_URL%
echo 远程仓库地址: %REPO_URL%

echo.
echo [4/8] 创建 .gitignore 文件...
echo # Flutter 相关文件 > .gitignore
echo .dart_tool/ >> .gitignore
echo .packages >> .gitignore
echo .pub/ >> .gitignore
echo build/ >> .gitignore
echo .flutter-plugins >> .gitignore
echo .flutter-plugins-dependencies >> .gitignore
echo .pub-cache/ >> .gitignore
echo .pub-preload-cache/ >> .gitignore
echo # IDE 相关文件 >> .gitignore
echo .idea/ >> .gitignore
echo .vscode/ >> .gitignore
echo *.iml >> .gitignore
echo *.ipr >> .gitignore
echo *.iws >> .gitignore
echo # 系统文件 >> .gitignore
echo .DS_Store >> .gitignore
echo Thumbs.db >> .gitignore
echo # 密钥文件 >> .gitignore
echo android/key.properties >> .gitignore
echo android/app/upload-keystore.jks >> .gitignore
echo # 日志文件 >> .gitignore
echo *.log >> .gitignore

echo.
echo [5/8] 添加所有文件到暂存区...
git add .
if %errorlevel% neq 0 (
    echo 错误：添加文件失败
    pause
    exit /b 1
)

echo.
echo [6/8] 提交代码...
git commit -m "%COMMIT_MESSAGE%"
if %errorlevel% neq 0 (
    echo 错误：代码提交失败
    pause
    exit /b 1
)

echo.
echo [7/8] 设置主分支...
git branch -M main

echo.
echo [8/8] 推送到 GitHub...
echo 注意：如果这是第一次推送，可能需要输入 GitHub 用户名和密码/Token
echo 建议使用 Personal Access Token 代替密码
echo Token 获取地址：https://github.com/settings/tokens
echo.
git push -u origin main

if %errorlevel% neq 0 (
    echo.
    echo 推送失败，可能的原因：
    echo 1. GitHub 仓库不存在，请先在 GitHub 上创建仓库
    echo 2. 认证失败，请检查用户名和密码/Token
    echo 3. 网络连接问题
    echo.
    echo 手动创建仓库步骤：
    echo 1. 访问 https://github.com/new
    echo 2. 仓库名称填写：%REPO_NAME%
    echo 3. 选择 Public 或 Private
    echo 4. 不要初始化 README、.gitignore 或 license
    echo 5. 点击 "Create repository"
    echo 6. 重新运行此脚本
    echo.
    pause
    exit /b 1
)

REM 成功信息
echo.
echo ========================================
echo   上传成功！
echo ========================================
echo.
echo GitHub 仓库地址：
echo %REPO_URL%
echo.
echo 在线查看地址：
echo https://github.com/%GITHUB_USERNAME%/%REPO_NAME%
echo.
echo 后续操作建议：
echo 1. 访问仓库页面，添加 README.md 描述
echo 2. 设置仓库的 Topics 标签
echo 3. 配置 GitHub Pages（如果需要）
echo 4. 设置分支保护规则
echo.

REM 询问是否打开仓库页面
set /p OPEN_BROWSER="是否在浏览器中打开仓库页面？(Y/N): "
if /i "%OPEN_BROWSER%"=="Y" (
    start https://github.com/%GITHUB_USERNAME%/%REPO_NAME%
)

echo.
echo 感谢使用 FocusFlow GitHub 上传工具！
pause