{
  pkgs,
  ...
}:
let
  userName = "rikki";
in
{
  # 系统软件
  environment.systemPackages = [
  ];

  home-manager.users.${userName} = {
    home.packages = with pkgs; [
      gnucash
    ];
  };
}
