{config, lib, ...}: let
  cfg = config.desktop.denial;
in {
  options.desktop.denial.enable = lib.mkEnableOption "the Denial desktop";

  config = lib.mkIf cfg.enable {
    desktop.greeter.session = lib.mkDefault "Denial";
    programs.denial.enable = true;

    # Denial 使用 IIO 传感器处理设备方向变化。
    hardware.sensor.iio.enable = true;

    # Denial 默认启动桌面 shell；当前设备使用移动/触屏 shell。
   # environment.etc."denial/session.conf".text = ''
   #   DENIAL_SHELL_PROFILE=mobile-shell
   # '';
  };
}
