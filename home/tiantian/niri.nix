{pkgs, ...}: {
  # niri 窗口管理器配置（替代 GNOME）
  # 依据 https://docs.noctalia.dev/noctalia/compositor-settings/niri/

  # 禁用 niri-flake 按 programs.niri.settings 生成的 config.kdl，
  # 避免与下方手写配置文件冲突
  programs.niri.config = null;

  xdg.configFile."niri/config.kdl".text = ''
    spawn-at-startup "noctalia"
    spawn-at-startup "${pkgs.fcitx5}/bin/fcitx5"

    input {
      keyboard {
        xkb {
          layout "us"
        }
      }
    }

    // 圆角窗口外观
    window-rule {
      geometry-corner-radius 20
      clip-to-geometry true
    }

    // Noctalia 设置窗口浮动显示
    window-rule {
      match app-id="dev.noctalia.Noctalia"
      open-floating true
      default-column-width { fixed 1080; }
      default-window-height { fixed 920; }
    }

    debug {
      // 允许通知动作与来自 Noctalia 的窗口激活
      honor-xdg-activation-with-invalid-serial
    }

    binds {
      Mod+T { spawn "ghostty"; }
      Mod+Return { spawn "ghostty"; }

      // Noctalia 核心快捷键
      Mod+Space { spawn-sh "noctalia msg panel-toggle launcher"; }
      Mod+S { spawn-sh "noctalia msg panel-toggle control-center"; }
      Mod+Comma { spawn-sh "noctalia msg settings-toggle"; }
      Alt+Tab { spawn-sh "noctalia msg window-switcher"; }

      // 音量与亮度
      XF86AudioRaiseVolume { spawn-sh "noctalia msg volume-up"; }
      XF86AudioLowerVolume { spawn-sh "noctalia msg volume-down"; }
      XF86AudioMute { spawn-sh "noctalia msg volume-mute"; }
      XF86MonBrightnessUp { spawn-sh "noctalia msg brightness-up"; }
      XF86MonBrightnessDown { spawn-sh "noctalia msg brightness-down"; }
    }

    // 壁纸方案：模糊的 overview 背景层（需在 noctalia 中启用 [backdrop]）
    layer-rule {
      match namespace="^noctalia-backdrop"
      place-within-backdrop true
    }

    // 普通应用窗口模糊（niri >= 26.04）
    window-rule {
      background-effect {
        blur true
        xray false
      }
    }

    // Noctalia 自身表面禁用 xray，观感更真实；
    // 其模糊区域通过 ext-background-effects 自动发布
    layer-rule {
      match namespace="^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$"
      background-effect {
        xray false
      }
    }

    // 窗口切换器开启模糊并禁用 xray
    layer-rule {
      match namespace="noctalia-window-switcher"
      background-effect {
        blur true
        xray false
      }
    }

    // 全局模糊微调
    blur {
      passes 2
      offset 3.0
      noise 0.03
      saturation 1.0
    }
  '';
}
