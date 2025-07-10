@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
echo ==========================================
echo    FocusFlow 快速推送工具
echo ==========================================
echo.

echo [1/5] 检查 Git 仓库状态...
if not exist ".git" (
    echo ❌ 当前目录不是 Git 仓库
    echo 请确保在项目根目录运行此脚本
    pause
    exit /b 1
)
echo ✅ Git 仓库检查通过
echo.

echo [2/5] 检查可用的远程仓库...
echo 当前配置的远程仓库：
git remote -v
echo.

echo 选择推送目标：
echo 1. GitHub (origin)
echo 2. Gitee (gitee)
echo 3. 同时推送到两个平台
echo 4. 仅本地提交（不推送）
echo.
set /p push_target="请选择 (1-4, 默认: 1): "
if "!push_target!"=="" set push_target=1
echo.

echo [3/5] 获取提交信息...
set /p commit_message="请输入提交信息 (默认: 更新代码): "
if "!commit_message!"=="" set commit_message=更新代码
echo 提交信息: !commit_message!
echo.

echo [4/5] 添加并提交变更...
git add .
if %errorlevel% neq 0 (
    echo ❌ 添加文件失败
    pause
    exit /b 1
)

git commit -m "!commit_message!"
if %errorlevel% neq 0 (
    echo ⚠️  没有新的变更需要提交
    if "!push_target!"=="4" (
        echo ✅ 本地操作完成
        goto end
    )
else
    echo ✅ 代码提交成功
)
echo.

echo [5/5] 推送到远程仓库...
if "!push_target!"=="1" (
    echo 正在推送到 GitHub...
    call :push_to_github
) else if "!push_target!"=="2" (
    echo 正在推送到 Gitee...
    call :push_to_gitee
) else if "!push_target!"=="3" (
    echo 正在推送到 GitHub 和 Gitee...
    call :push_to_github
    call :push_to_gitee
) else if "!push_target!"=="4" (
    echo ✅ 仅本地提交完成
    goto end
) else (
    echo ❌ 无效选择，默认推送到 GitHub
    call :push_to_github
)

goto end

:push_to_github
git push origin main
if %errorlevel% neq 0 (
    echo ❌ GitHub 推送失败
    echo.
    echo 可能的解决方案：
    echo 1. 检查网络连接
    echo 2. 运行 network_check.bat 诊断网络问题
    echo 3. 运行 setup_ssh.bat 切换到 SSH 连接
    echo 4. 运行 setup_gitee_mirror.bat 使用 Gitee 镜像
    echo.
    set github_failed=1
) else (
    echo ✅ GitHub 推送成功
    set github_success=1
)
goto :eof

:push_to_gitee
git remote get-url gitee >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Gitee 远程仓库未配置
    echo 请先运行 setup_gitee_mirror.bat 设置 Gitee 镜像
    goto :eof
)

git push gitee main
if %errorlevel% neq 0 (
    echo ❌ Gitee 推送失败
    echo 请检查 Gitee 仓库配置和网络连接
    set gitee_failed=1
) else (
    echo ✅ Gitee 推送成功
    set gitee_success=1
)
goto :eof

:end
echo.
echo ==========================================
if defined github_success (
    echo 🎉 代码已成功推送到 GitHub！
    echo GitHub 仓库: https://github.com/EricLmy/FocusFlow
)
if defined gitee_success (
    echo 🎉 代码已成功推送到 Gitee！
)
if defined github_failed (
    echo ⚠️  GitHub 推送失败，请检查网络连接
)
if defined gitee_failed (
    echo ⚠️  Gitee 推送失败，请检查配置
)
echo ==========================================
echo.

if defined github_success (
    set /p open_repo="是否在浏览器中打开 GitHub 仓库？(Y/n): "
    if /i "!open_repo!"=="" set open_repo=Y
    if /i "!open_repo!"=="y" start https://github.com/EricLmy/FocusFlow
)
echo.
pause