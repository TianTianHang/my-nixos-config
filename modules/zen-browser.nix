{config, lib, inputs, pkgs, ...}: let
  cfg = config.programs.zen-browser;
  system = pkgs.stdenv.hostPlatform.system;

  upstreamUnwrapped = inputs.zen-browser.packages.${system}.zen-browser-unwrapped;

  # 上游 youwen5/zen-browser-flake 的 sources.json 在 1.23.3b 上给出的
  # x86_64 hash 与 GitHub release 实际资产不符，直接构建会报 hash mismatch。
  # 这里用实际下载并 `xz -t` 校验过的 tarball 覆盖 src；等上游修正后可删。
  # 仓库三台机器都是 x86_64-linux，其它架构仍沿用上游定义。
  zen-unwrapped =
    if system == "x86_64-linux"
    then
      upstreamUnwrapped.overrideAttrs (old: {
        src = pkgs.fetchurl {
          inherit (old.src) url;
          hash = "sha256-uyBF0+IWVNQP6EElAJLurf0sH8gx7vtQkiJ3PIvcoUk=";
        };
      })
    else upstreamUnwrapped;

  # 与上游 zen-browser.nix 保持一致：Zen 的版本号独立于底层 Firefox，
  # 但 wrapFirefox 需要 firefoxVersion 来选择 FFmpeg ABI。
  zenPackage = pkgs.wrapFirefox (zen-unwrapped // {version = zen-unwrapped.firefoxVersion;}) {
    pname = "zen-browser";
    version = zen-unwrapped.version;
  };
in {
  options.programs.zen-browser = {
    enable = lib.mkEnableOption "the Zen browser";

    package = lib.mkOption {
      type = lib.types.package;
      default = zenPackage;
      defaultText = "zen-browser（已覆盖上游 1.23.3b 的错误 hash）";
      description = ''
        Zen 浏览器包，来自 flake 输入 zen-browser。

        nixpkgs 尚未收录 Zen（曾因安全问题被移除），因此只能走这个
        flake。它提供的是预编译二进制的包装，构建很快；版本随
        flake.lock 固定。
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
