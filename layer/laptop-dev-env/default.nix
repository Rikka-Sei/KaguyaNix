{pkgs, ...}: {
  environment.systemPackages = with pkgs;
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
      # Gnome
      # gnomeApps
      gnome.gnome-tweaks

      # gnomeExtensions
      gnomeExtensions.kimpanel
    ]
    ++ [
      # system tools
      # archives
      zip
      xz
      unzip
      p7zip

      # utils
      ripgrep # recursively searches directories for a regex pattern

      # networking tools
      mtr # A network diagnostic tool
      iperf3
      dnsutils # `dig` + `nslookup`
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      nmap # A utility for network discovery and security auditing
      ipcalc # it is a calculator for the IPv4/v6 addresses

      # misc
      cowsay
      file
      which
      tree
      gnused
      gnutar
      gawk
      zstd
      gnupg

      # nix related
      #
      # it provides the command `nom` works just like `nix`
      # with more details log output
      nix-output-monitor

      btop # replacement of htop/nmon
      iotop # io monitoring
      iftop # network monitoring

      # system call monitoring
      strace # system call monitoring
      ltrace # library call monitoring
      lsof # list open files

      # system tools
      sysstat
      lm_sensors # for `sensors` command
      ethtool
      pciutils # lspci
      usbutils # lsusb

      netcat-openbsd
    ]
    ++ [
      # Monitor tools
      mission-center
    ];

  programs.direnv.enable = true;

  nixpkgs.config.permittedInsecurePackages = [
    "electron-25.9.0"
  ];

  services.v2raya.enable = true;
}
