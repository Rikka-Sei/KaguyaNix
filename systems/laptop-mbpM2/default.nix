{...}: {
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

  # 允许 nix-darwin 接管当前机器上已有的 shell 初始化文件。
  environment.etc = {
    "bashrc".knownSha256Hashes = [
      "8b5e3466922d1ae34bc145e21c7e53e7329a7a7b58b148b436bd954d5e651ac3"
    ];
    "zshrc".knownSha256Hashes = [
      "4d1ab5704f9d167a042fecac0d056c8a79a8ebd71e032d3489536c8db9ffe3e0"
    ];
    "zprofile".knownSha256Hashes = [
      "f320016e2cf13573731fbee34f9fe97ba867dd2a31f24893d3120154e9306e92"
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
