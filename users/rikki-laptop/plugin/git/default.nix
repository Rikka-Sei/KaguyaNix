{
  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "Rikki";
    userEmail = "rikki@member.fsf.org";
    extraConfig = {
      user.signingkey = "85E52EEE42578D11";
      commit.gpgsign = true;
    };
  };
}
