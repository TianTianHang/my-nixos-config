{
  description = "Modular NixOS configuration for vivobook";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
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
          home-manager.users.tiantian = import ./home/tiantian;
        }
      ];
    };
  };
}
