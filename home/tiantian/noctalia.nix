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
    };
  };
}
