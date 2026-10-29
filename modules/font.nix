# 系统字体统一接入点：此后本仓库需要的字体（fetch 自建或 nixpkgs 现成包）
# 一律加进本文件的 fonts.packages，不再散落到其他模块。
#
# 字体进 fonts.packages 后有两条生效路径，flatpak 不需要额外配置：
#   - 宿主机：NixOS 写入 /etc/fonts/conf.d/00-nixos-cache.conf 的 <dir>
#   - flatpak 沙箱：fonts.fontDir 汇总的 /run/current-system/sw/share/X11/fonts
#     会被 flatpak 挂成 /run/host/fonts，fontconfig 经 remap-dir 引用
# 所以这里加的字体会自动对 WPS 等 flatpak 应用可见。
#
# 注意别与「字体没装」混淆：flatpak 挂载链路本身是通的（已在 WeChat 沙箱
# 实测 fc-list 能看到宿主机 Noto CJK）。缺字就在这里补装。
{pkgs, ...}: let
  # WPS 公式符号字体：Symbol / Wingdings / Wingdings 2 / Wingdings 3 /
  # Webdings / MT Extra。WPS 因版权不随 Linux 包分发，缺失时弹
  # "formula symbols might not be displayed correctly" 提示。
  # 源是社区整理的 Windows 字体备份（rev/hash 锁定）。
  wpsSymbolFonts = pkgs.stdenvNoCC.mkDerivation {
    pname = "wps-symbol-fonts";
    version = "2026-06-17";
    src = pkgs.fetchFromGitHub {
      owner = "iykrichie";
      repo = "wps-office-19-missing-fonts-on-Linux";
      rev = "9ec55e80bfef51a9d4e4ac79a1b1341f3da64b51";
      hash = "sha256-gT5wu0zJxglHwvtE9VpgLQns/rMtsISx/0w1IMvp4kU=";
    };
    nativeBuildInputs = [pkgs.installFonts];
    # 仓库只有字体文件、没有构建系统：跳过 configure/make，
    # 由 installFonts 挂在 preInstall 上完成安装。
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      # fontDir 的正则（nixos/modules/config/fonts/fontdir.nix）大小写敏感，
      # 只认小写 .ttf；而 fontDir 正是 flatpak 挂进沙箱的 /run/host/fonts。
      # 仓库里 WEBDINGS.TTF 是大写扩展名，不转会漏出 fontDir。
      for f in *.TTF; do
        [ -e "$f" ] || continue
        mv "$f" "''${f%.TTF}.ttf"
      done
      runHook preInstall
      runHook postInstall
    '';
  };

  # SimSun（宋体）：中易专有字体，nixpkgs 未收录，从社区单字体仓库取。
  # fc-scan 确认 family 为 "SimSun,宋体"。
  simsun = pkgs.stdenvNoCC.mkDerivation {
    pname = "simsun";
    version = "2020-02-03";
    src = pkgs.fetchFromGitHub {
      owner = "kongchengji";
      repo = "FontSimsun";
      rev = "64e9c986e6efdc2bc881a8fb3b7602b25f93d52e";
      hash = "sha256-8bm2IXoMQwSm/0EACVsPr7UUu4dvRHsSWQ2voaOtr3M=";
    };
    nativeBuildInputs = [pkgs.installFonts];
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      runHook postInstall
    '';
  };
in {
  fonts.packages = [
    wpsSymbolFonts
    simsun
    # Nerd Font（Meslo 系列）：powerlevel10k 主题图标（git 分支、箭头等）
    # 依赖 Nerd Font 补丁字形，缺失时显示为方块；ghostty 的 font-family
    # 用其中的 "MesloLGS Nerd Font Mono" 等宽子族。
    pkgs.nerd-fonts.meslo-lg
  ];
}
