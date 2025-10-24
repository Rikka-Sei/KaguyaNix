# Darwin 特定的用户配置 - laptop-mbp2019
{ lib, ... }:

{
  # 在 Darwin 系统中明确设置用户的 home 目录
  # 这样 home-manager 就能正确从 config.users.users.rikki.home 获取路径
  users.users.rikki = {
    name = "rikki";
    home = "/Users/rikki";
  };
}