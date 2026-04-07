{
  target = {
    platform = "darwin";
    arch = "aarch64";
  };

  hardware = "mbpM2";
  locale = "zh-CN";

  capabilities = [
    "development/base"
    "development/emacs"
    "cross-platform/linux-builder"
  ];

  users.rikki = import ./users/rikki/meta.nix;
}
