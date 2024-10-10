{
  alejandra,
  pkgs,
  ...
}: {
  home.packages = [
    alejandra.defaultPackage.${pkgs.stdenv.hostPlatform.system}
  ];
}
