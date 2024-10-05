# if you want to enable this config
# you need to add "vboxusers" to users.users.<name>.extraGroups
{
  virtualisation.virtualbox = {
    host = {
      enable = true;
      enableKvm = true;
      addNetworkInterface = false;
    };
    guest = {
      enable = true;
    };
  };
}
