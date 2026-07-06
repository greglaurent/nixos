{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    doom-emacs = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-desktop.url = "github:aaddrick/claude-desktop-debian";
  };

  outputs = { nixpkgs, home-manager, dms, doom-emacs, nixos-hardware, zen-browser, claude-desktop, ... }:
  let
    system = "x86_64-linux";
    hosts = [ "rhizome" "plateau" ];
    flakePkgs = final: prev: {
      zen-browser = zen-browser.packages.${system}.default;
      claude-desktop = claude-desktop.packages.${system}.claude-desktop-fhs;
    };

    mkHost = host: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit home-manager dms doom-emacs nixos-hardware; };
      modules = [
        { nixpkgs.overlays = [ flakePkgs ]; }
        ./hosts/${host}
      ];
    };
  in {
    nixosConfigurations = nixpkgs.lib.genAttrs hosts mkHost;

    # Scaffold a project dev shell:  nix flake init -t ~/.config/nixos#devshell
    templates.devshell = {
      path = ./templates/devshell;
      description = "Per-project dev shell (flake devShell + .envrc for direnv)";
    };
  };
}
