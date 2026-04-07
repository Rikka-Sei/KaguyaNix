{ ... }:
{
  imports = [
    ./users/rikki/default.nix
  ];

  networking.hostName = "laptop-mbpM2";

  time.timeZone = "Asia/Shanghai";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "@admin"
      "rikki"
    ];
  };

  kaguya.crossPlatform.linuxBuilder = {
    cores = 3;
    memorySize = 2048;
    diskSize = 25000;
    maxJobs = 3;
    ephemeral = true;
  };

  system.stateVersion = 6;
}
