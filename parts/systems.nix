{
  self,
  inputs,
  lib,
  ...
}: let
  extendedLib = lib.extend (
    final: prev: let
      libFiles = builtins.readDir ../lib;
      libExtensions = builtins.listToAttrs (
        map
        (
          name: let
            attrName = lib.removeSuffix ".nix" name;
            attrValue = import (../lib + "/${name}") {lib = final;};
          in {
            name = attrName;
            value = attrValue;
          }
        )
        (
          builtins.filter (
            name:
              libFiles.${name}
              == "regular"
              && lib.hasSuffix ".nix" name
          ) (builtins.attrNames libFiles)
        )
      );
    in
      libExtensions
  );
  packages = extendedLib.packages.loadPackages ../packages;
  graph = extendedLib.capabilityGraph;
  systemEntries = builtins.readDir ../systems;
  systemNames = builtins.filter (
    name:
      systemEntries.${name}
      == "directory"
      && builtins.pathExists (../systems + "/${name}/meta.nix")
  ) (builtins.attrNames systemEntries);

  mkPlan = hostName:
    graph.buildPlanFromMeta {
      inherit hostName;
      meta = import (../systems + "/${hostName}/meta.nix");
      modulesDir = ../modules;
      hardwareDir = ../hardware;
    };

  shellPackage = pkgs: shellName:
    if shellName == "fish"
    then pkgs.fish
    else if shellName == "zsh"
    then pkgs.zsh
    else pkgs.bashInteractive;

  mkFrameworkModule = {
    hostName,
    plan,
    unstable,
  }: {
    lib,
    pkgs,
    ...
  }: let
    enabledUsers = lib.filterAttrs (_: userCfg: userCfg.enable) plan.users;
    shellPackages = lib.unique (map (userCfg: shellPackage pkgs userCfg.shell) (builtins.attrValues enabledUsers));
    hasFishUsers = lib.any (userCfg: userCfg.shell == "fish") (builtins.attrValues enabledUsers);
    hostConfig = graph.mergeAttrsets (
      plan.systemOptionDefaults
      ++ [
        plan.hostOverrides
        {
          kaguya.buildPlan = plan;
        }
      ]
    );
    mkUserModule = userName: userCfg: let
      userConfig = graph.mergeAttrsets (userCfg.optionDefaults ++ [userCfg.overrides]);
    in {
      imports =
        userCfg.modulePaths
        ++ [
          {
            config = userConfig;
          }
        ];

      home.username = userName;
      home.homeDirectory = userCfg.homeDirectory;
      home.stateVersion = userCfg.stateVersion;
      programs.home-manager.enable = true;
    };
    mkUserAccount = userName: userCfg: let
      shellPkg = shellPackage pkgs userCfg.shell;
      linuxGroups = lib.optionals userCfg.admin ["wheel"] ++ userCfg.extraGroups;
    in {
      ${userName} =
        if plan.target.platform == "darwin"
        then {
          name = userName;
          home = userCfg.homeDirectory;
          shell = shellPkg;
        }
        else {
          isNormalUser = true;
          home = userCfg.homeDirectory;
          extraGroups = linuxGroups;
          shell = shellPkg;
        };
    };
  in {
    options.kaguya.buildPlan = lib.mkOption {
      type = lib.types.attrs;
      internal = true;
      readOnly = true;
      description = "Kaguya 在预构建阶段生成的冻结构建计划。";
    };

    config =
      hostConfig
      // {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit inputs unstable;
          hostName = hostName;
          kaguyaBuildPlan = plan;
        };
        home-manager.users = lib.mapAttrs mkUserModule enabledUsers;
        users.users = lib.mkMerge (lib.mapAttrsToList mkUserAccount enabledUsers);
        environment.shells = shellPackages;
        programs.fish.enable = hasFishUsers;
      };
  };

  mkSystem = hostName: let
    plan = mkPlan hostName;
    nixpkgsVersion = "25.05";
    patches = import ./patch/default.nix {
      lib = extendedLib;
      architecture = plan.target.system;
      inherit nixpkgsVersion;
    };
    defaultModulePath = ../systems + "/${hostName}/default.nix";
    hasDefaultModule = builtins.pathExists defaultModulePath;
    buildSystemConfig =
      if plan.target.platform == "darwin"
      then {
        builder = inputs.nix-darwin.lib.darwinSystem;
        nixpkgsInput = inputs.nixpkgs-darwin;
        nixpkgsUnstableInput = inputs.nixpkgs-unstable or inputs.nixpkgs-darwin;
        platformModules =
          lib.optional
          (inputs ? home-manager && inputs.home-manager ? darwinModules)
          inputs.home-manager.darwinModules.home-manager;
      }
      else {
        builder = inputs.nixpkgs.lib.nixosSystem;
        nixpkgsInput = inputs.nixpkgs;
        nixpkgsUnstableInput = inputs.nixpkgs-unstable or inputs.nixpkgs;
        platformModules =
          lib.optional (inputs ? nix-flatpak) inputs.nix-flatpak.nixosModules.nix-flatpak
          ++ lib.optional
          (inputs ? home-manager && inputs.home-manager ? nixosModules)
          inputs.home-manager.nixosModules.home-manager;
      };
    unstable = import buildSystemConfig.nixpkgsUnstableInput {
      system = plan.target.system;
      config.allowUnfree = true;
    };
    systemBuildArgs =
      {
        specialArgs = {
          inherit inputs unstable;
          lib = extendedLib;
          hostName = hostName;
          kaguyaBuildPlan = plan;
        };

        modules =
          [
            {
              nixpkgs.overlays = [packages.overlay];
            }
            packages.module
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.hostPlatform = plan.target.system;
            }
            (mkFrameworkModule {
              inherit hostName plan unstable;
            })
            plan.hardware.modulePath
          ]
          ++ buildSystemConfig.platformModules
          ++ plan.systemModulePaths
          ++ lib.optional hasDefaultModule defaultModulePath
          ++ patches.getModules;
      }
      // patches.getBuildArgs;
  in
    buildSystemConfig.builder systemBuildArgs;

  nixosSystems =
    builtins.filter (
      hostName: let
        meta = import (../systems + "/${hostName}/meta.nix");
        platform = meta.target.platform or "linux";
      in
        platform == "linux"
    )
    systemNames;

  darwinSystems =
    builtins.filter (
      hostName: let
        meta = import (../systems + "/${hostName}/meta.nix");
        platform = meta.target.platform or "linux";
      in
        platform == "darwin"
    )
    systemNames;
in {
  flake = {
    lib.kaguya = {
      inherit (graph) buildPlanFromMeta mergeAttrsets;
      inherit (graph.errors) defaultLocale renderError throwError;
    };

    nixosConfigurations = builtins.listToAttrs (
      map (name: {
        inherit name;
        value = mkSystem name;
      })
      nixosSystems
    );

    darwinConfigurations = builtins.listToAttrs (
      map (name: {
        inherit name;
        value = mkSystem name;
      })
      darwinSystems
    );
  };
}
