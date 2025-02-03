{ config, ... }:
let
  cfg = config.user-envirentment.variables;

in
{
  config = {
    user-envirentment.variables.tracker-aria2 = "s";
  };
}
