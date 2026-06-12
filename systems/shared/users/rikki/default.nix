{...}: {
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "Rikki";
        email = "rikki@member.fsf.org";
        signingkey = "3927D7F5365B0203";
      };
      commit.gpgsign = true;
    };
  };
}
