{ config, ... }:
let
  cfg = config.user-environment.variables;

in
{
  config = {
    user-environment.variables.tracker-aria2 = "s";
  };
}
