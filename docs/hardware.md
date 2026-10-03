# 本机驱动档案

这份文档记录当前这台机器的硬件、它使用的驱动，以及几个只能在实机上发现的
坑。目的是：将来重装系统、换内核或换机器时，不用再重新踩一遍。

驱动现状可以用仓库里的只读脚本随时复查：

```bash
./scripts/verify-drivers.sh
```

## 机器

| 项目 | 值 |
| --- | --- |
| 厂商 / 型号 | HUAWEI HLY-WX9XX（MateBook D 14，主板 HLY-WX9XX-PCB）|
| CPU | AMD Ryzen 5 3550H with Radeon Vega Mobile Gfx |
| 内存 | 14 GiB |
| 存储 | SK hynix PC601 NVMe 512 GB（`nvme0n1`）|
| 内核 | linux-zen 7.2.8 |
| 引导 | GRUB 2.14，EFI |

## 各设备驱动一览

| 设备 | 内核驱动 | 固件 / 说明 |
| --- | --- | --- |
| GPU | `amdgpu` | PCI `1002:15d8`（Picasso / Raven 2），Mesa 26.2.3 + `vulkan-radeon`，picasso 固件齐全 |
| 无线 | `rtw88_8822ce` | Realtek RTL8822CE，`rtw88/rtw8822c_fw.bin`，固件版本 9.9.15 |
| 蓝牙 | `btusb` + `btrtl` | USB `1358:c123`，加载 `rtl_bt/rtl8822cu_fw.bin` |
| 音频 | `snd_hda_intel` | Realtek ALC256，`alsa-ucm-conf` 已装 |
| 摄像头 | `uvcvideo` | USB `13d3:56db`（ov9734 / AzureWave），UVC 1.50 |
| 触摸板 | `elan_i2c` | `ELAN2204:00 04F3:30F5`（I²C）|
| 加速度计 | `lis2dh12`（SMO8840）| IIO `iio:device0`，`iio-sensor-proxy` 提供方向 |
| 背光 | `amdgpu_bl1` | 需要 `acpi_backlight=native`（见下）|
| CPU 微码 | `amd-ucode` | `/boot/amd-ucode.img` |
| 指纹 | 无 | Goodix `27c6:5117`，见「已知限制」|

## 内核命令行

`/etc/default/grub` 中的 `GRUB_CMDLINE_LINUX_DEFAULT`：

```
loglevel=3 rw usb-storage.quirks=346d:5678:u acpi_backlight=native cfg80211.ieee80211_regdom=CN
```

- `acpi_backlight=native`：让 `amdgpu` 直接提供背光接口。去掉它之后
  `/sys/class/backlight` 里可能没有可用设备，`brightnessctl` 也就调不了亮度。
- `cfg80211.ieee80211_regdom=CN`：在启动早期就设定无线法规域，**不依赖**
  `regulatory.db` 的加载时机。
- `usb-storage.quirks=346d:5678:u`：针对一个 USB 存储设备的兼容性绕过。

## 无线法规域（重要）

新装的系统上，`iw reg get` 会显示 `country 00: DFS-UNSET`，也就是最保守的
「世界域」：5 GHz 大量信道不可用、发射功率被压到最低。原因是缺少法规数据库：

```
kernel: faux_driver regulatory: Direct firmware load for regulatory.db failed with error -2
kernel: cfg80211: failed to load regulatory.db
```

处理方式是两层保险：

1. 安装 `wireless-regdb`（core 仓库），提供
   `/usr/lib/firmware/regulatory.db` 与 `regulatory.db.p7s`。
2. 在 GRUB 加 `cfg80211.ieee80211_regdom=CN`，这样即使数据库没能加载，
   法规域也正确。

注意：开机早期那条 `Direct firmware load for regulatory.db failed` 属于**时序
现象**（此时 root 文件系统尚未挂载），随后 `cfg80211` 重新加载时能够正常读到
数据库。判断是否真的生效，看 `iw reg get` 是否显示 `country CN`，而不是看
早期日志。

> 血的教训：不要为了验证这个文件去反复 `modprobe -r cfg80211 / mac80211 /
> rtw88_8822ce`。网卡正靠这些模块工作，卸载会直接断网。要确认状态，用
> `iw reg get`；确实需要重载时，只 `modprobe`（加载），不要 `-r`。

## 已知限制

以下都是硬件或生态限制，**不是配置错误**，不用再花时间排查：

- **指纹识别器不可用**：Goodix `27c6:5117` 在 Linux 下没有可用的开源驱动。
  内核只把它当作普通 USB 设备枚举；`libfprint-tod-git` 及任何 TOD 驱动都不
  包含该 ID，因此 `fprintd-list` 始终返回 `No devices available`。除非将来有
  上游驱动，否则无法使用。
- **`amd_pstate` 不可用**：这颗 Raven2 APU 没有向系统暴露 ACPP CPPC
  （`/sys/devices/system/cpu/cpu0/acpi_cppc` 不存在），所以只能用
  `acpi-cpufreq` + `schedutil`。内核虽然编入了 `CONFIG_X86_AMD_PSTATE`，
  但对本机无用，不必为此改内核参数。
- **无法精简固件包**：`linux-firmware` 主包**硬依赖**全部子包
  （intel / nvidia / broadcom / mediatek / atheros / ti / cirrus 等），
  所以即使本机用不到那约 350 MiB，也无法安全移除。
- 日志里的 `ccp 0000:03:00.2: psp: unable to access the device: you might be
  running a broken BIOS` 与 `amdgpu: psp gfx command LOAD_TA(0x1) failed` 是
  Raven 平台上的常见无害告警，不影响功能。

## 历史坑点

- **`niri-power-effects.service` 开机启动失败**：该单元由 `default.target`
  拉起，而它原先写了 `Requisite=graphical-session.target` —— 这个 target 要等
  `niri.service` 起来才 active，于是启动被直接拒绝，整个会话里守护进程都是死
  的。修复方式是从会话相关单元里删除多余的 `Requisite`，保留 `PartOf` 与
  `After=`。见提交 `f779bdc`。
- **锁屏时屏幕不灭**：`swayidle` 的 `lock` 事件原先只跑 `swaylock`。现在改为
  调用 `lock-screen.sh`：先锁定，再 `niri msg action power-off-monitors`。niri
  在收到输入或解锁时会自动点亮显示器，无需额外处理。见提交 `bc1f19e`。

## 复查方式

```bash
./scripts/verify-drivers.sh     # 硬件与驱动体检（只读）
iw reg get | head -2            # 期望 country CN
nmcli device status | grep wlan # 期望 connected
```
