{
  description = "HenryZeng 's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-flatpak,
    alejandra,
    ...
  } @ inputs: {
    nixosConfigurations = {
      "ASUS_TianXuan4_Rikki" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          # base env
          ./device/ASUS_TianXuan4
          ./global/laptop-dev-env

          # extra services
          ./library/services/tailscale
          ./library/services/virtualbox
          ./library/services/vm

          # desktop env
          ./library/desktop-env/gnome

          # flatpak desktop env
          nix-flatpak.nixosModules.nix-flatpak
          ./library/services/flatpak/desktop-env

          # user env
          home-manager.nixosModules.home-manager
          ./library/home-manager
          ./users/laptop/rikki
        ];
      };
    };
  };
}
