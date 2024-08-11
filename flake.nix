{
  description = "HenryZeng 's NixOS Flake";

  inputs = {
    nixpkgs.url = "https://mirrors.ustc.edu.cn/nix-channels/nixos-24.05/nixexprs.tar.xz";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
        "ASUS_TianXuan4_Rikki" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; }; # this is the important part
          modules = [
            # base env
            ./device/ASUS_TianXuan4
            ./global/laptop-dev-env

            # user env
            home-manager.nixosModules.home-manager
            ./library/home-manager
            ./users/laptop/rikki
          ];
      };
    };
  };
}
