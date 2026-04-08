{
  config,
  lib,
  ...
}: let
  cfg = config.kaguya.services.teamviewer;
in {
  options.kaguya.services.teamviewer.enable = lib.mkEnableOption "TeamViewer 能力";

  config = lib.mkIf cfg.enable {
    services.teamviewer.enable = true;
  };
}
