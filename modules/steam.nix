{config, lib, pkgs, ...}: let
  cfg = config.desktop.steam;
in {
  options.desktop.steam.enable = lib.mkEnableOption "the Steam gaming platform";

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;

      # 进 Steam 运行环境的额外包。gamescope 用于按需开独占帧率锁的
      # gamescope 会话，mangohud 用于帧率/frametime 叠加层。
      extraPackages = with pkgs; [
        gamescope
        mangohud
      ];

      # protontricks 方便往 Proton 前缀里装 winetricks 依赖
      protontricks.enable = true;
    };
  };
}
