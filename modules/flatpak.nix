# Flatpak 底座：只开启运行时，不在这里装任何具体应用。
#
# 本机（tuf）已装 5 个 flathub 应用（WPS 365 / WeChat / RustDesk /
# Flatseal / 腾讯会议）。不开 services.flatpak 的话，重建后 flatpak 会
# 整体失效 —— 这些应用都不是 Nix 包，随 Nix 配置一起消失。
#
# 应用本体不进这个模块：Zotero 走 Nix 包（在 home/tiantian/packages.nix），
# 其余 flatpak 应用本就在 /var/lib/flatpak 里手动管理，由 flatpak 自己跟踪
# 版本。services.flatpak.packages（声明式安装）在本版 nixpkgs 里不存在，
# 只有 enable / extraPortals / package 三个选项。
{lib, pkgs, ...}: {
  services.flatpak.enable = true;

  # services.flatpak.enable 带一条断言：config.xdg.portal.enable 必须为 true。
  # 注意这与 home/tiantian/portals.nix 里的 xdg.portal 是**两个不同的选项** ——
  # 那个是 home-manager 的，这个是 nixpkgs 的，home 里开并不能满足断言。
  # 目前 tuf 上系统级已经是 true（由 flake 输入的桌面模块带入），但依赖这个
  # 隐式来源不稳（换桌面模块就可能失效），所以显式写出来。
  xdg.portal.enable = true;
}