.PHONY: update
update:
	home-manager switch --flake .#qnm@windoze

.PHONY: clean
clean:
	nix-collect-garbage -d
