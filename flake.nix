{
  description = "Rikki 's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nil = {
      url = "github:oxalica/nil";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    {
      nixosConfigurations = {
        "ASUS_TianXuan4_Rikki" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
          };
          modules =
            [ ./plugin ]
            ++ [
              { nixpkgs.config.allowUnfree = true; }
              # Desktop
              ./desktop/gnome

              # device
              ./device/ASUS_TianXuan4

              # layers
              ./layer/develop

              ./layer/flatpak

              # extra services
              # ./plugin/services/tailscale
              # ./plugin/services/virtualbox
              #./plugin/services/vmware
              #./plugin/services/vm
              ./plugin/services/docker

              # users
              ./users/rikki-laptop
            ];
        };
      };
    };
}
