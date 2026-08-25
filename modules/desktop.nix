{
  services.xserver.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.libinput.enable = true;

  services.btrfs.autoScrub.enable = true;
  services.btrfs.autoScrub.interval = "weekly";

  programs.firefox.enable = true;
}
