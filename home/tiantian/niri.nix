{pkgs, ...}: {
  programs.niri = {
    enable = true;

    # 直接书写 KDL，由 niri-flake 在构建时用 `niri validate` 校验。
    # 参考 https://docs.noctalia.dev/noctalia/compositor-settings/niri/
    config = ''
      // 启动 Noctalia 桌面壳
      spawn-at-startup "noctalia"

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
        Mod+Space { spawn-sh "noctalia msg panel-toggle launcher"; }
        Mod+S { spawn-sh "noctalia msg panel-toggle control-center"; }
        Mod+Comma { spawn-sh "noctalia msg settings-toggle"; }
        Alt+Tab { spawn-sh "noctalia msg window-switcher"; }

        // 音量 / 亮度
        XF86AudioRaiseVolume { spawn-sh "noctalia msg volume-up"; }
        XF86AudioLowerVolume { spawn-sh "noctalia msg volume-down"; }
        XF86AudioMute { spawn-sh "noctalia msg volume-mute"; }
        XF86MonBrightnessUp { spawn-sh "noctalia msg brightness-up"; }
        XF86MonBrightnessDown { spawn-sh "noctalia msg brightness-down"; }
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
