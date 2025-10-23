# MacBook Pro 2019 löMn
{ config, lib, pkgs, ... }:

{
  # /(æ§/
  system.defaults = {
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };
    
    # Dock Mn
    dock = {
      autohide = true;
      orientation = "bottom";
    };

    # Finder Mn  
    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
    };
  };

  # ‰hMn
  security.pam.enableSudoTouchId = true;
}