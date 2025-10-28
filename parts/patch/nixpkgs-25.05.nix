# nixpkgs 25.05 特定的补丁配置
#
# 问题描述：
# nixpkgs-25.05-darwin 分支内部版本号被错误标记为 25.11，
# 导致 nix-darwin 25.05 的版本检查失败。
#
# 参考：https://github.com/NixOS/nixpkgs/issues/409677
#
# 解决方案：
# 1. 禁用 Darwin 系统的文档生成（避免文档生成阶段触发版本检查）
# 2. 禁用 darwinSystem 的版本检查参数
# 3. 这是临时解决方案，等待上游修复后可以移除此补丁

{
  lib,          # extendedLib
  architecture,
}:

{
  # 返回要添加到模块列表的配置
  getModules = lib.optionals (lib.arch.isDarwin architecture) [
    {
      # 禁用 Darwin 系统的文档生成
      documentation.enable = lib.mkDefault false;
    }
  ];

  # 返回要合并到 darwinSystem 的构建参数
  getBuildArgs =
    if lib.arch.isDarwin architecture
    then {
      # 禁用版本检查
      enableNixpkgsReleaseCheck = false;
    }
    else {};
}
