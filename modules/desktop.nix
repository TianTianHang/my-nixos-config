{lib, pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ghostty
    nautilus

    # 供 home 配置写 dconf 值（dconf.settings）
    dconf
  ];
  programs.niri.enable = true;
  # noctalia 桌面壳（上游 flake 模块）；声明式设置见 home/tiantian/noctalia.nix。
  # recommendedServices：NetworkManager、蓝牙、UPower 与电源档位服务
  programs.noctalia.enable = true;
  programs.noctalia.recommendedServices.enable = true;

  programs.firefox.enable = true;

  # home-manager xdg.portal 要求，用于链接 portal 与桌面应用定义
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];
}
