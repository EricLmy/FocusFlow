# GitHub 网络连接问题解决指南

## 问题描述
当尝试推送代码到 GitHub 时，出现以下错误：
```
fatal: unable to access 'https://github.com/EricLmy/FocusFlow.git/': Failed to connect to github.com port 443 after 21115 ms: Could not connect to server
```

## 解决方案

### 方案一：检查网络连接
1. **测试网络连接**
   ```bash
   ping github.com
   ```

2. **检查防火墙设置**
   - 确保防火墙允许 Git 访问网络
   - 临时关闭防火墙测试连接

### 方案二：使用代理设置
如果您在使用代理，需要配置 Git 代理：

```bash
# HTTP 代理
git config --global http.proxy http://proxy.server:port
git config --global https.proxy https://proxy.server:port

# SOCKS5 代理
git config --global http.proxy socks5://proxy.server:port
git config --global https.proxy socks5://proxy.server:port

# 清除代理设置
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### 方案三：更换 GitHub 访问方式

#### 3.1 使用 SSH 方式（推荐）
1. **生成 SSH 密钥**
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   ```

2. **添加 SSH 密钥到 GitHub**
   - 复制公钥内容：`cat ~/.ssh/id_rsa.pub`
   - 在 GitHub Settings > SSH and GPG keys 中添加

3. **更改远程仓库地址**
   ```bash
   git remote set-url origin git@github.com:EricLmy/FocusFlow.git
   ```

#### 3.2 使用 GitHub CLI（推荐）
1. **安装 GitHub CLI**
   - 下载：https://cli.github.com/
   - 或使用包管理器安装

2. **认证登录**
   ```bash
   gh auth login
   ```

3. **推送代码**
   ```bash
   gh repo create EricLmy/FocusFlow --public
   git push -u origin main
   ```

### 方案四：DNS 解析问题
1. **刷新 DNS 缓存**
   ```cmd
   ipconfig /flushdns
   ```

2. **更换 DNS 服务器**
   - 8.8.8.8 (Google DNS)
   - 1.1.1.1 (Cloudflare DNS)
   - 114.114.114.114 (国内 DNS)

### 方案五：使用国内 Git 镜像

#### 5.1 Gitee 镜像同步
1. **在 Gitee 创建仓库**
   - 访问 https://gitee.com/
   - 创建新仓库 `FocusFlow`

2. **添加 Gitee 远程仓库**
   ```bash
   git remote add gitee https://gitee.com/your_username/FocusFlow.git
   git push -u gitee main
   ```

3. **设置 Gitee 同步到 GitHub**
   - 在 Gitee 仓库设置中启用 GitHub 同步

#### 5.2 使用 GitHub 镜像站
```bash
# 临时使用镜像
git remote set-url origin https://github.com.cnpmjs.org/EricLmy/FocusFlow.git

# 推送后改回原地址
git remote set-url origin https://github.com/EricLmy/FocusFlow.git
```

## 快速解决脚本

### 网络诊断脚本 (network_check.bat)
```batch
@echo off
echo 正在诊断网络连接问题...
echo.

echo 1. 测试 GitHub 连接
ping -n 4 github.com
echo.

echo 2. 测试 DNS 解析
nslookup github.com
echo.

echo 3. 检查当前 Git 配置
git config --list | findstr proxy
echo.

echo 4. 测试 HTTPS 连接
curl -I https://github.com
echo.

echo 诊断完成！
pause
```

### SSH 快速设置脚本 (setup_ssh.bat)
```batch
@echo off
echo 设置 SSH 连接到 GitHub...
echo.

echo 1. 检查是否已有 SSH 密钥
if exist "%USERPROFILE%\.ssh\id_rsa.pub" (
    echo SSH 密钥已存在
    type "%USERPROFILE%\.ssh\id_rsa.pub"
) else (
    echo 生成新的 SSH 密钥...
    ssh-keygen -t rsa -b 4096 -C "developer@focusflow.com" -f "%USERPROFILE%\.ssh\id_rsa" -N ""
    echo SSH 密钥已生成
    type "%USERPROFILE%\.ssh\id_rsa.pub"
)

echo.
echo 2. 更改远程仓库地址为 SSH
git remote set-url origin git@github.com:EricLmy/FocusFlow.git

echo.
echo 请将上面的公钥添加到 GitHub Settings > SSH and GPG keys
echo 然后运行: git push -u origin main
echo.
pause
```

## 推荐解决顺序

1. **首先尝试**：检查网络连接和防火墙
2. **如果网络正常**：使用 SSH 方式连接
3. **如果 SSH 不可用**：使用 GitHub CLI
4. **如果都不行**：使用 Gitee 镜像同步
5. **最后选择**：使用代理或镜像站

## 验证推送成功
推送成功后，访问以下地址验证：
- GitHub 仓库：https://github.com/EricLmy/FocusFlow
- 检查文件是否完整上传
- 确认提交历史正确

## 后续使用
连接问题解决后，可以继续使用 `quick_push.bat` 脚本进行日常代码推送。

## 常见问题

**Q: 为什么会出现连接超时？**
A: 可能是网络防火墙、代理设置、DNS 解析或 GitHub 服务访问限制导致。

**Q: SSH 和 HTTPS 哪个更好？**
A: SSH 更安全且不需要每次输入密码，推荐使用 SSH 方式。

**Q: 可以同时推送到多个平台吗？**
A: 可以，添加多个远程仓库地址，分别推送到 GitHub、Gitee 等平台。

---

*如果以上方案都无法解决问题，建议联系网络管理员或使用移动热点测试网络环境。*