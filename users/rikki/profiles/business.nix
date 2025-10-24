{
  pkgs,
  lib,
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
    ]
    # Linux 特有的财务软件
    ++ lib.optionals pkgs.stdenv.isLinux [
      gnucash
    ];
  };
}
