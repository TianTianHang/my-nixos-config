{
  # noctalia 桌面壳声明式配置（由 flake 注入的 homeModules.default 提供）
  # 完整选项见 https://docs.noctalia.dev/noctalia/configuration/
  programs.noctalia = {
    enable = true;

    settings = {
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Noctalia";
      };

      # 壁纸服务；具体壁纸可在 设置 → 壁纸 中选取，会写入 settings.toml
      wallpaper.enabled = true;

      # niri overview 背后的模糊壁纸层，
      # 需配合 niri 配置中的 layer-rule place-within-backdrop
      backdrop = {
        enabled = true;
        blur_intensity = 0.5;
        tint_intensity = 0.3;
      };

      # 从启动器打开的应用走 systemd-run 独立 scope，与 noctalia 隔离。
      # 否则 Zen 等浏览器的内容进程会与 noctalia 共享 app-niri-noctalia-*.scope，
      # 内存涨到 ~13GB 触发 OOM 时 systemd OOMPolicy=stop 会连坐杀掉 noctalia。
      shell.launcher.launch_apps_as_systemd_services = true;
    };
  };
}
