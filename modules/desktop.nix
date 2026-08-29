{lib, pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ghostty
    nautilus

    # 屏幕键盘（2-in-1 / 触屏设备）：wvkbd 走 wl_virtual_keyboard 协议，
    # 不抢占 input-method 角色，可与 fcitx5 共存
    wvkbd
    # 供 home 配置写 dconf 值（dconf.settings）
    dconf
  ];

  # niri Wayland 合成器（替代 GNOME）
  # 已删除 niri-flake：niri 包与 ~/.config/niri/config.kdl 统一由
  # home-manager（home/tiantian/niri.nix）管理，这里不再启用 NixOS 模块。

  # noctalia 桌面壳（上游 flake 模块）；声明式设置见 home/tiantian/noctalia.nix。
  # recommendedServices：NetworkManager、蓝牙、UPower 与电源档位服务
  programs.noctalia.enable = true;
  programs.noctalia.recommendedServices.enable = true;

  programs.firefox.enable = true;

  # home-manager xdg.portal 要求，用于链接 portal 与桌面应用定义
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];
}
