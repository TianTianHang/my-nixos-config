{config, pkgs, ...}: {
  home.username = "tiantian";
  home.homeDirectory = "/home/tiantian";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    tree
    git
  ];

  programs.git = {
    enable = true;
    settings.user = {
      name = "TianTianHang";
      email = "a2450804878@hotmial.com";
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };
}
