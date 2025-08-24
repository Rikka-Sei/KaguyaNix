{
  pkgs,
  inputs,
  ...
}:
let
  userName = "rikki";
in
{
  # 开发工具
  environment.systemPackages = [
  ];

  home-manager.users.${userName} = {
    programs.gnucash.enable = true;
  };

  users.users.${userName}.shell = pkgs.fish;
  programs.fish.enable = true;
}
