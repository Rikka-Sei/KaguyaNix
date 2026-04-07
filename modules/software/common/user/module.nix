{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kaguya.software.common;
in
{
  options.kaguya.software.common.enable = lib.mkEnableOption "通用软件能力";

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        bc
        jq
        fastfetch
        treefmt
        gimp
        vscode
        thunderbird
        gemini-cli
        xray
        sing-box
        logseq
        typst
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        gnome-software
        kdePackages.kdenlive
        remmina
        qq
        v2rayn
        typora
        hmcl
        mindustry
        ddnet
        feishu
        filezilla
        ghidra
        ghidra-extensions.ghidra-golanganalyzerextension
        anki
        firefox
        tor-browser
        calibre
        signal-desktop
      ];
  };
}
