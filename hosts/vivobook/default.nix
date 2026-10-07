{config, lib, pkgs, ...}: {
  imports = [
    ../common.nix
    ./hardware-configuration.nix
    ../../modules/acpi-fix.nix
  ];

  networking.hostName = "vivobook";

  # EasyTier 跑在独立 netns 里，通过这对 veth 与宿主相连。
  # linkPrefix 与 kuangshi 错开：段本身就是组网设备访问该宿主的地址，
  # 共用同一段会撞车。
  services.easytier.netns = {
    enable = true;
    linkPrefix = "192.168.11";
    hostLastOctet = 253;
    # routes 必须按本机实际情况填写：easytier 自身的虚拟网段
    # （取自 /var/lib/easytier/easytier.toml 的 ipv4=），以及需要经组网
    # 访问的远端内网段。查当前值：
    #   sudo ip netns exec easytier ip route show dev easytier0
    routes = [ ];
  };

  desktop.denial.enable = true;
  desktop.niri.enable = false;

  system.stateVersion = "26.05";
}
