{
  config,
  pkgs,
  ...
}: {
  i18n.defaultLocale = "zh_CN.UTF-8";
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      fira-code-nerdfont
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      source-han-sans
      source-han-serif
      sarasa-gothic #更纱黑体
      source-code-pro
      hack-font
      jetbrains-mono
      ubuntu_font_family
    ];

    # 简单配置一下 fontconfig 字体顺序，以免 fallback 到不想要的字体
    fontconfig = {
      defaultFonts = {
        emoji = ["Noto Color Emoji"];
        monospace = [
          "Ubuntu Mono"
          "Noto Sans Mono CJK SC"
          "Sarasa Mono SC"
          "DejaVu Sans Mono"
        ];
        sansSerif = [
          "Noto Sans CJK SC"
          "Source Han Sans SC"
          "DejaVu Sans"
        ];
        serif = [
          "Noto Serif CJK SC"
          "Source Han Serif SC"
          "DejaVu Serif"
        ];
      };
    };
  };

  system.fsPackages = [pkgs.bindfs];
  fileSystems = let
    mkRoSymBind = path: {
      device = path;
      fsType = "fuse.bindfs";
      options = ["ro" "resolve-symlinks" "x-gvfs-hide"];
    };
    aggregatedIcons = pkgs.buildEnv {
      name = "system-icons";
      paths = with pkgs; [
        #libsForQt5.breeze-qt5  # for plasma
        gnome.gnome-themes-extra
      ];
      pathsToLink = ["/share/icons"];
    };
    aggregatedFonts = pkgs.buildEnv {
      name = "system-fonts";
      paths = config.fonts.packages;
      pathsToLink = ["/share/fonts"];
    };
  in {
    "/usr/share/icons" = mkRoSymBind "${aggregatedIcons}/share/icons";
    "/usr/local/share/fonts" = mkRoSymBind "${aggregatedFonts}/share/fonts";
  };
}
