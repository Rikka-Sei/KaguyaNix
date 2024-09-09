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