{config, lib, pkgs, ...}: let
  cfg = config.desktop.niri;
in {
  options.desktop.niri.enable = lib.mkEnableOption "the Niri desktop configuration";

  config = lib.mkIf cfg.enable {
    desktop.greeter.session = lib.mkDefault "Niri";
    programs.niri.enable = true;

    environment.systemPackages = [ pkgs.xwayland-satellite ];

    # Niri and Noctalia are user-session configuration, so keep them together
    # with the system-side compositor option.
    home-manager.users.tiantian.imports = [
      ../../home/tiantian/niri.nix
      ../../home/tiantian/noctalia.nix
    ];

    programs.noctalia.enable = true;
    programs.noctalia.recommendedServices.enable = true;
  };
}
