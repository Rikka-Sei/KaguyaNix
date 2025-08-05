{ inputs, unstable, ... }:
{
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.home-manager.nixosModules.home-manager
    ./font
    ./input
    ./patch
    ./user-environment
  ];

  # home-manager pre config
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.extraSpecialArgs = {
    inherit inputs;
    inherit unstable; # 传递 unstable 参数给 home-manager
  };
}
