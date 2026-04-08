{lib}: let
  defaultLocale = "zh-CN";

  bundles = {
    "zh-CN" = {
      "node.missingField" = err: "系统 ${err.host} 缺少必填字段 `${err.subject}`。";
      "node.invalidType" = err: "系统 ${err.host} 的 `${err.subject}` 类型错误，期望 ${err.expected}，实际为 ${err.actual}。";
      "node.invalidEnum" = err: "系统 ${err.host} 的 `${err.subject}` 取值非法，期望 ${lib.concatStringsSep ", " err.expected}，实际为 `${err.actual}`。";
      "user.invalidShell" = err: "系统 ${err.host} 中用户 `${err.user}` 的 shell 不受支持，期望 ${lib.concatStringsSep ", " err.expected}，实际为 `${err.actual}`。";
      "capability.invalidId" = err: "capability 标识 `${err.subject}` 不合法，必须是 `<domain>/<name>` 形式。";
      "capability.unknown" = err: "未知 capability: ${err.subject}";
      "capability.missingFacet" = err: "capability `${err.subject}` 缺少 `${err.facet}` facet。";
      "capability.invalidMetaField" = err: "capability `${err.subject}.${err.facet}` 的元数据字段 `${err.field}` 非法。";
      "capability.unsupportedPlatform" = err: "capability `${err.subject}.${err.facet}` 不支持当前平台 `${err.actual}`，支持的平台为 ${lib.concatStringsSep ", " err.expected}。";
      "capability.unsupportedArch" = err: "capability `${err.subject}.${err.facet}` 不支持当前架构 `${err.actual}`，支持的架构为 ${lib.concatStringsSep ", " err.expected}。";
      "capability.conflict" = err: "capability `${err.subject}` 与 `${err.conflicting}` 冲突。";
      "capability.cycle" = err: "检测到 capability 依赖循环: ${lib.concatStringsSep " -> " err.cycle}";
      "hardware.unknown" = err: "未知硬件配置: ${err.subject}";
      "hardware.missingMeta" = err: "硬件 `${err.subject}` 缺少 `meta.nix`。";
      "hardware.missingConfiguration" = err: "硬件 `${err.subject}` 缺少 `configuration.nix`。";
      "hardware.unsupportedPlatform" = err: "硬件 `${err.subject}` 不支持当前平台 `${err.actual}`，支持的平台为 ${lib.concatStringsSep ", " err.expected}。";
      "hardware.unsupportedArch" = err: "硬件 `${err.subject}` 不支持当前架构 `${err.actual}`，支持的架构为 ${lib.concatStringsSep ", " err.expected}。";
    };

    "en-US" = {
      "node.missingField" = err: "System ${err.host} is missing required field `${err.subject}`.";
      "node.invalidType" = err: "System ${err.host} has invalid type for `${err.subject}`: expected ${err.expected}, got ${err.actual}.";
      "node.invalidEnum" = err: "System ${err.host} has invalid value for `${err.subject}`: expected one of ${lib.concatStringsSep ", " err.expected}, got `${err.actual}`.";
      "user.invalidShell" = err: "User `${err.user}` in system ${err.host} has unsupported shell `${err.actual}`. Expected one of ${lib.concatStringsSep ", " err.expected}.";
      "capability.invalidId" = err: "Capability id `${err.subject}` is invalid. Expected `<domain>/<name>`.";
      "capability.unknown" = err: "Unknown capability: ${err.subject}";
      "capability.missingFacet" = err: "Capability `${err.subject}` is missing `${err.facet}` facet.";
      "capability.invalidMetaField" = err: "Capability `${err.subject}.${err.facet}` has invalid metadata field `${err.field}`.";
      "capability.unsupportedPlatform" = err: "Capability `${err.subject}.${err.facet}` does not support platform `${err.actual}`. Supported platforms: ${lib.concatStringsSep ", " err.expected}.";
      "capability.unsupportedArch" = err: "Capability `${err.subject}.${err.facet}` does not support architecture `${err.actual}`. Supported architectures: ${lib.concatStringsSep ", " err.expected}.";
      "capability.conflict" = err: "Capability `${err.subject}` conflicts with `${err.conflicting}`.";
      "capability.cycle" = err: "Detected capability dependency cycle: ${lib.concatStringsSep " -> " err.cycle}";
      "hardware.unknown" = err: "Unknown hardware profile: ${err.subject}";
      "hardware.missingMeta" = err: "Hardware `${err.subject}` is missing `meta.nix`.";
      "hardware.missingConfiguration" = err: "Hardware `${err.subject}` is missing `configuration.nix`.";
      "hardware.unsupportedPlatform" = err: "Hardware `${err.subject}` does not support platform `${err.actual}`. Supported platforms: ${lib.concatStringsSep ", " err.expected}.";
      "hardware.unsupportedArch" = err: "Hardware `${err.subject}` does not support architecture `${err.actual}`. Supported architectures: ${lib.concatStringsSep ", " err.expected}.";
    };
  };

  fallbackRenderer = err: "Kaguya error ${err.code or "unknown"}: ${builtins.toJSON err}";
in {
  inherit bundles defaultLocale;

  renderError = locale: err: let
    bundle = bundles.${locale} or bundles.${defaultLocale};
    renderer = bundle.${err.code} or fallbackRenderer;
  in
    renderer err;

  throwError = locale: err:
    throw (
      let
        bundle = bundles.${locale} or bundles.${defaultLocale};
        renderer = bundle.${err.code} or fallbackRenderer;
      in
        renderer err
    );
}
