{config, lib, pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/acpi-fix.nix
    ../../modules/btrfs.nix
    ../../modules/desktop.nix
    ../../modules/desktops/denial.nix
    ../../modules/desktops/niri.nix
    ../../modules/easytier.nix
    ../../modules/greeter.nix
    ../../modules/input-method.nix
    ../../modules/localization.nix
    ../../modules/networking.nix
    ../../modules/nix.nix
    ../../modules/packages.nix
    ../../modules/user.nix
    ../../modules/waydroid.nix
  ];

  networking.hostName = "vivobook";

  desktop.denial.enable = true;
  desktop.niri.enable = false;

  system.stateVersion = "26.05";
}
