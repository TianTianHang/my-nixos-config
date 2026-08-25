{config, lib, pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/networking.nix
    ../../modules/desktop.nix
    ../../modules/system.nix
    ../../modules/user.nix
  ];

  networking.hostName = "vivobook";

  system.stateVersion = "26.05";
}
