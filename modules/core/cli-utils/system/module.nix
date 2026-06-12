{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.core.cli-utils;
in {
  options.kaguya.core.cli-utils.enable = lib.mkEnableOption "通用 CLI 工具能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      axel
      nano
      vim
      wget
      curl
      zip
      xz
      unzip
      p7zip
      ripgrep
      file
      which
      tree
      gnused
      gnutar
      gawk
      zstd
      cowsay
      mailutils
    ];
  };
}
