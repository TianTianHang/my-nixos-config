{
  description = "Shared NixOS configuration for personal x86 devices";

  inputs = {
    # 使用南京大学 Git 镜像加速 nixpkgs 源码下载
    nixpkgs.url = "git+https://mirror.nju.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # noctalia 桌面壳（v5）。固定到 cachix 分支以命中官方二进制缓存；
    # 注意不能写 inputs.nixpkgs.follows，否则哈希变化会导致缓存全部失效
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    # noctalia-greeter：greetd 登录界面（追新，本地构建）
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    denial.url = "github:denialwm/denial";

  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    noctalia,
    noctalia-greeter,
    denial
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    # 自定义包覆盖
    overlay = final: prev: {
      kylin-virtual-keyboard = final.callPackage ./pkgs/kylin-virtual-keyboard/package.nix {};
      droidloom = final.callPackage ./pkgs/droidloom/package.nix {};
    };
    pkgsWithOverlay = import nixpkgs {
      inherit system;
      overlays = [overlay];
      config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
        "nvidia-settings"
        "nvidia-x11"
      ];
    };
  in {
    packages.x86_64-linux.kylin-virtual-keyboard = pkgsWithOverlay.kylin-virtual-keyboard;
    packages.x86_64-linux.droidloom = pkgsWithOverlay.droidloom;

    nixosConfigurations = let
      mkX86Host = host: nixpkgs.lib.nixosSystem {
        inherit system;
        pkgs = pkgsWithOverlay;
        modules = [
          host
          home-manager.nixosModules.home-manager
          ({config, ...}: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # 只在 Niri 模块启用时提供 Noctalia 的 Home Manager 选项。
            # 这样 Denial 或其他桌面不会加载 Niri 专属的 shell 配置。
            home-manager.sharedModules = nixpkgs.lib.mkIf config.desktop.niri.enable [
              noctalia.homeModules.default
            ];
            home-manager.users.tiantian = import ./home/tiantian;
          })
          noctalia.nixosModules.default
          noctalia-greeter.nixosModules.default
          denial.nixosModules.default
        ];
      };
    in {
      vivobook = mkX86Host ./hosts/vivobook;
      kuangshi = mkX86Host ./hosts/kuangshi;
    };
  };
}
