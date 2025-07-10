@echo off
setlocal

REM ==============================================================================
REM  FocusFlow 快速推送脚本
REM  适用于已经配置好 Git 仓库的快速代码推送
REM ==============================================================================

echo.
echo ========================================
echo   FocusFlow 快速推送工具
REM ========================================
echo.

REM 检查是否为 Git 仓库
if not exist ".git" (
    echo 错误：当前目录不是 Git 仓库
    echo 请先运行 upload_to_github.bat 进行初始化
    pause
    exit /b 1
)

REM 获取提交信息
set /p COMMIT_MESSAGE="请输入提交信息 (默认: Update code): "
if "%COMMIT_MESSAGE%"=="" set COMMIT_MESSAGE=Update code

echo.
echo [1/4] 检查文件变更...
git status --porcelain
if %errorlevel% neq 0 (
    echo 错误：Git 状态检查失败
    pause
    exit /b 1
)

echo.
echo [2/4] 添加所有变更文件...
git add .
if %errorlevel% neq 0 (
    echo 错误：添加文件失败
    pause
    exit /b 1
)

echo.
echo [3/4] 提交变更...
git commit -m "%COMMIT_MESSAGE%"
if %errorlevel% neq 0 (
    echo 提示：没有新的变更需要提交
    pause
    exit /b 0
)

echo.
echo [4/4] 推送到远程仓库...
git push
if %errorlevel% neq 0 (
    echo 错误：推送失败，请检查网络连接和认证信息
    pause
    exit /b 1
)

echo.
echo ========================================
echo   推送成功！
echo ========================================
echo.
echo 提交信息: %COMMIT_MESSAGE%
echo 推送时间: %date% %time%
echo.

REM 显示远程仓库地址
for /f "tokens=2" %%i in ('git remote get-url origin') do set REPO_URL=%%i
echo 仓库地址: %REPO_URL%
echo.

echo 代码已成功推送到 GitHub！
pause