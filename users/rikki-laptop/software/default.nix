{ pkgs, unstable, ... }:
{
  # 通过 home.packages 安装一些常用的软件
  # 这些软件将仅在当前用户下可用，不会影响系统级别的配置
  # 建议将所有 GUI 软件，以及与 OS 关系不大的 CLI 软件，都通过 home.packages 安装

  home.packages =
    with pkgs;
    [
      # User Cli Tools
      bc
      jq
      fastfetch
      treefmt
    ]
    ++ [
      # Gnome pkgs
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
      # editor
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
      # Generater
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
}
