{ ... }: {
  programs.ghostty.enable = true;

  programs.ghostty.settings = {
    theme = "catppuccin-mocha";
    background-opacity = 0.8;
    background-blur = true;
  };
}
