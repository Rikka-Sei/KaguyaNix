{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kaguya.software."network-access";
in
{
  options.kaguya.software."network-access".enable = lib.mkEnableOption "网络接入软件能力";

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        xray
        sing-box
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        v2rayn
      ];
  };
}
