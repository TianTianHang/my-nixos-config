{inputs, pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    # AAGL 游戏启动器模块（Cachix 缓存配置在 modules/nix.nix）
    inputs.aagl.nixosModules.default

    # 本机需要的共享模块。不引 desktops/denial（这台用 Niri）与
    # waydroid（没有主机启用它）。
    ../../modules/boot.nix
    ../../modules/btrfs.nix
    ../../modules/desktop.nix
    ../../modules/dsh.nix
    ../../modules/desktops/niri.nix
    ../../modules/easytier.nix
    ../../modules/flatpak.nix
    ../../modules/greeter.nix
    ../../modules/input-method.nix
    ../../modules/localization.nix
    ../../modules/mihomo.nix
    ../../modules/networking.nix
    ../../modules/nix.nix
    ../../modules/packages.nix
    ../../modules/steam.nix
    ../../modules/user.nix
  ];

  networking.hostName = "kuangshi";

  # CachyOS 内核。桌面机长期开着，CPU 支持 AVX2/BMI2，用 x86_64-v3 基线。
  # 覆盖 modules/boot.nix 里的 mkDefault（v1 基线）。
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;

  # EasyTier 跑在独立 netns 里，通过这对 veth 与宿主相连。
  # linkPrefix 是本机 proxy_network 声明导出的段，组网设备靠它访问宿主：
  # ssh 192.168.10.253 即到本机。绝不能取远端内网段（会占用远端设备地址）。
  services.easytier.netns = {
    enable = true;
    linkPrefix = "192.168.10";
    hostLastOctet = 253;
    routes = [
      # easytier 自身的虚拟网段
      "10.126.126.0/24"
      # 远端内网：上游代理 192.168.100.254 在此段。
      # mihomo 经静态路由 + routing-mark 经 veth 过去（不开 auto-detect）。
      "192.168.100.0/24"
      "192.168.9.0/24"
    ];
  };

  # 只引了 desktops/niri.nix，desktop.denial 这个选项在本机根本不存在，
  # 无需（也不能）再显式置 false。
  desktop.niri.enable = true;

  # DeepSeek Harness 官方 Electron 桌面版
  programs.dsh.enable = true;

  # Steam
  desktop.steam.enable = true;

  # AAGL 游戏启动器（按需开关，不需要的删掉对应行即可）
  programs.anime-game-launcher.enable = true; # 原神
  programs.anime-games-launcher.enable = true; # 米哈游游戏合集
  programs.honkers-railway-launcher.enable = true; # 崩坏：星穹铁道
  programs.sleepy-launcher.enable = true; # 绝区零

  # 浏览器用 Zen（覆盖 common 里共享的 firefox 默认值）
  programs.firefox.enable = false;
  environment.systemPackages = [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # nix-daemon 的代理指向**本机 mihomo**（127.0.0.1:7890），不是上游
  # 192.168.100.254:7890。github.com 直连超时，nix 需要代理才能拉 flake
  # 输入、下载 FOD 源码包（zen 的 tarball）与二进制缓存。
  #
  # 为什么绕一层本机 mihomo：显式代理变量会让 libcurl 直接连上游，**绕过
  # TUN 与整套规则引擎**，mihomo 日志里完全看不到 nix 的连接。指到
  # 127.0.0.1:7890 后 nix 流量才进规则引擎，config/mihomo/config.yaml 里的
  # DOMAIN-SUFFIX,cachix.org,CACHIX / opencode.ai,OPENCODE 两个 select 组
  # 对 nix 才生效（可在 Web UI 现场切换走代理还是直连）。
  # 代价是多一跳：本机 mihomo 再拨上游 192.168.100.254:7890。
  systemd.services.nix-daemon.environment = {
    http_proxy = "http://127.0.0.1:7890";
    https_proxy = "http://127.0.0.1:7890";
  };

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:2:0:0";
    };
  };

  # mihomo 透明代理：上游是经组网可达的 192.168.100.254:7890，
  # 出站靠 routing-mark + modules/easytier.nix 里的 ip rule 走 veth 进组网。
  networking.mihomo.enable = true;

  users.users.tiantian.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILF47iRw0YgSWTbmYgnLMLyDeKXb0POLi80SINgeGl52 nix-builder-key"
  ];
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "26.05";
}
