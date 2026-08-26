{pkgs, ...}: {
  programs.niri = {
    # 直接书写 KDL，由 niri-flake 在构建时用 `niri validate` 校验。
    # 参考 https://docs.noctalia.dev/noctalia/compositor-settings/niri/
    config = ''
      // 启动 Noctalia 桌面壳
      spawn-at-startup "noctalia"

      // 屏幕键盘：注册为输入法客户端，文本输入聚焦时由 niri 唤起
      spawn-at-startup "squeekboard"

      // 触控板：轻点即点击（tap-to-click）与自然滚动
      input {
        touchpad {
          tap
          natural-scroll
        }
      }

      // 圆角窗口并裁剪内容到圆角边界
      window-rule {
        geometry-corner-radius 20
        clip-to-geometry true
      }

      // 让 Noctalia 设置窗口以浮动层打开，固定尺寸方便操作
      window-rule {
        match app-id="dev.noctalia.Noctalia"
        open-floating true
        default-column-width { fixed 1080; }
        default-window-height { fixed 920; }
      }

      debug {
        // 允许 Noctalia 的通知操作与窗口激活
        honor-xdg-activation-with-invalid-serial
      }

      binds {
        // 核心 Noctalia 绑定
        Mod+D { spawn-sh "noctalia msg panel-toggle launcher"; }
        Mod+S { spawn-sh "noctalia msg panel-toggle control-center"; }
        Mod+Comma { spawn-sh "noctalia msg settings-toggle"; }
        Alt+Tab { spawn-sh "noctalia msg window-switcher"; }

        // 启动终端
        Mod+T { spawn "ghostty"; }

        // 窗口操作
        Mod+Q { close-window; }
        Mod+F { fullscreen-window; }
        Mod+Shift+F { toggle-column-tabbed-display; }
        Mod+C { center-column; }

        // 聚焦窗口（HJKL 与方向键）
        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+J { focus-window-down; }
        Mod+K { focus-window-up; }
        Mod+Left { focus-column-or-monitor-left; }
        Mod+Right { focus-column-or-monitor-right; }
        Mod+Up { focus-window-or-monitor-up; }
        Mod+Down { focus-window-or-monitor-down; }

        // 移动窗口 / 列
        Mod+Shift+H { move-column-left; }
        Mod+Shift+L { move-column-right; }
        Mod+Shift+J { move-window-down; }
        Mod+Shift+K { move-window-up; }
        Mod+Shift+Left { move-column-left-or-to-monitor-left; }
        Mod+Shift+Right { move-column-right-or-to-monitor-right; }
        Mod+Shift+Up { move-window-up-or-to-workspace-up; }
        Mod+Shift+Down { move-window-down-or-to-workspace-down; }

        // 将窗口并入 / 移出列（标签页）
        Mod+BracketLeft { consume-window-into-column; }
        Mod+BracketRight { expel-window-from-column; }

        // 交换相邻窗口
        Mod+Shift+U { swap-window-left; }
        Mod+Shift+I { swap-window-right; }

        // 屏幕键盘手动开关（无键盘时通常自动弹出，这里用于手动切换）
        Mod+O { spawn-sh "V=$(busctl get-property --user sm.puri.OSK0 /sm/puri/OSK0 sm.puri.OSK0 Visible 2>/dev/null); if [ \"$V\" = \"b true\" ]; then busctl call --user sm.puri.OSK0 /sm/puri/OSK0 sm.puri.OSK0 SetVisible b false; else busctl call --user sm.puri.OSK0 /sm/puri/OSK0 sm.puri.OSK0 SetVisible b true; fi"; }

        // 音量 / 亮度
        XF86AudioRaiseVolume { spawn-sh "noctalia msg volume-up"; }
        XF86AudioLowerVolume { spawn-sh "noctalia msg volume-down"; }
        XF86AudioMute { spawn-sh "noctalia msg volume-mute"; }
        XF86MonBrightnessUp { spawn-sh "noctalia msg brightness-up"; }
        XF86MonBrightnessDown { spawn-sh "noctalia msg brightness-down"; }
      }

      // 二合一设备：进入平板模式（物理键盘不可用）时启用屏幕键盘，
      // 退出时关闭。squeekboard 会在文本输入聚焦时自动弹出。
      switch-events {
        tablet-mode-on { spawn "bash" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true"; }
        tablet-mode-off { spawn "bash" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false"; }
      }

      // 将 Noctalia 的模糊壁纸层放入 overview 背景（需 noctalia backdrop 启用）
      layer-rule {
        match namespace="^noctalia-backdrop"
        place-within-backdrop true
      }

      // 模糊效果（需 niri >= 26.04，由 niri-unstable 提供）
      blur {
        passes 2
        offset 3.0
        noise 0.03
        saturation 1.0
      }

      // 应用层模糊，但不穿透到壁纸（xray=false 更真实）
      window-rule {
        background-effect {
          blur true
          xray false
        }
      }

      // Noctalia 各层表面：关闭 xray，使用其后的窗口内容作为模糊源
      layer-rule {
        match namespace="^noctalia-(bar-[\"]+|notification|dock|panel|attached-panel|osd)$"
        background-effect {
          xray false
        }
      }

      // 窗口切换器：启用模糊并关闭 xray
      layer-rule {
        match namespace="noctalia-window-switcher"
        background-effect {
          blur true
          xray false
        }
      }
    '';
  };
}
