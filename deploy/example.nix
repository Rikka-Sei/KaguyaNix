{
  # 部署配置：香港 VPS hk2-export
  hostname = "131.24.21.234"; # 也可以是 Domain
  system = "hk2-export"; # systems 目录下的 profile 名

  # SSH 配置
  sshUser = "root";
  sshOpts = [
    "-o"
    "StrictHostKeyChecking=no"
  ];

  # 部署选项
  fastConnection = false; # 海外服务器，网络可能较慢
  autoRollback = true; # 自动回滚
  magicRollback = true; # 魔法回滚（网络断开时）
}
