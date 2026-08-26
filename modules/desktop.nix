{lib, pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ghostty
    nautilus

    # 屏幕键盘（2-in-1 / 触屏设备）：作为 Wayland 输入法客户端，
    # 文本输入聚焦且 screen-keyboard-enabled=true 时自动弹出
    squeekboard
    # 提供 org.gnome.desktop.a11y.applications 的 GSettings schema，
    # 供 squeekboard 读取 screen-keyboard-enabled 开关
    gsettings-desktop-schemas
    # 用于 switch-events 切换上述开关
    dconf
  ];

  # niri Wayland 合成器（替代 GNOME）
  # 模块来自上游 niri-flake；包用上游预构建的 unstable（追新，
  # 命中 niri.cachix.org 缓存。stable 25.08 依赖的 libdisplay-info_0_2
  # 已从当前 nixpkgs 移除，故不使用模块默认包）
  programs.niri.enable = true;

  # 关闭 niri-flake 自带的 KDE polkit 代理，改用 noctalia 内置代理，
  # 避免两者同时运行导致重复授权弹窗
  #systemd.user.services.niri-flake-polkit.wantedBy = lib.mkForce [];

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
