{
  optionPath = [
    "kaguya"
    "software"
    "workstation"
  ];

  support = {
    platform = [
      "linux"
      "darwin"
    ];
    arch = [
      "x86_64"
      "aarch64"
    ];
  };

  requires = [
    "software/base-cli"
    "software/browser"
    "software/communication"
    "software/creative"
    "software/desktop-tools"
    "software/remote-access"
  ];
  conflicts = [];
}
