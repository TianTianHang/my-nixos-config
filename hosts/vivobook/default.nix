{config, lib, pkgs, ...}: {
  imports = [
    ../common.nix
    ./hardware-configuration.nix
    ../../modules/acpi-fix.nix
  ];

  networking.hostName = "vivobook";

  desktop.denial.enable = true;
  desktop.niri.enable = false;

  system.stateVersion = "26.05";
}
