# Camellia Niri Setup

[English](README.md) | [简体中文](README_zh.md)

使用一个自包含、可审计的安装程序，在另一台电脑上复现这套 Arch Linux Niri
桌面环境。本项目受 `niriconf` 启发，但避免了缓存状态、破坏性的卸载步骤以及
与特定机器绑定的输出设备名称。

## 包含的软件

- 图形环境核心：Niri、Waybar、SwayNC、Fuzzel/Rofi、Kitty、门户组件和 Polkit
- 登录管理：SDDM，以及项目内附带的 SilentSDDM 主题
- 外观：Layan Dark、Papirus Dark、Bibata 光标和 Pywal 动态配色
- 文件管理：Thunar、GVfs、Tumbler 和 Ark
- 浏览器：Firefox Developer Edition，以及简体中文语言包
- 输入法：Fcitx5，以及中文输入相关组件
- 基础组件：NetworkManager、PipeWire、蓝牙、剪贴板、亮度、媒体控制、截图、
  电源配置、系统监控和常用命令行工具

完整的软件包列表位于 `packages/official.txt` 和 `packages/aur.txt`。

## 安装

目前仅面向 Arch Linux。请先安装 `yay` 或 `paru`，因为有五个外观或桌面相关
的软件包来自 AUR。安装程序会自动安装 AUR 构建所需的 `base-devel`。

```bash
git clone https://github.com/Iris-NaN/camellia-niri-setup.git
cd camellia-niri-setup
./scripts/verify.sh
./install.sh --dry-run
./install.sh
```

安装程序会将被替换的用户配置备份到：

```text
~/Backups/camellia-niri-setup/<timestamp>/
```

部署系统配置之前，它也会备份 SDDM 和区域设置文件。

常用的部分安装模式：

```bash
./install.sh --packages-only
./install.sh --configs-only
./install.sh --no-system
./install.sh --no-sddm-theme
./install.sh --locale zh_CN.UTF-8
./install.sh --replace-configs
```

默认行为有意保持保守：

- 除非明确提供 `--locale`，否则保留现有系统区域设置。
- 受管理的配置目录会先备份，再与现有内容合并。如需精确替换，请使用
  `--replace-configs`。
- 使用 `--no-sddm-theme` 保留当前登录主题。
- Niri 专用的用户服务绑定到 `niri.service`，不会在 Plasma 会话或纯文本登录中
  启动。
- AUR 外观或辅助包安装失败时会给出警告，但不会阻止用户配置、SDDM 和系统服务
  继续部署。

如果 AUR 软件包使用的 GitHub 下载被阻断，可以为安装程序传入可信的 HTTPS
代理。Git 和 curl 可能读取不同的环境变量，因此同时设置两种写法：

```bash
https_proxy=http://127.0.0.1:7890 \
HTTPS_PROXY=http://127.0.0.1:7890 \
./install.sh
```

在虚拟机中，`127.0.0.1` 指向客体自身。如果代理运行在 libvirt 宿主机上，应改用
宿主机的网桥地址（通常是 `192.168.122.1`），并让代理监听该接口。请将访问范围
限制在虚拟机网络内，不要在其他接口上暴露无需认证的代理。

不要关闭 TLS 验证，也不要随意把 PKGBUILD 的源码地址替换为不可信的下载代理；
AUR 源码仍应正常通过哈希值或签名验证。

## QEMU/KVM 虚拟机

Niri 需要可用的硬件 EGL/GBM 渲染器，并且会主动拒绝 llvmpipe/softpipe 软件 EGL
渲染器。使用 libvirt 虚拟机时，请选择 Virtio 显卡、开启 3D 加速，并为 SPICE
显示开启 OpenGL。虚拟机关机后，可用以下等价命令配置：

```bash
virt-xml VM_NAME --edit --video model.acceleration.accel3d=yes
virt-xml VM_NAME --edit --graphics gl.enable=yes,listen=none
```

修改后应将客体完整关机再启动；只重启客体内核不会重新创建虚拟显卡。较新的
libvirt 会在 `device` 属性中记录实际选择的 Virtio 前端。对于既有虚拟机，先检查
非活动 XML：

```bash
virsh dumpxml --inactive VM_NAME
```

如果启用加速后的显卡模型仍记录为 `device='virtio-vga'`，请用
`virsh edit VM_NAME` 将该属性改为 `device='virtio-vga-gl'`，同时保留
`<acceleration accel3d='yes'/>`。启动虚拟机后，应验证客体内核，而不是只相信
管理器里的 3D 复选框：

```bash
journalctl -b -k | grep -E 'features:|cap sets'
```

正常工作的 VirGL 设备会显示 `features: +virgl`，并且至少有一个 capability set；
`features: -virgl` 表示 QEMU 仍然创建了仅支持 2D 的 Virtio GPU。

宿主机需要安装 QEMU、Mesa 和 `virglrenderer`。如果 Niri 日志出现
`software EGL renderers are skipped` 或 `no allocator available for device`，说明
虚拟机仍在使用软件渲染。启用 SPICE GL 后，一些传统 framebuffer 截图工具会截到
黑图，即使 virt-manager 中的实际桌面显示正常。

## 显示器布局

默认配置不包含输出设备名称、分辨率或位置，因此 Niri 可以在不同硬件上安全
启动。登录后运行：

```bash
niri msg outputs
```

如果新机器也需要将外接显示器放在内置屏幕上方，可以参考
`profiles/outputs-external-top-internal-bottom.kdl`。将其中的输出设备配置块复制到
`config.kdl`，并按实际情况调整。节能配置会自动根据主配置生成。

## 硬件适配

- 只有检测到电池时才会安装低电量服务；它会自动发现 UPower 电池路径，而不是
  假定设备名为 `BAT0` 或 `BAT1`。
- 笔记本背光使用 `brightnessctl`；外接显示器使用 `ddcutil`。
- 使用多个 DDC/CI 显示器时，请在调用亮度辅助脚本前，将 `DDCUTIL_DISPLAY`
  设置为目标显示器的 ddcutil 编号。
- 对应硬件不可用时，Waybar 的电池和背光模块会自动隐藏。

## 壁纸和动态配色

将壁纸放入 `~/Pictures/Wallpapers`。项目内附带一张默认图片。现有的 Pywal 工作流
仍然作为配色来源；安装程序会在目标用户的主目录中重新创建 Waybar、Kitty、
Rofi、SwayNC 和 Wlogout 的相关链接。

## 有意排除的内容

- 生成的 Pywal 缓存和缩略图缓存
- Git 历史和旧配置备份
- 浏览器配置文件、Cookie、密码和个人数据
- 当前电池状态和硬件标识符
- 写死的显示器名称和位置

## 验证

运行 `./scripts/verify.sh`。它会检查所有 Shell 脚本，确认引用的 Niri 辅助脚本
存在，重新生成节能配置，并在已安装 `niri` 时验证两个 KDL 文件。
