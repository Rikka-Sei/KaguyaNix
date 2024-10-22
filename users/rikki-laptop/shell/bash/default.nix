{name, ...}: {
  options.userShell = {
    bash = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "The switch of  bash";
      };
    };
  };
}
