{ lib }:
{
  # 扫描 packages 目录，生成 overlay 和模块配置
  loadPackages = packagesDir:
    let
      # 读取 packages 目录
      packageEntries =
      if builtins.pathExists packagesDir
      then builtins.readDir packagesDir
      else {};

      # 解析包名和路径
      packagePaths = lib.mapAttrsToList (name: type:
        let
          # 去掉 .nix 后缀作为包名
          pkgName = lib.removeSuffix ".nix" name;
          # 确定包的路径
          pkgPath =
            if type == "directory"
            then packagesDir + "/${name}"
            else packagesDir + "/${name}";
        in
        {
          name = pkgName;
          path = pkgPath;
        }
      ) packageEntries;

      # 生成 overlay（将所有包注入到 pkgs）
      generateOverlay = final: prev:
        let
          # 为每个包创建一个 overlay entry
          packageOverlays = builtins.listToAttrs (
            map (pkg:
              let
                # 导入包定义
                packageDef = import pkg.path {
                  pkgs = final;
                  lib = lib;
                  config = { }; # 临时的空 config，实际会被模块系统替换
                };
              in
              {
                name = pkg.name;
                value = packageDef.package or (throw "Package ${pkg.name} must export 'package' attribute");
              }
            ) packagePaths
          );
        in
        packageOverlays;

      # 生成 NixOS/Darwin 模块（合并所有包的 options 和 config）
      generateModule = { config, pkgs, lib, ... }:
        let
          # 为每个包导入定义并提取 options 和 config
          packageModules = map (pkg:
            let
              packageDef = import pkg.path {
                inherit pkgs lib config;
              };
            in
            {
              options = packageDef.options or { };
              config = packageDef.config or { };
            }
          ) packagePaths;

          # 合并所有 options
          allOptions = lib.foldl' (acc: mod: acc // mod.options) { } packageModules;

          # 合并所有 config
          allConfigs = map (mod: mod.config) packageModules;
        in
        {
          options = allOptions;
          config = lib.mkMerge allConfigs;
        };

    in
    {
      overlay = generateOverlay;
      module = generateModule;
    };
}
