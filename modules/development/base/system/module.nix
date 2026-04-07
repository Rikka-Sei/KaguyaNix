{
  config,
  inputs,
  lib,
  pkgs,
  unstable,
  ...
}:
let
  cfg = config.kaguya.development.base;
  alejandraPkg = inputs.alejandra.packages.${pkgs.system}.default or inputs.alejandra.defaultPackage.${pkgs.system};
  nilPkg = inputs.nil.packages.${pkgs.system}.default;
in
{
  options.kaguya.development.base = {
    enable = lib.mkEnableOption "基础开发能力";
    AIPackage = lib.mkOption {
      type = lib.types.package;
      default = unstable.AI-code;
      description = "AI 包来源。";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      [
        axel
        nano
        git
        vim
        wget
        curl
        gnumake
        zip
        xz
        unzip
        p7zip
        ripgrep
        mtr
        iperf3
        dnsutils
        aria2
        nmap
        ipcalc
        cowsay
        file
        which
        tree
        gnused
        gnutar
        gawk
        zstd
        nix-output-monitor
        nixfmt-rfc-style
        btop
        iftop
        lsof
        netcat-gnu
        mailutils
        alejandraPkg
        nilPkg
      ]
      ++ lib.optionals (!pkgs.stdenv.isDarwin) [
        vlc
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        iotop
        strace
        ltrace
        sysstat
        lm_sensors
        ethtool
        pciutils
        usbutils
        mission-center
      ];

    programs.direnv.enable = true;

    programs.AI-wrapper = {
      enable = true;
      package = cfg.AIPackage;
    };
  };
}
