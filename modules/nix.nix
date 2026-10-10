{
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # 国内二进制缓存镜像，加速软件包下载（优先镜像，官方向备）
  nix.settings.substituters = [
    "https://mirror.sjtu.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
    "https://noctalia.cachix.org"
    "https://denial.cachix.org"
    # AAGL（米哈游游戏启动器）的 Cachix 缓存，避免其依赖从源码构建
    "https://ezkea.cachix.org"
    # CachyOS 内核。flake 的 nixConfig 会自动注入官方 attic
    # （attic.xuyh0120.win/lantian），但实测 release 分支的内核并未收录
    # 在其中（探测 44 个变体全 404），因此这里改用 bahrom04 的镜像缓存
    # cache.xinux.uz —— 实测同一批 44 个变体命中 35 个，含本仓库用到的
    # latest-x86_64-v3 与 lts。官方 attic 一并保留，等它追上后是免费冗余。
    "https://attic.xuyh0120.win/lantian"
    "https://cache.xinux.uz"
    # DeepSeek Harness（dsh）打包。其 flake 的 nixConfig 只在直接
    # nix build/run 那个 flake 时生效；我们只在 pkgsWithOverlay 里用它的
    # overlays.default，所以必须在这里显式声明才能命中它的 Cachix。
    "https://deepseek-harness-nix.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    "denial.cachix.org-1:wd8YTnvPmugFrtdMJWtR1XdVknR3/g2nmBJkT+vAruo="
    "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
    # CachyOS 内核缓存（官方 attic + bahrom04 镜像）
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    "cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0="
    "deepseek-harness-nix.cachix.org-1:5NrkwLN9veNMhiINtU5ZeV4isXFhFsOwn6Ms7J1M+TA="
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
