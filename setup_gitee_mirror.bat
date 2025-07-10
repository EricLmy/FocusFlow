@echo off
chcp 65001 >nul
echo ==========================================
echo    FocusFlow Gitee 镜像设置工具
echo ==========================================
echo.
echo 此工具将帮助您设置 Gitee 作为 GitHub 的镜像
echo 适用于 GitHub 连接不稳定的情况
echo.

echo [提示] 使用前请确保：
echo 1. 已在 Gitee 注册账号：https://gitee.com/
echo 2. 已在 Gitee 创建名为 'FocusFlow' 的仓库
echo.
set /p continue="是否继续设置 Gitee 镜像？(Y/n): "
if /i "!continue!"=="n" exit /b 0
echo.

echo [1/5] 获取 Gitee 用户信息...
set /p gitee_username="请输入您的 Gitee 用户名: "
if "!gitee_username!"=="" (
    echo ❌ 用户名不能为空
    pause
    exit /b 1
)
echo.

echo [2/5] 添加 Gitee 远程仓库...
git remote add gitee https://gitee.com/!gitee_username!/FocusFlow.git
if %errorlevel% neq 0 (
    echo ⚠️  Gitee 远程仓库可能已存在，尝试更新...
    git remote set-url gitee https://gitee.com/!gitee_username!/FocusFlow.git
    if %errorlevel% neq 0 (
        echo ❌ Gitee 远程仓库配置失败
        pause
        exit /b 1
    )
)
echo ✅ Gitee 远程仓库配置成功
echo.

echo [3/5] 推送代码到 Gitee...
echo 正在推送代码到 Gitee（可能需要输入用户名和密码）...
git push -u gitee main
if %errorlevel% neq 0 (
    echo ❌ 推送到 Gitee 失败
    echo.
    echo 可能的原因：
    echo 1. 用户名或密码错误
    echo 2. Gitee 仓库不存在或无权限
    echo 3. 网络连接问题
    echo.
    echo 请检查以下信息：
    echo - Gitee 用户名：!gitee_username!
    echo - 仓库地址：https://gitee.com/!gitee_username!/FocusFlow
    echo.
    pause
    exit /b 1
)
echo ✅ 代码已成功推送到 Gitee
echo.

echo [4/5] 设置 Gitee 同步到 GitHub...
echo.
echo 📋 手动设置 Gitee 同步到 GitHub 的步骤：
echo 1. 访问您的 Gitee 仓库：https://gitee.com/!gitee_username!/FocusFlow
echo 2. 点击 "管理" → "仓库镜像管理"
echo 3. 添加镜像仓库：https://github.com/EricLmy/FocusFlow.git
echo 4. 设置同步频率（建议：实时同步）
echo 5. 输入 GitHub 用户名和 Personal Access Token
echo.
set /p open_gitee="是否打开 Gitee 仓库页面进行设置？(Y/n): "
if /i "!open_gitee!"=="" set open_gitee=Y
if /i "!open_gitee!"=="y" (
    start https://gitee.com/!gitee_username!/FocusFlow
    echo 已在浏览器中打开 Gitee 仓库页面
)
echo.

echo [5/5] 验证配置...
echo 当前远程仓库配置：
git remote -v
echo.

echo ==========================================
echo 🎉 Gitee 镜像设置完成！
echo ==========================================
echo.
echo 📖 使用说明：
echo.
echo 1. 日常开发推送到 Gitee：
echo    git push gitee main
echo.
echo 2. 推送到 GitHub（如果网络允许）：
echo    git push origin main
echo.
echo 3. 同时推送到两个平台：
echo    git push gitee main && git push origin main
echo.
echo 4. 使用快速推送脚本：
echo    - 修改 quick_push.bat 添加 Gitee 推送
echo    - 或创建专门的 push_to_gitee.bat
echo.
echo 📝 后续步骤：
echo 1. 在 Gitee 设置同步到 GitHub（如上所述）
echo 2. 获取 GitHub Personal Access Token
echo 3. 配置自动同步
echo.
echo ==========================================
echo.
pause