{pkgs, ...}: {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-rime
        librime
        rime-data
        qt6Packages.fcitx5-chinese-addons
      ];
    };
  };

  environment.variables.RIME_DATA_DIR = "${pkgs.rime-data}/share/rime-data";
}
