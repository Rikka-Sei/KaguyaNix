{...}: {
  imports = [
    ./users/rikki/default.nix
  ];

  networking.hostName = "laptop-asus-tx4-personal";

  time.timeZone = "Asia/Shanghai";

  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        3000
        8080
        20171
      ];
    };
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "rikki"
    ];
  };

  system.stateVersion = "24.05";
}
