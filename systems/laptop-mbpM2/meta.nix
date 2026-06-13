{
  target = {
    platform = "darwin";
    arch = "aarch64";
  };

  hardware = "mbpM2";
  locale = "zh-CN";

  views = [
    "development/base"
  ];

  caps = [
    "development/emacs"
    "cross-platform/linux-builder"
  ];

  users.rikki = import ./users/rikki/meta.nix;
}
