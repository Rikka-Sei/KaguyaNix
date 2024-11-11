{
  nil,
  pkgs,
  ...
}: {
  home.packages = [
    nil.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
