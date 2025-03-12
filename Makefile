ASUS_TianXuan4_Rikki:
	http_proxy=http://127.0.0.1:20171 https_proxy=http://127.0.0.1:20171 nixos-rebuild build --flake ./#ASUS_TianXuan4_Rikki --show-trace
	sudo nixos-rebuild switch --flake ./#ASUS_TianXuan4_Rikki
	rm result
	
update:
	nix flake update

format:
	alejandra ./

clean-garbage:
	nix-collect-garbage

eval-time:
	time nix eval --raw .#nixosConfigurations.ASUS_TianXuan4_Rikki.config.system.build.toplevel --show-trace