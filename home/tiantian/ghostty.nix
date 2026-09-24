{ ... }: {
  programs.ghostty.enable = true;

  programs.ghostty.settings = {
    theme = "TokyoNight Storm";
    background-opacity = 0.92;
    background-blur = true;
  };
}
