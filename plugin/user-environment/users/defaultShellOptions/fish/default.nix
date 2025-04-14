{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.user-environment.users;

  shell-conf = name: value: {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # Disable greeting

        function gitsign -d "Git commit with signing"
            if test (count $argv) -lt 1
                echo "用法: gitsign <message> [keyid]"
                return 1
            end

            set -l message $argv[1]
            set -l keyid 8A33560C4120DFA3  # 默认密钥

            if test (count $argv) -ge 2
                set keyid $argv[2]
            end

            git -c user.signingkey=$keyid! commit -S -m "$message"
        end
      '';
      # shellInit = ''
      #   export TL=${trackerList}
      #   0file() { curl -F"file=@$1" https://envs.sh ; }
      #   0pb() { curl -F"file=@-;" https://envs.sh ; }
      #   0url() { curl -F"url=$1" https://envs.sh ; }
      #   0short() { curl -F"shorten=$1" https://envs.sh ; }
      # '';
      plugins = [
        {
          name = "pure";
          src = pkgs.fishPlugins.pure.src;
        }
        {
          name = "fzf.fish";
          src = pkgs.fetchFromGitHub {
            owner = "PatrickF1";
            repo = "fzf.fish";
            rev = "e5d54b93cd3e096ad6c2a419df33c4f50451c900";
            hash = "sha256-5cO5Ey7z7KMF3vqQhIbYip5JR6YiS2I9VPRd6BOmeC8=";
          };
        }
        {
          name = "fish-async-prompt";
          src = pkgs.fetchFromGitHub {
            owner = "acomagu";
            repo = "fish-async-prompt";
            rev = "316aa03c875b58e7c7f7d3bc9a78175aa47dbaa8";
            hash = "sha256-J7y3BjqwuEH4zDQe4cWylLn+Vn2Q5pv0XwOSPwhw/Z0=";
          };
        }
      ];
    };
  };

  isType = t: t == "fish";
  isSelected = v: v.enable && isType v.defaultShell;
in
{
  config = {
    home-manager.users = mapAttrs (name: v: mkIf (isSelected v) (shell-conf name v)) cfg;

    users.users = mapAttrs (_: v: mkIf (isSelected v) { shell = pkgs.fish; }) cfg;

    programs.fish.enable = any isType (mapAttrsToList (_: v: v.defaultShell) cfg);
  };
}
