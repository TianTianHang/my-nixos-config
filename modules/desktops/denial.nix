{config, lib, ...}: let
  cfg = config.desktop.denial;
in {
  options.desktop.denial.enable = lib.mkEnableOption "the Denial desktop";

  config = lib.mkIf cfg.enable {
    desktop.greeter.session = lib.mkDefault "Denial";
    programs.denial.enable = true;
  };
}
