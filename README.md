# Wake On Mijia (wom)

通过订阅巴法云主题并接收控制消息，在本地网络广播 WOL 魔术包以唤醒指定设备。项目提供 systemd 与 SysV init 两种安装方式，支持自动重连、心跳与日志轮转，适合守护进程部署。

## 功能特性
- 连接 `bemfa.com` 并订阅指定主题，收到 `on` 指令后发送 WOL 魔术包
- 自动重连与心跳维持（30 秒 `ping`），健壮性更好
- 日志写入 `wol.log` 并进行 5MB 大小轮转
- 支持 systemd 与 SysV init 安装，安装脚本自动判断环境
- `config.ini` 管理用户参数，无需改动代码

## 目录结构
- `main.py`：守护进程入口，网络连接与 WOL 逻辑
- `config.ini`：用户参数配置（服务器、UID、主题、MAC）
- `install.sh`：安装脚本，自动选择 systemd 或 init，并提示输入 `main.py` 路径
- `wom.service`：systemd 单元模板（安装脚本会按实际路径生成）
- `bemfa_wol`：OpenWrt `procd` 示例脚本（如需在 OpenWrt 上使用可参考）

## 快速开始
1. 准备环境
   - 具有 `python3` 的 Linux 主机
   - 可访问外网网络（连接 `bemfa.com:8344`）
   - 设备网卡支持 WOL，且局域网允许 UDP 广播端口 `9`
2. 配置参数
   - 编辑 `config.ini`：
     ```ini
     [server]
     ip=bemfa.com
     port=8344

     [auth]
     uid=<你的UID>

     [topic]
     name=<你的主题>

     [device]
     mac=<你的设备MAC，如 CC:28:AA:04:00:53>
     ```
3. 安装服务
   - 执行：`sudo bash install.sh`或者`./install.sh`
   - 按提示输入 `main.py` 的绝对路径，例如：`/root/bemfa/wol/main.py`
   - 脚本将自动：
     - 若支持 systemd：生成并安装 `wom.service`，启用并启动
     - 若不支持 systemd：生成 `/etc/init.d/wom`，注册并启动
4. 验证运行
   - systemd：
     - 查看状态：`sudo systemctl status wom`
     - 查看日志：`journalctl -u wom -f`
   - init：
     - 查看状态：`/etc/init.d/wom status`
     - 日志：`/var/log/wom.log`

## 配置说明
- `server.ip` / `server.port`：巴法云服务器地址与端口
- `auth.uid`：你的 UID，请替换为自己的值
- `topic.name`：订阅主题名，控制消息形如 `topic=<name>&msg=on`
- `device.mac`：被唤醒设备的 MAC 地址，支持 `AA:BB:CC:DD:EE:FF`

## 服务管理
- systemd
  - 启动：`sudo systemctl start wom`
  - 重启：`sudo systemctl restart wom`
  - 开机自启：`sudo systemctl enable wom`
  - 停止：`sudo systemctl stop wom`
  - 日志：`journalctl -u wom -f`
- init
  - 启动：`/etc/init.d/wom start`
  - 重启：`/etc/init.d/wom restart`
  - 停止：`/etc/init.d/wom stop`
  - 开机自启（Debian/Ubuntu）：`sudo update-rc.d wom defaults`

## 日志与排错
- 业务日志：`wol.log`（与 `main.py` 同目录），超过 5MB 轮转到 `wol.log.bak`
- systemd：使用 `journal`，查看 `journalctl -u wom -f`
- init：标准输出/错误重定向至 `/var/log/wom.log`
- 常见问题：
  - 无法连接服务器：检查防火墙与 DNS，确认 `bemfa.com:8344` 可达
  - 收到指令但未唤醒：
    - 检查目标主机 BIOS/操作系统是否启用 WOL
    - 局域网是否允许广播，端口 `9` 是否被阻断
    - MAC 地址是否正确，交换机/AP 是否隔离广播
  - 网络未就绪导致启动失败：systemd 单元使用 `network-online.target`，确保网络服务可用

## 运行与开发
- 手动运行（调试）：
  - `cd <main.py所在目录>`
  - `python3 main.py`
- 修改配置无需改代码，直接编辑 `config.ini`

## 卸载
- systemd：
  - `sudo systemctl stop wom && sudo systemctl disable wom`
  - 删除单元文件：`sudo rm /etc/systemd/system/wom.service && sudo systemctl daemon-reload`
- init：
  - 停止并删除脚本：`/etc/init.d/wom stop && sudo rm /etc/init.d/wom`
  - 取消自启（Debian/Ubuntu）：`sudo update-rc.d -f wom remove`

## 安全建议
- 不要在公共仓库中提交真实 UID
- 如需非 `root` 运行，请为运行用户配置访问日志/工作目录权限

## 许可证
- 未设置许可证。如需开源发布，请添加合适的许可证文件。