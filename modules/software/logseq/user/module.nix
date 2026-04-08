{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kaguya.software.logseq;
in
{
  options.kaguya.software.logseq.enable = lib.mkEnableOption "Logseq 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.logseq ];
  };
}
