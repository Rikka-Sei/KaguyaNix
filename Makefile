ASUS_TianXuan4_Rikki:
	sudo nixos-rebuild switch --flake ./#ASUS_TianXuan4_Rikki
	
update:
	nix flake update

format:
	alejandra ./

clean-garbage:
	nix-collect-garbage