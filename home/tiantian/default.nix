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
}
