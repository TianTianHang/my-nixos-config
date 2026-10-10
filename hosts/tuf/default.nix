# ASUS TUF Gaming F15 FX506HC（板号 FX506HC，BIOS FX506HC.313）
# 混合显卡：Intel Iris Xe 驱动内屏（eDP-1），RTX 3050 Laptop 外接输出（DP-2/3）。
# 命名沿用 vivobook 的先例 —— 按厂商产品线取名，不用通用厂商名。
#
# 注意不引 ../../modules/acpi-fix.nix：那份 SSDT 修的是 Vivobook 固件独有的
# CTDP / SxCT 符号缺失。本机同样带 Intel DPTF 表，但日志里没有对应的
# AE_NOT_FOUND 报错（只有另一类 H_EC.SEN2/SEN4/CHRG 缺失，该模块不覆盖），
# 引了只会白压一个 ACPI override。
{inputs, pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix

    # 本机需要的共享模块。本机不加入组网，故不引 easytier.nix / mihomo.nix
    # （两者都各自定义 enable 选项，不引就没有选项、也没有服务）；
    # 根分区是 ext4，故不引 btrfs.nix（它无条件开 autoScrub，而 NixOS 断言
    # 要求至少有一个 btrfs 文件系统）。不引 waydroid（没有主机启用它）。
    ../../modules/boot.nix
    ../../modules/desktop.nix
    ../../modules/dsh.nix
    ../../modules/desktops/niri.nix
    ../../modules/flatpak.nix
    ../../modules/greeter.nix
    ../../modules/input-method.nix
    ../../modules/localization.nix
    ../../modules/networking.nix
    ../../modules/nix.nix
    ../../modules/packages.nix
    ../../modules/user.nix
  ];

  networking.hostName = "tuf";

  # CachyOS 内核。CPU 是 i5-11400H（Rocket Lake），实测支持 AVX2/BMI2，
  # 用 x86_64-v3 基线。覆盖 modules/boot.nix 里的 mkDefault。
  #
  # 注意本机从 7.1.9-zen1 换到 CachyOS 7.2.x，NVIDIA 驱动会重编译匹配；
  # systemd-boot 默认保留上一代条目，新内核起不来时可在启动菜单选旧的。
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;

  # 沿用本机原有设置
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  networking.interfaces.enp46s0.wakeOnLan.enable = true;
  networking.firewall.allowedUDPPorts = [
    9 # Wake-on-LAN magic packet
  ];

  # 只引了 desktops/niri.nix，desktop.denial 这个选项在本机根本不存在，
  # 无需（也不能）再显式置 false。
  desktop.niri.enable = true;

  # DeepSeek Harness 官方 Electron 桌面版
  programs.dsh.enable = true;

  # 本机尚未加入组网，easytier / mihomo 都不引（见上方 imports 的说明）。

  # 浏览器用 Zen（覆盖 modules/desktop.nix 里的 firefox 默认值）
  programs.firefox.enable = false;
  environment.systemPackages = [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # nix-daemon 的代理指向**本机 mihomo**（127.0.0.1:7890），不是上游
  # 192.168.100.254:7890。理由见 hosts/kuangshi/default.nix 的同名配置：
  # 显式代理会绕过 TUN 与规则引擎，mihomo 的 CACHIX / OPENCODE 选择组
  # 就对 nix 完全无效。
  systemd.services.nix-daemon.environment = {
    http_proxy = "http://127.0.0.1:7890";
    https_proxy = "http://127.0.0.1:7890";
  };

  # Intel 驱动内屏，NVIDIA 走 PRIME offload 按需出图。
  # bus ID 取自本机 /sys/class/drm/card*/device 的 PCI_SLOT_NAME：
  # NVIDIA 0000:01:00.0，Intel 0000:00:02.0。
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      # bus ID 直接挂在 prime 下，不是 prime.offload 下
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  system.stateVersion = "26.05";
}