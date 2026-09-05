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
      settings.addons.virtualkeyboard.globalSection.OnDemand = "False";
      settings.globalOptions.Behavior.EnabledAddons = "virtualkeyboard";
    };
  };

  environment.variables.RIME_DATA_DIR = "${pkgs.rime-data}/share/rime-data";
}
