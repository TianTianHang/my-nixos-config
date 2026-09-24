{pkgs, ...}: {
  home.packages = with pkgs; [
    droidloom
    tree
  ];
}
