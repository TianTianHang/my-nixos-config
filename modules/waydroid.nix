{ config, lib, pkgs, ... }:
let
  cfg = config.virtualisation.waydroid;
in {
  # Waydroid：在 Wayland 桌面（niri）中以容器方式运行安卓应用
  #
  # 启用后需手动初始化安卓镜像（仅需一次，约 1GB）：
  #   sudo waydroid init
  # 然后启动容器与图形界面（需在已登录的图形会话中执行）：
  #   sudo systemctl restart waydroid-container
  #   waydroid show-full-ui        # 全屏启动安卓界面
  # 也可用 waydroid app install xxx.apk 安装应用，或直接 waydroid shell
  virtualisation.waydroid.enable = false;

  # 部分内核将 binder 编译为模块，显式加载以确保 binderfs 可用；
  # 若已内建（=y）则 modprobe 为无操作，无副作用
  boot.kernelModules = lib.mkIf cfg.enable [ "binder_linux" ];

  # 内核 6.17+ 已移除 legacy ip_tables 模块，waydroid 默认走的 iptables-legacy
  # 会因此失败（waydroid-net.sh start 报错）。改用 nftables 后端：
  #   - 启用系统级 nftables（确保内核 nft 模块/nat 表可用）
  #   - 并把 waydroid 设为 waydroid-nftables 变体（其内部用 nft 做 NAT）
  networking.nftables.enable = lib.mkIf cfg.enable true;
  virtualisation.waydroid.package = lib.mkIf cfg.enable pkgs.waydroid-nftables;
}
