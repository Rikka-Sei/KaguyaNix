# 架构判断工具函数
{lib}: let
  # Darwin 架构列表
  darwinArchs = [
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  # Linux 架构列表
  linuxArchs = [
    "x86_64-linux"
    "aarch64-linux"
    "i686-linux"
    "riscv64-linux"
  ];
in {
  # 导出架构列表
  inherit darwinArchs linuxArchs;

  # 判断是否为 Darwin 架构
  isDarwin = architecture: builtins.elem architecture darwinArchs;

  # 判断是否为 Linux 架构
  isLinux = architecture: builtins.elem architecture linuxArchs;

  # 获取平台类型 - 返回 "darwin" 或 "linux"
  getPlatformType = architecture:
    if builtins.elem architecture darwinArchs
    then "darwin"
    else if builtins.elem architecture linuxArchs
    then "linux"
    else throw "Unsupported architecture: ${architecture}";
}
