{
  home.username = "tiantian";
  home.homeDirectory = "/home/tiantian";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  imports = [
    ./packages.nix
    ./git.nix
    ./bash.nix
    ./niri.nix
    ./noctalia.nix
    ./portals.nix
  ];

  # 默认认为物理键盘可用，不自动弹出屏幕键盘；
  # 进入平板模式（tablet-mode-on）时由 niri 切换为 true
  dconf.settings = {
    "org/gnome/desktop/a11y/applications" = {
      screen-keyboard-enabled = false;
    };
  };
}
