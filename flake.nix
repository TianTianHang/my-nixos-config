{
  description = "Modular NixOS configuration for vivobook";

  # 注意：不使用 nixConfig 声明缓存（非信任用户会收到 ignored 警告），
  # 全部缓存在 modules/nix.nix 中以系统级 nix.settings 配置

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

  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    noctalia,
    noctalia-greeter
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    # 自定义包覆盖
    overlay = final: prev: {
      fcitx5-osk = final.callPackage "${self}/pkgs/fcitx5-osk/default.nix" {};
    };
    pkgsWithOverlay = import nixpkgs {
      inherit system;
      overlays = [overlay];
    };
  in {
    nixosConfigurations.vivobook = nixpkgs.lib.nixosSystem {
      inherit system;
      pkgs = pkgsWithOverlay;
      modules = [
        ./hosts/vivobook
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # 全局注入 noctalia 的 Home Manager 模块，供 home/tiantian 中
          # 的 programs.noctalia 声明式设置使用
          home-manager.sharedModules = [noctalia.homeModules.default];
          home-manager.users.tiantian = import ./home/tiantian;
        }
        noctalia.nixosModules.default
        noctalia-greeter.nixosModules.default
      ];
    };

    # 导出自定义包供单独构建测试
    packages.x86_64-linux.fcitx5-osk = pkgsWithOverlay.fcitx5-osk;
  };
}
