{ config, ... }:
let
  cfg = config.user-shell.variables;

in
{
  config = {
    user-shell.variables.tracker-aria2 = "s";
  };
}
