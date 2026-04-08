{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kaguya.software."reverse-engineering";
in
{
  options.kaguya.software."reverse-engineering".enable = lib.mkEnableOption "逆向分析软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals pkgs.stdenv.isLinux (
      with pkgs;
      [
        ghidra
        ghidra-extensions.ghidra-golanganalyzerextension
      ]
    );
  };
}
