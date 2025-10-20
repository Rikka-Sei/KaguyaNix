{
  pkgs,
  ...
}:
let
  userName = "rikki";
in
{
  home-manager.users.${userName} = {
    home.packages = with pkgs; [
      spotify
    ];
  };
}
