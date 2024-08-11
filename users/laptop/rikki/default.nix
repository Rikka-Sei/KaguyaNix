{
  users.users.rikki = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };
  home-manager.users.rikki = import ./rikki.nix;
}