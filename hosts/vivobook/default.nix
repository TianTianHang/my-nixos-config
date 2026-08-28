{config, lib, pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/btrfs.nix
    ../../modules/desktop.nix
    ../../modules/greeter.nix
    ../../modules/input-method.nix
    ../../modules/localization.nix
    ../../modules/networking.nix
    ../../modules/nix.nix
    ../../modules/packages.nix
    ../../modules/user.nix
    ../../modules/wvkbd.nix
  ];

  networking.hostName = "vivobook";

  system.stateVersion = "26.05";
}
