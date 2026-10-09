{config, lib, pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/acpi-fix.nix

    # 本机需要的共享模块。不引 desktops/niri（这台用 Denial）与
    # waydroid（没有主机启用它）。
    ../../modules/boot.nix
    ../../modules/btrfs.nix
    ../../modules/desktop.nix
    ../../modules/desktops/denial.nix
    ../../modules/easytier.nix
    ../../modules/greeter.nix
    ../../modules/input-method.nix
    ../../modules/localization.nix
    ../../modules/mihomo.nix
    ../../modules/networking.nix
    ../../modules/nix.nix
    ../../modules/packages.nix
    ../../modules/user.nix
  ];

  networking.hostName = "vivobook";

  # EasyTier 跑在独立 netns 里，通过这对 veth 与宿主相连。
  # linkPrefix 与 kuangshi 错开：段本身就是组网设备访问该宿主的地址，
  # 共用同一段会撞车。
  services.easytier.netns = {
    enable = true;
    linkPrefix = "192.168.11";
    hostLastOctet = 253;
    routes = [
      # 远端内网：mihomo 的上游代理 192.168.100.254 在此段。
      # 与 kuangshi 同组网，代理位置相同，两台机器走同一条路径。
      "192.168.100.0/24"
      "192.168.9.0/24"
      # 本机 easytier 自身的虚拟网段（取自
      # /var/lib/easytier/easytier.toml 的 ipv4=）。kuangshi 是
      # 10.126.126.0/24，vivobook 的地址需在本机确认后替换。
      "10.126.126.0/24"
    ];
  };

  # mihomo 透明代理：上游同样是经组网可达的 192.168.100.254:7890，
  # 出站靠 routing-mark + modules/easytier.nix 里的 ip rule 走 veth。
  networking.mihomo.enable = true;

  # 只引了 desktops/denial.nix，desktop.niri 这个选项在本机根本不存在，
  # 无需（也不能）再显式置 false。
  desktop.denial.enable = true;

  system.stateVersion = "26.05";
}
