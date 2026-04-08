{
  self,
  inputs,
  lib,
  ...
}:
let
  # 扫描 deploy 目录中的所有 .nix 文件
  deployDir = ../deploy;
  deployFiles = builtins.readDir deployDir;

  # 过滤出 .nix 文件并移除扩展名
  deployNames = lib.mapAttrsToList (
    name: type:
    if type == "regular" && lib.hasSuffix ".nix" name then lib.removeSuffix ".nix" name else null
  ) deployFiles;

  validDeployNames = lib.filter (name: name != null) deployNames;

  # 为每个部署配置创建节点
  mkDeployNode =
    deployName:
    let
      deployConfig = import (deployDir + "/${deployName}.nix");
      systemName = deployConfig.system;
    in
    {
      hostname = deployConfig.hostname;

      profiles.system = {
        user = deployConfig.sshUser or "root";
        sshUser = deployConfig.sshUser or "root";
        sshOpts = deployConfig.sshOpts or [ ];
        fastConnection = deployConfig.fastConnection or true;
        autoRollback = deployConfig.autoRollback or true;
        magicRollback = deployConfig.magicRollback or true;

        path = inputs.deploy-rs.lib.${builtins.currentSystem}.activate.nixos self.nixosConfigurations.${systemName};
      };
    };

  # 生成所有部署节点
  deployNodes = lib.listToAttrs (
    map (deployName: {
      name = deployName;
      value = mkDeployNode deployName;
    }) validDeployNames
  );
in
{
  flake.deploy.nodes = deployNodes;

  # 添加 deploy-rs 的检查
  perSystem =
    { system, ... }:
    {
      checks = inputs.deploy-rs.lib.${system}.deployChecks self.deploy;
    };
}
