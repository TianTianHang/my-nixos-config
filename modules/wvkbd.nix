{pkgs, ...}: {
  # wvkbd 包装命令：把启动参数与信号显隐收进一个脚本，niri 配置只需调用
  # `wvkbdctl {start,show,hide,toggle}`。
  #
  # wvkbd 信号语义：SIGUSR1=隐藏，SIGUSR2=显示，SIGRTMIN=切换显隐。
  # 注意：不要给 wvkbd 加 `--auto`，那会走 zwp_input_method_v2 协议，
  # 与 fcitx5 抢 input-method 角色导致 Rime 无法切换。wvkbd 默认只走
  # wl_virtual_keyboard 协议，常驻运行也不影响 fcitx5。
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "wvkbdctl" ''
      #! wvkbd 控制脚本：封装启动参数与信号显隐，避免在 niri 配置里重复书写长参数
      WVKBD=${pkgs.wvkbd}/bin/wvkbd-mobintl
      # Catppuccin Mocha 暗色配色 + 半透明
      ARGS="--bg 1e1e2e --fg 313244 --text cdd6f4 --press 89b4fa --fg-sp 585b70 --press-sp 74c7ec --alpha 235"
      HIDDEN="$ARGS --hidden"

      case "$1" in
        start)
          # 已运行则忽略，否则以隐藏模式常驻启动
          pgrep -x wvkbd-mobintl >/dev/null || exec "$WVKBD" $HIDDEN
          ;;
        show)
          pkill -SIGUSR2 -x wvkbd-mobintl
          ;;
        hide)
          pkill -SIGUSR1 -x wvkbd-mobintl
          ;;
        toggle)
          if pgrep -x wvkbd-mobintl >/dev/null; then
            pkill -SIGRTMIN -x wvkbd-mobintl
          else
            exec "$WVKBD" $ARGS
          fi
          ;;
        *)
          echo "usage: wvkbdctl {start|show|hide|toggle}" >&2
          exit 1
          ;;
      esac
    '')
  ];
}
