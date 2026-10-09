{pkgs, ...}: {
  home.packages = with pkgs; [
    droidloom
    tree
    # Zotero 走 Nix 包而非 flatpak：与 ~/.zotero、~/Zotero 同一套数据目录，
    # 切换版本不需要迁移。flatpak 底座见 modules/flatpak.nix。
    zotero
  ];
}
