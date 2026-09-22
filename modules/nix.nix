{
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # 国内二进制缓存镜像，加速软件包下载（优先镜像，官方向备）
  nix.settings.substituters = [
    "https://mirror.sjtu.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
    "https://noctalia.cachix.org"
    "https://denial.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    "denial.cachix.org-1:wd8YTnvPmugFrtdMJWtR1XdVknR3/g2nmBJkT+vAruo="
  ];
  nix.settings.trusted-users = [ "root" "nixremote" "tiantian" ];

  # 远程构建配置
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "192.168.100.202";
      system = "x86_64-linux";
      protocol = "ssh";
      sshUser = "nixremote";
      maxJobs = 10;
      speedFactor = 2;
      supportedFeatures = [ "kvm" "big-parallel" "nixos-test" ];
    }
  ];
}
