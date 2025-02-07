{ pkgs, inputs, ... }:
let
  # 直接使用 flake 中下载的 nixpkgs 源码
  nixos_tarball = inputs.nixpkgs;
  # 提取 programs.sqlite 文件
  programs-sqlite = pkgs.runCommand "program.sqlite" { } ''
    cp ${nixos_tarball}/programs.sqlite $out
  '';
in
{
  programs.command-not-found.dbPath = programs-sqlite;
}
