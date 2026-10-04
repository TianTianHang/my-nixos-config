{inputs, ...}: {
  nix.settings =
    {
      experimental-features = ["nix-command" "flakes"];

      # 国内二进制缓存镜像，加速软件包下载（优先镜像，官方向备）
      substituters = [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
        "https://noctalia.cachix.org"
        "https://denial.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "denial.cachix.org-1:wd8YTnvPmugFrtdMJWtR1XdVknR3/g2nmBJkT+vAruo="
      ];
      trusted-users = ["root" "nixremote" "tiantian"];
    }
    # AAGL（米哈游游戏启动器）的 Cachix 缓存（extra-substituters），
    # 避免启动器及其依赖从源码构建
    // inputs.aagl.nixConfig;

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
