{ pkgs, lib, ... }:
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
      gnumake
    ]
    # 条件性包含 VLC - 仅在支持的平台上
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      vlc
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
      iftop

      # system call monitoring
      lsof
    ]
    # Linux 特有的包
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
    ]
    ++ [
      # netcat 替代方案 - netcat-openbsd 在某些版本中被标记为 broken
      netcat-gnu
      mailutils
    ];

  programs.direnv.enable = true;
}
