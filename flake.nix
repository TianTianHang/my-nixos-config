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

    # niri 的 NixOS/Home Manager 模块与上游构建的包（追新）。
    # 注意：不能写 inputs.nixpkgs.follows——它依赖的库版本随其锁定的
    # nixpkgs 走，跟随我们的会导致缓存失效甚至缺依赖
    niri.url = "github:sodiboo/niri-flake";

  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    niri,
    noctalia,
    noctalia-greeter
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    nixosConfigurations.vivobook = nixpkgs.lib.nixosSystem {
      inherit system;
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
        niri.nixosModules.niri
        {
          # 使用 niri-flake 上游预构建的 niri-unstable（最新主分支，
          # 命中其 cachix 缓存），避免用本地 pkgs 重编译
          programs.niri.package = niri.packages.${system}.niri-unstable;
        }
        noctalia.nixosModules.default
        noctalia-greeter.nixosModules.default
      ];
    };
  };
}
