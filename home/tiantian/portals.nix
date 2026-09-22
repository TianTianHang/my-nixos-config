{pkgs, ...}: {
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];

    # xdg-desktop-portal 1.17+ 要求显式指定后端。
    # "*" 表示沿用旧行为：按字典序取第一个可用实现；
    # 当前桌面若提供专用后端（例如 Denial 的系统模块），其桌面专属路由
    # 由对应系统模块在 xdg.portal.config.<desktop> 中声明。
    config.common.default = "*";
  };
}
