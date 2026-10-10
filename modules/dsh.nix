{config, lib, pkgs, ...}: let
  cfg = config.programs.dsh;
in {
  options.programs.dsh = {
    enable = lib.mkEnableOption "the official DeepSeek Harness desktop application";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.dsh.dsh-desktop-official;
      defaultText = lib.literalExpression "pkgs.dsh.dsh-desktop-official";
      description = ''
        DeepSeek Harness 桌面应用包，来自 flake 输入 dsh 的 overlay。

        注意 pkgs.dsh.dsh-desktop 是非官方打包（dsh-desktop-unofficial 的
        别名），要上游发布版构建的官方桌面应用必须用 dsh-desktop-official。
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # 应用自带 .desktop 文件与图标（Electron），装进 systemPackages 后
    # Noctalia / Denial 的应用菜单里就能看到，不需要额外配 xdg 配置。
    environment.systemPackages = [ cfg.package ];
  };
}
