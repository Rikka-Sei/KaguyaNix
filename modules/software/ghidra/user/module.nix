{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.ghidra;
in {
  options.kaguya.software.ghidra.enable = lib.mkEnableOption "Ghidra 逆向分析能力";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ghidra
      ghidra-extensions.ghidra-golanganalyzerextension
    ];
  };
}
