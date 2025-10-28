{lib}: {
  # 导入 per-system 配置的便利函数
  # 使用方法: imports = lib.per-sys.import ./. systemName;
  # 在模块中: imports = lib.per-sys.import ./. systemName;
  import = baseDir: systemName:
    lib.optional
      (builtins.pathExists (baseDir + "/per-system/${systemName}.nix"))
      (baseDir + "/per-system/${systemName}.nix");

  # 检查 per-system 配置是否存在
  # 使用方法: lib.per-sys.exists ./. systemName
  exists = baseDir: systemName:
    builtins.pathExists (baseDir + "/per-system/${systemName}.nix");
}
