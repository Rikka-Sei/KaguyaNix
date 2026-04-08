{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kaguya.software.communication;
in
{
  options.kaguya.software.communication.enable = lib.mkEnableOption "通信软件能力";

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        thunderbird
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        qq
        feishu
        signal-desktop
      ];
  };
}
