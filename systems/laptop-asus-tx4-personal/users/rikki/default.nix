{pkgs, ...}: {
  home-manager.users.rikki = {
    home.packages = with pkgs; [
      powertop
      acpi
      brightnessctl
    ];

    programs.fish.shellAliases = {
      "power-usage" = "sudo powertop";
      "brightness" = "brightnessctl";
      "battery" = "acpi -b";
    };

    services.gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-gnome3;
    };
  };
}
