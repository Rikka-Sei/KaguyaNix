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

        function traffic_calc --description "计算流量费用和USDT数量" --argument price
            # 检查价格参数
            if test -z "$price"
                echo "错误: 请提供价格参数"
                echo "用法: traffic_calc <价格>"
                return 1
            end
            
            if not string match -qr '^[0-9]+\.?[0-9]*$' $price
                echo "错误: 请输入有效的价格数字"
                return 1
            end
            
            # 获取用户输入
            read -P "请输入当前流量(G): " traffic
            
            # 验证输入
            if test -z "$traffic"
                echo "错误: 流量不能为空"
                return 1
            end
            
            if not string match -qr '^[0-9]+\.?[0-9]*$' $traffic
                echo "错误: 请输入有效的数字"
                return 1
            end
            
            echo "正在获取USDT汇率..."
            
            # 获取USDT汇率
            set usdt_rate (https_proxy=http://127.0.0.1:20171 curl -s "https://api.coinbase.com/v2/exchange-rates?currency=USDT" | jq -r '.data.rates.CNY')
            
            # 检查汇率获取是否成功
            if test -z "$usdt_rate" -o "$usdt_rate" = "null"
                echo "错误: 无法获取USDT汇率，请检查网络连接"
                return 1
            end
            
            # 计算调整后汇率 (减去0.1)
            set adjusted_rate (echo "$usdt_rate - 0.1" | bc -l)
            
            # 计算总费用 CNY (流量 * 传入的价格)
            set total_cny (echo "$traffic * $price" | bc -l)
            
            # 计算需要的USDT数量
            set usdt_amount (echo "scale=6; $total_cny / $adjusted_rate" | bc -l)
            
            # 输出结果
            echo ""
            echo "========== 计算结果 =========="
            echo "流量: $traffic G"
            echo "总费用: $total_cny CNY"
            echo "USDT汇率: $usdt_rate CNY"
            echo "调整后汇率: $adjusted_rate CNY"
            echo "需要USDT: $usdt_amount"
            echo "============================="
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
