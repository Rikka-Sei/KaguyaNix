{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kaguya.crossPlatform.linuxBuilder;
in
{
  options.kaguya.crossPlatform.linuxBuilder = {
    enable = lib.mkEnableOption "Linux Builder 能力";
    cores = lib.mkOption {
      type = lib.types.int;
      default = 4;
    };
    memorySize = lib.mkOption {
      type = lib.types.int;
      default = 4096;
    };
    diskSize = lib.mkOption {
      type = lib.types.int;
      default = 20000;
    };
    maxJobs = lib.mkOption {
      type = lib.types.int;
      default = 4;
    };
    ephemeral = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "Linux Builder 仅支持 Darwin 平台。";
      }
    ];

    nix.linux-builder = {
      enable = true;
      inherit (cfg) ephemeral maxJobs;
      config.virtualisation = {
        cores = lib.mkDefault cfg.cores;
        memorySize = lib.mkDefault cfg.memorySize;
        diskSize = lib.mkDefault cfg.diskSize;
      };
    };

    nix.settings = {
      trusted-users = [ "@admin" ];
      builders-use-substitutes = lib.mkDefault true;
    };
  };
}
