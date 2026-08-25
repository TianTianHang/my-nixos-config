{ pkgs, ... }: {
  services.xserver.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # 只保留 GDM + gnome-shell 核心，剔除捆绑的游戏与可选应用
  environment.gnome.excludePackages = with pkgs; [
    # 游戏
    gnome.gnome-chess
    gnome.iagno
    gnome.five-or-more
    gnome.four-in-a-row
    gnome.gnome-klotski
    gnome.gnome-mahjongg
    gnome.gnome-mines
    gnome.gnome-nibbles
    gnome.gnome-robots
    gnome.gnome-sudoku
    gnome.gnome-taquin
    gnome.gnome-tetravex
    gnome.swell-foop
    gnome.aisleriot
    # 可选/冗余应用
    gnome.cheese
    gnome.gnome-maps
    gnome-photos
    gnome-tour
    gnome.gnome-weather
    gnome.gnome-music
    gnome.gnome-contacts
    gnome.gnome-clocks
    gnome.gnome-todo
    gnome.gnome-logs
    gnome.epiphany
    rhythmbox
    gnome.totem
    gnome.simple-scan
    gnome.baobab
    evolution
    gnome-user-docs
    gnome.yelp
    gnome-text-editor
    gnome-connections
    gnome.gnome-boxes
  ];

  environment.systemPackages = with pkgs; [
    ghostty
  ];

  services.libinput.enable = true;

  services.btrfs.autoScrub.enable = true;
  services.btrfs.autoScrub.interval = "weekly";

  programs.firefox.enable = true;

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-rime
        qt6Packages.fcitx5-chinese-addons
      ];
    };
  };
}
