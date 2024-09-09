{
  users.users.rikki = {
    isNormalUser = true;
    extraGroups = [ "wheel" "vboxusers" ];
  };
  home-manager.users.rikki = import ./rikki.nix;
}