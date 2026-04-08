{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software."remote-access";
in {
  options.kaguya.software."remote-access".enable = lib.mkEnableOption "远程接入软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals pkgs.stdenv.isLinux (
      with pkgs; [
        remmina
        filezilla
      ]
    );
  };
}
