{lib}: let
  errors = import ./errors.nix {inherit lib;};

  validPlatforms = [
    "linux"
    "darwin"
  ];

  validArches = [
    "x86_64"
    "aarch64"
  ];

  validShells = [
    "bash"
    "fish"
    "zsh"
  ];

  ensureAttrs = locale: hostName: subject: value:
    if builtins.isAttrs value
    then value
    else
      errors.throwError locale {
        code = "node.invalidType";
        host = hostName;
        inherit subject;
        expected = "attrset";
        actual = builtins.typeOf value;
      };

  ensureString = locale: hostName: subject: value:
    if builtins.isString value
    then value
    else
      errors.throwError locale {
        code = "node.invalidType";
        host = hostName;
        inherit subject;
        expected = "string";
        actual = builtins.typeOf value;
      };

  ensureBool = locale: hostName: subject: value:
    if builtins.isBool value
    then value
    else
      errors.throwError locale {
        code = "node.invalidType";
        host = hostName;
        inherit subject;
        expected = "bool";
        actual = builtins.typeOf value;
      };

  ensureListOfStrings = locale: hostName: subject: value:
    if builtins.isList value && lib.all builtins.isString value
    then value
    else
      errors.throwError locale {
        code = "node.invalidType";
        host = hostName;
        inherit subject;
        expected = "list<string>";
        actual = builtins.typeOf value;
      };

  ensureOptionalString = locale: hostName: subject: value:
    if value == null || builtins.isString value
    then value
    else
      errors.throwError locale {
        code = "node.invalidType";
        host = hostName;
        inherit subject;
        expected = "string|null";
        actual = builtins.typeOf value;
      };

  ensureEnum = locale: hostName: subject: allowed: value: let
    normalized = ensureString locale hostName subject value;
  in
    if builtins.elem normalized allowed
    then normalized
    else
      errors.throwError locale {
        code = "node.invalidEnum";
        host = hostName;
        inherit subject;
        expected = allowed;
        actual = normalized;
      };

  ensureOptionPath = locale: capabilityId: facet: value:
    if builtins.isList value && lib.all builtins.isString value
    then value
    else
      errors.throwError locale {
        code = "cap.invalidMetaField";
        subject = capabilityId;
        inherit facet;
        field = "optionPath";
      };

  mergeAttrsets = attrsets: lib.foldl' lib.recursiveUpdate {} attrsets;

  parseCapId = locale: capabilityId: let
    match = builtins.match "([^/]+)/([^/]+)" capabilityId;
  in
    if match == null
    then
      errors.throwError locale {
        code = "cap.invalidId";
        subject = capabilityId;
      }
    else {
      domain = builtins.elemAt match 0;
      name = builtins.elemAt match 1;
    };

  capDir = locale: modulesDir: capabilityId: let
    parts = parseCapId locale capabilityId;
  in
    modulesDir + "/${parts.domain}/${parts.name}";

  loadCapFacet = {
    locale,
    modulesDir,
    capabilityId,
    facet,
    target,
  }: let
    baseDir = capDir locale modulesDir capabilityId;
    facetDir = baseDir + "/${facet}";
    metaPath = facetDir + "/meta.nix";
    modulePath = facetDir + "/module.nix";
  in
    if !builtins.pathExists baseDir
    then
      errors.throwError locale {
        code = "cap.unknown";
        subject = capabilityId;
      }
    else if !(builtins.pathExists metaPath && builtins.pathExists modulePath)
    then
      errors.throwError locale {
        code = "cap.missingFacet";
        subject = capabilityId;
        inherit facet;
      }
    else let
      metaRaw = import metaPath;
      meta = ensureAttrs locale "meta" "meta" metaRaw;
      support = ensureAttrs locale "meta" "support" (meta.support or {});
      platform = ensureListOfStrings locale "meta" "support.platform" (support.platform or []);
      arch = ensureListOfStrings locale "meta" "support.arch" (support.arch or []);
      requires = ensureListOfStrings locale "meta" "requires" (meta.requires or []);
      conflicts = ensureListOfStrings locale "meta" "conflicts" (meta.conflicts or []);
      optionPath = ensureOptionPath locale capabilityId facet (meta.optionPath or []);

      _platformCheck =
        if builtins.elem target.platform platform
        then true
        else
          errors.throwError locale {
            code = "cap.unsupportedPlatform";
            subject = capabilityId;
            inherit facet;
            expected = platform;
            actual = target.platform;
          };

      _archCheck =
        if builtins.elem target.arch arch
        then true
        else
          errors.throwError locale {
            code = "cap.unsupportedArch";
            subject = capabilityId;
            inherit facet;
            expected = arch;
            actual = target.arch;
          };
    in {
      inherit
        arch
        capabilityId
        conflicts
        facet
        modulePath
        optionPath
        platform
        requires
        ;
    };

  resolveCaps = {
    locale,
    modulesDir,
    target,
    facet,
    requested,
  }: let
    visit = state: capabilityId:
      if state.seen.${capabilityId} or false
      then state
      else if builtins.elem capabilityId state.stack
      then
        errors.throwError locale {
          code = "cap.cycle";
          cycle = state.stack ++ [capabilityId];
        }
      else let
        nextState = state // {stack = state.stack ++ [capabilityId];};
        meta = loadCapFacet {
          inherit locale modulesDir capabilityId facet target;
        };
        afterRequires = lib.foldl' visit nextState meta.requires;
      in
        afterRequires
        // {
          stack = state.stack;
          seen = afterRequires.seen // {${capabilityId} = true;};
          resolved = afterRequires.resolved ++ [meta];
        };

    finalState =
      lib.foldl' visit {
        seen = {};
        stack = [];
        resolved = [];
      }
      requested;

    resolvedIds = map (item: item.capabilityId) finalState.resolved;

    _conflictChecks =
      map (
        item:
          map (
            conflict:
              if builtins.elem conflict resolvedIds
              then
                errors.throwError locale {
                  code = "cap.conflict";
                  subject = item.capabilityId;
                  conflicting = conflict;
                }
              else true
          )
          item.conflicts
      )
      finalState.resolved;
  in {
    caps = resolvedIds;
    facets = finalState.resolved;
    modulePaths = map (item: item.modulePath) finalState.resolved;
    optionDefaults = map (item: lib.setAttrByPath (item.optionPath ++ ["enable"]) true) finalState.resolved;
  };

  parseViewId = locale: viewId: let
    match = builtins.match "([^/]+)/([^/]+)" viewId;
  in
    if match == null
    then
      errors.throwError locale {
        code = "view.invalidId";
        subject = viewId;
      }
    else {
      domain = builtins.elemAt match 0;
      name = builtins.elemAt match 1;
    };

  viewDir = locale: viewsDir: viewId: let
    parts = parseViewId locale viewId;
  in
    viewsDir + "/${parts.domain}/${parts.name}";

  loadViewFacet = {
    locale,
    viewsDir,
    viewId,
    facet,
    target,
  }: let
    baseDir = viewDir locale viewsDir viewId;
    facetPath = baseDir + "/${facet}.nix";
  in
    if !builtins.pathExists baseDir
    then
      errors.throwError locale {
        code = "view.unknown";
        subject = viewId;
      }
    else if !builtins.pathExists facetPath
    then
      errors.throwError locale {
        code = "view.missingFacet";
        subject = viewId;
        inherit facet;
      }
    else let
      raw = import facetPath;
      data = ensureAttrs locale "view" "view" raw;
      support = ensureAttrs locale "view" "support" (data.support or {});
      platform = ensureListOfStrings locale "view" "support.platform" (support.platform or []);
      arch = ensureListOfStrings locale "view" "support.arch" (support.arch or []);
      includes = ensureListOfStrings locale "view" "includes" (data.includes or []);
      caps = ensureListOfStrings locale "view" "caps" (data.caps or []);
      _platformCheck =
        if builtins.elem target.platform platform
        then true
        else
          errors.throwError locale {
            code = "view.unsupportedPlatform";
            subject = viewId;
            inherit facet;
            expected = platform;
            actual = target.platform;
          };
      _archCheck =
        if builtins.elem target.arch arch
        then true
        else
          errors.throwError locale {
            code = "view.unsupportedArch";
            subject = viewId;
            inherit facet;
            expected = arch;
            actual = target.arch;
          };
    in
      builtins.seq _platformCheck (builtins.seq _archCheck {inherit viewId facet includes caps;});

  resolveViews = {
    locale,
    viewsDir,
    target,
    facet,
    requested,
  }: let
    visit = state: viewId:
      if state.seen.${viewId} or false
      then state
      else if builtins.elem viewId state.stack
      then
        errors.throwError locale {
          code = "view.cycle";
          cycle = state.stack ++ [viewId];
        }
      else let
        nextState = state // {stack = state.stack ++ [viewId];};
        view = loadViewFacet {inherit locale viewsDir viewId facet target;};
        afterIncludes = lib.foldl' visit nextState view.includes;
      in
        afterIncludes
        // {
          stack = state.stack;
          seen = afterIncludes.seen // {${viewId} = true;};
          caps = afterIncludes.caps ++ view.caps;
          views = afterIncludes.views ++ [viewId];
        };
    finalState =
      lib.foldl' visit {
        seen = {};
        stack = [];
        caps = [];
        views = [];
      }
      requested;
  in {
    views = finalState.views;
    caps = lib.unique finalState.caps;
  };

  normalizeUser = {
    hostName,
    locale,
    platform,
    userName,
    userCfg,
  }: let
    attrs = ensureAttrs locale hostName "users.${userName}" userCfg;
    shell = ensureEnum locale hostName "users.${userName}.shell" validShells (attrs.shell or "bash");
  in {
    enable = ensureBool locale hostName "users.${userName}.enable" (attrs.enable or true);
    admin = ensureBool locale hostName "users.${userName}.admin" (attrs.admin or false);
    inherit shell;
    extraGroups = ensureListOfStrings locale hostName "users.${userName}.extraGroups" (attrs.extraGroups or []);
    caps = ensureListOfStrings locale hostName "users.${userName}.caps" (attrs.caps or []);
    views = ensureListOfStrings locale hostName "users.${userName}.views" (attrs.views or []);
    overrides = ensureAttrs locale hostName "users.${userName}.overrides" (attrs.overrides or {});
    stateVersion = ensureString locale hostName "users.${userName}.stateVersion" (attrs.stateVersion or "24.05");
    homeDirectory = ensureOptionalString locale hostName "users.${userName}.homeDirectory" (
      attrs.homeDirectory
      or (
        if platform == "darwin"
        then "/Users/${userName}"
        else "/home/${userName}"
      )
    );
  };

  validateHardware = {
    hardwareDir,
    hardwareName,
    locale,
    target,
  }: let
    baseDir = hardwareDir + "/${hardwareName}";
    metaPath = baseDir + "/meta.nix";
    configurationPath = baseDir + "/configuration.nix";
  in
    if !builtins.pathExists baseDir
    then
      errors.throwError locale {
        code = "hardware.unknown";
        subject = hardwareName;
      }
    else if !builtins.pathExists metaPath
    then
      errors.throwError locale {
        code = "hardware.missingMeta";
        subject = hardwareName;
      }
    else if !builtins.pathExists configurationPath
    then
      errors.throwError locale {
        code = "hardware.missingConfiguration";
        subject = hardwareName;
      }
    else let
      metaRaw = import metaPath;
      meta = ensureAttrs locale "hardware" "meta" metaRaw;
      support = ensureAttrs locale "hardware" "support" (meta.support or {});
      platform = ensureListOfStrings locale "hardware" "support.platform" (support.platform or []);
      arch = ensureListOfStrings locale "hardware" "support.arch" (support.arch or []);
      _platformCheck =
        if builtins.elem target.platform platform
        then true
        else
          errors.throwError locale {
            code = "hardware.unsupportedPlatform";
            subject = hardwareName;
            expected = platform;
            actual = target.platform;
          };
      _archCheck =
        if builtins.elem target.arch arch
        then true
        else
          errors.throwError locale {
            code = "hardware.unsupportedArch";
            subject = hardwareName;
            expected = arch;
            actual = target.arch;
          };
    in {
      name = hardwareName;
      modulePath = configurationPath;
      inherit arch platform;
    };
in {
  inherit
    errors
    mergeAttrsets
    resolveViews
    validArches
    validPlatforms
    ;

  buildPlanFromMeta = {
    hostName,
    meta,
    modulesDir,
    hardwareDir,
    viewsDir,
  }: let
    rawMeta = ensureAttrs errors.defaultLocale hostName "meta" meta;
    locale = ensureString errors.defaultLocale hostName "locale" (rawMeta.locale or errors.defaultLocale);
    targetRaw =
      if rawMeta ? target
      then ensureAttrs locale hostName "target" rawMeta.target
      else
        errors.throwError locale {
          code = "node.missingField";
          host = hostName;
          subject = "target";
        };
    platform = ensureEnum locale hostName "target.platform" validPlatforms (
      if targetRaw ? platform
      then targetRaw.platform
      else
        errors.throwError locale {
          code = "node.missingField";
          host = hostName;
          subject = "target.platform";
        }
    );
    arch = ensureEnum locale hostName "target.arch" validArches (
      if targetRaw ? arch
      then targetRaw.arch
      else
        errors.throwError locale {
          code = "node.missingField";
          host = hostName;
          subject = "target.arch";
        }
    );
    hardwareName =
      if rawMeta ? hardware
      then ensureString locale hostName "hardware" rawMeta.hardware
      else
        errors.throwError locale {
          code = "node.missingField";
          host = hostName;
          subject = "hardware";
        };
    target = {
      inherit arch platform;
      system = "${arch}-${
        if platform == "linux"
        then "linux"
        else "darwin"
      }";
    };
    hostViews = ensureListOfStrings locale hostName "views" (rawMeta.views or []);
    hostCaps = ensureListOfStrings locale hostName "caps" (rawMeta.caps or []);
    hostOverrides = ensureAttrs locale hostName "overrides" (rawMeta.overrides or {});
    usersRaw = ensureAttrs locale hostName "users" (rawMeta.users or {});
    users =
      lib.mapAttrs (
        userName: userCfg:
          normalizeUser {
            inherit hostName locale platform userName userCfg;
          }
      )
      usersRaw;
    hardware = validateHardware {
      inherit hardwareDir hardwareName locale target;
    };
    systemViewResolution = resolveViews {
      inherit locale viewsDir target;
      facet = "system";
      requested = hostViews;
    };
    systemResolution = resolveCaps {
      inherit locale modulesDir target;
      facet = "system";
      requested = lib.unique (systemViewResolution.caps ++ hostCaps);
    };
    resolvedUsers =
      lib.mapAttrs (
        userName: userCfg: let
          userViewResolution = resolveViews {
            inherit locale viewsDir target;
            facet = "user";
            requested =
              if userCfg.enable
              then userCfg.views
              else [];
          };
          userResolution = resolveCaps {
            inherit locale modulesDir target;
            facet = "user";
            requested =
              if userCfg.enable
              then lib.unique (userViewResolution.caps ++ userCfg.caps)
              else [];
          };
        in
          userCfg
          // {
            caps = userResolution.caps;
            views = userViewResolution.views;
            modulePaths = userResolution.modulePaths;
            optionDefaults = userResolution.optionDefaults;
          }
      )
      users;
  in {
    inherit
      hardware
      hostName
      locale
      resolvedUsers
      target
      ;
    hostOverrides = hostOverrides;
    systemCaps = systemResolution.caps;
    systemCapModulePaths = systemResolution.modulePaths;
    systemOptionDefaults = systemResolution.optionDefaults;
    systemViews = systemViewResolution.views;
    users = resolvedUsers;
  };
}
