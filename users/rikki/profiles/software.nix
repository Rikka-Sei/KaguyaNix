{
  pkgs,
  unstable,
  ...
}: let
  userName = "rikki";
in {
  home-manager.users.${userName} = {
    home.packages = with pkgs;
      [
        # User CLI Tools
        bc
        jq
        fastfetch
        treefmt
      ]
      ++ [
        # GNOME packages
        gnome-software
      ]
      ++ [
        # User GUI Tools
        gimp
        typora
      ]
      ++ [
        # Games
        hmcl
        mindustry
      ]
      ++ [
        # Web Browser
        firefox
      ]
      ++ [
        # Editor
        vscode
      ]
      ++ [
        # Learn
        anki
      ]
      ++ [
        # File Transfer
        filezilla
      ]
      ++ [
        # Generator
        typst
        thunderbird
        hiddify-app
      ]
      ++ [
        unstable.AI-code
        gemini-cli
        ddnet
        ghidra
        ghidra-extensions.ghidra-golanganalyzerextension
        remmina
        feishu
        tor-browser
        kdePackages.kdenlive
        qq
      ];
  };
}
