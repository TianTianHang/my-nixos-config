{pkgs, ...}: {
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];

    # xdg-desktop-portal 1.17+ 要求显式指定后端，
    # "*" 表示沿用旧行为：按字典序取第一个可用实现。
    # niri 会话的精确配置由系统级（niri-flake 模块）提供
    config.common.default = "*";
  };
}
