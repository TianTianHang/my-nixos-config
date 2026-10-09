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

  # 内核沿用共享的 modules/boot.nix（linuxPackages_latest），与其他两台一致。
  # 注意本机当前跑的是 7.1.9-zen1（旧配置写的 linuxPackages_zen），切换后
  # 会换成 latest 系的 7.x，NVIDIA 驱动随之重编译匹配。

  # 沿用本机原有设置
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  networking.interfaces.enp46s0.wakeOnLan.enable = true;
  networking.firewall.allowedUDPPorts = [
    9 # Wake-on-LAN magic packet
  ];

  # 只引了 desktops/niri.nix，desktop.denial 这个选项在本机根本不存在，
  # 无需（也不能）再显式置 false。
  desktop.niri.enable = true;

  # 本机尚未加入组网，easytier / mihomo 都不引（见上方 imports 的说明）。

  # 浏览器用 Zen（覆盖 modules/desktop.nix 里的 firefox 默认值）
  programs.firefox.enable = false;
  environment.systemPackages = [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # 局域网代理：github.com 直连超时，nix-daemon 需要走代理
  # 才能拉 flake 输入、下载 FOD 源码包（zen 的 tarball）
  systemd.services.nix-daemon.environment = {
    http_proxy = "http://192.168.100.254:7890";
    https_proxy = "http://192.168.100.254:7890";
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