{ pkgs, ... }: {
  services.xserver.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # 只保留 GDM + gnome-shell 核心，剔除捆绑的游戏与可选应用
  environment.gnome.excludePackages = with pkgs; [
    # 游戏
    gnome-chess
    iagno
    five-or-more
    four-in-a-row
    gnome-klotski
    gnome-mahjongg
    gnome-mines
    gnome-nibbles
    gnome-robots
    gnome-sudoku
    gnome-taquin
    gnome-tetravex
    swell-foop
    aisleriot
    # 可选/冗余应用
    cheese
    gnome-maps
    gnome-photos
    gnome-tour
    gnome-weather
    gnome-music
    gnome-contacts
    gnome-clocks
    endeavour
    gnome-logs
    epiphany
    rhythmbox
    totem
    simple-scan
    baobab
    evolution
    gnome-user-docs
    yelp
    gnome-text-editor
    gnome-connections
    gnome-boxes
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
