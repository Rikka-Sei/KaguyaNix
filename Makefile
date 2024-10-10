ASUS_TianXuan4_Rikki:
	sudo nixos-rebuild switch --flake ./#ASUS_TianXuan4_Rikki --show-trace
	
update:
	nix flake update

format:
	alejandra ./

clean-garbage:
	nix-collect-garbage

eval-time:
	time nix eval --raw .#nixosConfigurations.ASUS_TianXuan4_Rikki.config.system.build.toplevel --show-trace