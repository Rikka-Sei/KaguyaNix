{
  config,
  lib,
  ...
}: let
  cfg = config.kaguya.identity.rikki;
  gitCfg = config.kaguya.programs.git;
in {
  options = {
    kaguya.identity.rikki.enable = lib.mkEnableOption "Rikki 身份能力";

    kaguya.programs.git = {
      enable = lib.mkEnableOption "Git 配置能力";
      userName = lib.mkOption {
        type = lib.types.str;
        default = "Rikki";
      };
      email = lib.mkOption {
        type = lib.types.str;
        default = "rikki@member.fsf.org";
      };
      signingKey = lib.mkOption {
        type = lib.types.str;
        default = "3927D7F5365B0203";
      };
      signCommits = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      lfs = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      kaguya.programs.git = {
        enable = lib.mkDefault true;
        userName = lib.mkDefault "Rikki";
        email = lib.mkDefault "rikki@member.fsf.org";
        signingKey = lib.mkDefault "3927D7F5365B0203";
        signCommits = lib.mkDefault true;
        lfs = lib.mkDefault true;
      };
    })

    (lib.mkIf gitCfg.enable {
      programs.git = {
        enable = true;
        lfs.enable = gitCfg.lfs;
        settings = {
          user = {
            name = gitCfg.userName;
            email = gitCfg.email;
            signingkey = gitCfg.signingKey;
          };
          commit.gpgsign = gitCfg.signCommits;
        };
      };
    })
  ];
}
