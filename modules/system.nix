{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    vim
    wget
  ];
  nix.settings.experimental-features = ["nix-command" "flakes" ];

  # 国内二进制缓存镜像，加速软件包下载（优先镜像，官方向备）
  nix.settings.substituters = [
    "https://mirror.sjtu.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];
}
