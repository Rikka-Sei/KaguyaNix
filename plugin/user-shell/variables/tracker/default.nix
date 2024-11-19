{ config, ... }:
let
  cfg = config.user-shell.variables;

in
{
  configs = {
    user-shell.variables.tracker-aria2 = "s";
  };
}
