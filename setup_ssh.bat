@echo off
chcp 65001 >nul
echo ==========================================
echo    FocusFlow SSH 连接设置工具
echo ==========================================
echo.

echo [1/4] 检查现有 SSH 密钥...
if exist "%USERPROFILE%\.ssh\id_rsa.pub" (
    echo ✅ 发现现有 SSH 密钥
    echo.
    echo 您的公钥内容：
    echo ----------------------------------------
    type "%USERPROFILE%\.ssh\id_rsa.pub"
    echo ----------------------------------------
    echo.
    set /p use_existing="是否使用现有密钥？(Y/n): "
    if /i "!use_existing!"=="n" goto generate_new
    goto configure_remote
) else (
    echo ❌ 未找到 SSH 密钥，将生成新密钥
    goto generate_new
)

:generate_new
echo.
echo [2/4] 生成新的 SSH 密钥...
if not exist "%USERPROFILE%\.ssh" mkdir "%USERPROFILE%\.ssh"
ssh-keygen -t rsa -b 4096 -C "developer@focusflow.com" -f "%USERPROFILE%\.ssh\id_rsa" -N ""
if %errorlevel% neq 0 (
    echo ❌ SSH 密钥生成失败
    pause
    exit /b 1
)
echo ✅ SSH 密钥生成成功
echo.
echo 您的新公钥内容：
echo ----------------------------------------
type "%USERPROFILE%\.ssh\id_rsa.pub"
echo ----------------------------------------
echo.

:configure_remote
echo [3/4] 配置远程仓库使用 SSH...
git remote set-url origin git@github.com:EricLmy/FocusFlow.git
if %errorlevel% neq 0 (
    echo ❌ 远程仓库配置失败
    pause
    exit /b 1
)
echo ✅ 远程仓库已配置为 SSH 方式
echo.

echo [4/4] 测试 SSH 连接...
echo 正在测试 SSH 连接到 GitHub...
ssh -T git@github.com -o ConnectTimeout=10
if %errorlevel% equ 1 (
    echo ✅ SSH 连接测试成功！
    echo.
    echo ==========================================
    echo 🎉 SSH 设置完成！
    echo ==========================================
    echo.
    echo 现在您可以使用以下命令推送代码：
    echo   git push -u origin main
    echo.
    echo 或者直接运行：quick_push.bat
    echo ==========================================
) else (
    echo ❌ SSH 连接测试失败
    echo.
    echo 请按照以下步骤手动配置：
    echo.
    echo 1. 复制上面显示的公钥内容
    echo 2. 访问 GitHub Settings: https://github.com/settings/keys
    echo 3. 点击 "New SSH key"
    echo 4. 粘贴公钥内容并保存
    echo 5. 等待几分钟后重新运行此脚本测试
    echo.
    echo 或者访问详细教程：
    echo https://docs.github.com/en/authentication/connecting-to-github-with-ssh
)

echo.
echo 当前远程仓库配置：
git remote -v
echo.

set /p open_github="是否打开 GitHub SSH 设置页面？(Y/n): "
if /i "!open_github!"=="" set open_github=Y
if /i "!open_github!"=="y" (
    start https://github.com/settings/keys
    echo 已在浏览器中打开 GitHub SSH 设置页面
)

echo.
pause