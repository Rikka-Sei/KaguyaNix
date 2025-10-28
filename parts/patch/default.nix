{
  lib,              # extendedLib
  architecture,
  nixpkgsVersion,   # 从 flake URL 提取的版本号
}: let
  # 检查对应版本的 patch 文件是否存在
  patchFile = ./. + "/nixpkgs-${nixpkgsVersion}.nix";
  hasPatch = builtins.pathExists patchFile;

  # 加载版本特定的 patch（如果存在）
  patch =
    if hasPatch
    then builtins.trace "✅ Loading patch for nixpkgs ${nixpkgsVersion} (${architecture})" (import patchFile { inherit lib architecture; })
    else builtins.trace "⚠️ No patch found for nixpkgs ${nixpkgsVersion}" null;

  modules = if patch != null then patch.getModules else [];
  buildArgs = if patch != null then patch.getBuildArgs else {};
in
builtins.trace "Patch modules: ${builtins.toString (builtins.length modules)}, buildArgs: ${builtins.toJSON buildArgs}" {
  # 返回要添加到模块列表的配置
  getModules = modules;

  # 返回要合并到构建参数的配置
  getBuildArgs = buildArgs;
}
