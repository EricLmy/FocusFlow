@echo off
chcp 65001 >nul
echo ==========================================
echo    FocusFlow GitHub 网络连接诊断工具
echo ==========================================
echo.

echo [1/6] 测试基本网络连接...
ping -n 4 github.com
if %errorlevel% neq 0 (
    echo ❌ GitHub 连接失败
    echo 建议检查网络连接或防火墙设置
) else (
    echo ✅ GitHub 连接正常
)
echo.

echo [2/6] 测试 DNS 解析...
nslookup github.com
echo.

echo [3/6] 检查当前 Git 代理配置...
git config --get http.proxy
if %errorlevel% equ 0 (
    echo 当前使用代理设置
) else (
    echo 未设置代理
)
echo.

echo [4/6] 测试 HTTPS 连接...
curl -I https://github.com --connect-timeout 10
if %errorlevel% neq 0 (
    echo ❌ HTTPS 连接失败
    echo 可能需要配置代理或使用 SSH
) else (
    echo ✅ HTTPS 连接正常
)
echo.

echo [5/6] 检查 SSH 连接...
ssh -T git@github.com -o ConnectTimeout=10
if %errorlevel% equ 1 (
    echo ✅ SSH 连接正常（返回码1是正常的）
) else (
    echo ❌ SSH 连接可能有问题
)
echo.

echo [6/6] 检查远程仓库配置...
git remote -v
echo.

echo ==========================================
echo 诊断完成！
echo.
echo 如果发现连接问题，请参考以下解决方案：
echo 1. 网络问题 → 检查防火墙和网络连接
echo 2. HTTPS 失败 → 运行 setup_ssh.bat 切换到 SSH
echo 3. 代理问题 → 配置正确的代理设置
echo 4. 都不行 → 考虑使用 Gitee 镜像
echo.
echo 详细解决方案请查看：GitHub_Network_Troubleshooting.md
echo ==========================================
echo.
pause