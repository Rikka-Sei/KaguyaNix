# if you want to enable this config
# you need to add "vboxusers" to users.users.<name>.extraGroups
{
  virtualisation.virtualbox =
    let
      pkgs = import (builtins.fetchGit {
        # Descriptive name to make the store path easier to identify
        name = "overlay-virtualbox";
        url = "https://github.com/NixOS/nixpkgs/";
        ref = "refs/heads/nixos-24.05";
        rev = "6eb01a67e1fc558644daed33eaeb937145e17696";
      }) { };

      overlay-virtualbox = pkgs.virtualbox;
    in
    {
      host = {
        enable = true;
        enableKvm = true;
        addNetworkInterface = false;
        package = overlay-virtualbox;
      };
      guest = {
        enable = true;
      };
    };
}
