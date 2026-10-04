{lib, pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ghostty
    nautilus

    # 供 home 配置写 dconf 值（dconf.settings）
    dconf
  ];

  # 默认浏览器。mkDefault 便于主机在 hosts/<host>/default.nix 里覆盖
  # （例如 kuangshi 换成了 zen-browser）
  programs.firefox.enable = lib.mkDefault true;

  services.upower.enable = true;

  # home-manager xdg.portal 要求，用于链接 portal 与桌面应用定义
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];
}
