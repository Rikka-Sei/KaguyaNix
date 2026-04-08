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
    "software/common"
    "software/logseq"
    "gaming/base"
    "business/common"
    "lifetime/common"
  ];
  overrides = {
    kaguya.programs.git.email = "rikki@member.fsf.org";
  };
}
