{
  home-manager,
  inputs,
  ...
}: {
  imports = [
    home-manager.nixosModules.home-manager
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = inputs;
}
