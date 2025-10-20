{ pkgs, ... }:
{
  environment.systemPackages =
    with pkgs;
    [
      emacs
    ]
    ++ [
      emacsPackages.vterm
    ];
}
