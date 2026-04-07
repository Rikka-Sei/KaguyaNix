{ lib, pkgs, config, ... }:
let
  cfg = config.kaguya.core.input;
in
{
  options.kaguya.core.input.enable = lib.mkEnableOption "输入法能力";

  config = lib.mkIf cfg.enable {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-chinese-addons
        fcitx5-mozc
        fcitx5-gtk
      ];
    };
  };
}
