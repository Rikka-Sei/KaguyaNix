{
  pkgs,
  lib,
  ...
}:
let
  userName = "rikki";
in
{
  home-manager.users.${userName} = {
    home.packages =
      with pkgs;
      [
        # User CLI Tools
        bc
        jq
        fastfetch
        treefmt

        # Cross-platform GUI Tools
        gimp
        firefox
        vscode
        thunderbird

        # Cross-platform CLI/Other Tools
        gemini-cli
        xray
        sing-box
        logseq
        typst

      ]
      # Linux 特有的包
      ++ lib.optionals pkgs.stdenv.isLinux [
        # GNOME 软件
        gnome-software

        # KDE 软件
        kdePackages.kdenlive

        # Linux 专有工具
        remmina
        qq
        v2rayn

        # Linux 专有编辑器和应用
        typora

        # Games (Linux-specific builds)
        hmcl
        mindustry
        ddnet

        # 其他可能有平台问题的包
        feishu

        # 文件传输工具
        filezilla

        # 安全分析工具 (当前 broken)
        ghidra
        ghidra-extensions.ghidra-golanganalyzerextension

        # 学习工具 (当前在 macOS 上 broken)
        anki

        # 隐私浏览器
        tor-browser

        # 电子书管理 (当前 broken)
        calibre

        signal-desktop
      ];
  };
}
