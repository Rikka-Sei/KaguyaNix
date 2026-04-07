{
  target = {
    platform = "darwin";
    arch = "x86_64";
  };

  hardware = "mbp2019";
  locale = "zh-CN";

  capabilities = [
    "development/base"
    "development/emacs"
    "cross-platform/linux-builder"
  ];

  users.rikki = import ./users/rikki/meta.nix;
}
