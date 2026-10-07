{inputs, pkgs, ...}: {
  imports = [
    ../common.nix
    ./hardware-configuration.nix
    # AAGL 游戏启动器模块（Cachix 缓存配置在 modules/nix.nix）
    inputs.aagl.nixosModules.default
  ];

  networking.hostName = "kuangshi";

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

  desktop.denial.enable = false;
  desktop.niri.enable = true;

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

  # 局域网代理：github.com 直连超时，nix-daemon 需要走代理
  # 才能拉取 flake 输入、下载 FOD 源码包（zen 的 tarball）
  systemd.services.nix-daemon.environment = {
    http_proxy = "http://192.168.100.254:7890";
    https_proxy = "http://192.168.100.254:7890";
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

  users.users.tiantian.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILF47iRw0YgSWTbmYgnLMLyDeKXb0POLi80SINgeGl52 nix-builder-key"
  ];
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "26.05";
}
