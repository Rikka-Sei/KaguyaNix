{
  # TODO: waiting for https://github.com/nix-community/home-manager/pull/3238 to be merged

  # programs.blesh = {
  #   enable = true;
  #   options = {
  #     prompt_ps1_transient = "trim:same-dir";
  #     prompt_ruler = "empty-line";
  #   };
  #   blercExtra = ''
  #     function my/complete-load-hook {
  #       bleopt complete_auto_history=
  #       bleopt complete_ambiguous=
  #       bleopt complete_menu_maxlines=10
  #     };
  #     blehook/eval-after-load complete my/complete-load-hook
  #   '';
  # };
}