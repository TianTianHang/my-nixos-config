{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ghostty
    nautilus

    # 供 home 配置写 dconf 值（dconf.settings）
    dconf
  ];

  programs.firefox.enable = true;

  services.upower.enable = true;

  # home-manager xdg.portal 要求，用于链接 portal 与桌面应用定义
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];
}
