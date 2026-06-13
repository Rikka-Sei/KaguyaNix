{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.core.command-not-found;
  nixosTarball = inputs.nixpkgs;
  programsSqlite = pkgs.runCommand "program.sqlite" {} ''
    cp ${nixosTarball}/programs.sqlite $out
  '';
in {
  options.kaguya.core.command-not-found.enable = lib.mkEnableOption "command-not-found 数据库能力";

  config = lib.mkIf cfg.enable {
    programs.command-not-found.dbPath = programsSqlite;
  };
}
