{ ... }: {
  programs.ghostty.enable = true;

  programs.ghostty.settings = {
    # Nerd Font 等宽子族：powerlevel10k 图标渲染依赖（见 modules/font.nix）
    font-family = "MesloLGS Nerd Font Mono";
    theme = "TokyoNight Storm";
    background-opacity = 0.92;
    background-blur = true;
  };
}
