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
  capabilities = [
    "identity/rikki"
    "development/base"
    "software/workstation"
    "software/network-access"
    "software/learning"
    "software/logseq"
    "software/reverse-engineering"
    "gaming/base"
    "business/common"
    "lifetime/common"
  ];
  overrides = {
    kaguya.programs.git.email = "rikki@member.fsf.org";
  };
}
