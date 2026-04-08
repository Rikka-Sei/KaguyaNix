{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.development.emacs;
in {
  options.kaguya.development.emacs.enable = lib.mkEnableOption "Emacs 开发能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      emacs
      emacsPackages.vterm
    ];
  };
}
