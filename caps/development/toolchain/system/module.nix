{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.development.toolchain;
  alejandraPkg = inputs.alejandra.packages.${pkgs.system}.default or inputs.alejandra.defaultPackage.${pkgs.system};
  nilPkg = inputs.nil.packages.${pkgs.system}.default;
in {
  options.kaguya.development.toolchain.enable = lib.mkEnableOption "开发工具链能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      gnumake
      nix-output-monitor
      nixfmt-rfc-style
      alejandraPkg
      nilPkg
    ];
    programs.direnv.enable = true;
  };
}
