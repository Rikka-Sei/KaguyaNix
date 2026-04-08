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
      "af60f7af4a5b4c1b0efe950e3e3f3ee8b136834ecb46fd7dba76f4b66adbc3e1"
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
