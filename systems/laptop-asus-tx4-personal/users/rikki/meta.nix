{
  enable = true;
  admin = true;
  shell = "fish";
  extraGroups = [
    "docker"
    "vboxusers"
    "kvm"
    "libvirt"
    "libvirtd"
  ];
  views = [
    "development/base"
    "software/workstation"
    "gaming/base"
  ];
  caps = [
    "core/user-cli"
    "software/firefox"
    "software/vscode"
    "software/qq"
    "software/feishu"
    "software/signal-desktop"
    "software/kdenlive"
    "software/typora"
    "software/gnome-software"
    "software/remmina"
    "software/filezilla"
    "software/xray"
    "software/sing-box"
    "software/v2rayn"
    "software/anki"
    "software/calibre"
    "software/ghidra"
    "software/logseq"
    "software/gnucash"
    "software/spotify"
  ];
}
