{ pkgs, ... }:
{
  environment.systemPackages =
    with pkgs;
    [
      # User Tools
      axel
      nano
      git
      vim
      wget
      curl
      vlc
      emacs
      gnumake
    ]
    ++ [
      # system tools
      # archives
      zip
      xz
      unzip
      p7zip

      # utils
      ripgrep

      # networking tools
      mtr
      iperf3
      dnsutils
      aria2
      nmap
      ipcalc

      # misc
      cowsay
      file
      which
      tree
      gnused
      gnutar
      gawk
      zstd

      # nix related
      nix-output-monitor
      nixfmt-rfc-style

      btop
      iotop
      iftop

      # system call monitoring
      strace
      ltrace
      lsof

      # system tools
      sysstat
      lm_sensors
      ethtool
      pciutils
      usbutils

      netcat-openbsd
    ]
    ++ [
      # Monitor tools
      mission-center
      mailutils
    ];

  services.postfix = {
    enable = true;
    domain = "localhost";
    origin = "localhost";
    config = {
      mydestination = "localhost";
      inet_interfaces = "loopback-only";
      default_transport = "local";
    };
  };

  programs.direnv.enable = true;
}
