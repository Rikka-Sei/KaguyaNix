{
  support = {
    platform = ["linux" "darwin"];
    arch = ["x86_64" "aarch64"];
  };
  includes = [];
  caps = [
    "development/toolchain"
    "core/cli-utils"
    "operations/network-tools"
    "operations/system-diagnostics"
  ];
}
