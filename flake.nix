{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Tracks upstream more closely; used to pull individual packages that lag in
    # the stable channel (currently: rustdesk 1.4.9 vs 26.05's 1.4.7).
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

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

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, dms, doom-emacs, nixos-hardware, zen-browser, claude-desktop, ... }:
  let
    system = "x86_64-linux";
    hosts = [ "rhizome" "plateau" ];
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
    flakePkgs = final: prev: {
      zen-browser = zen-browser.packages.${system}.default;
      claude-desktop = claude-desktop.packages.${system}.claude-desktop-fhs;
      obsbot-camera-control = final.callPackage ./pkgs/obsbot-camera-control { };
      # nixos-26.05 lags upstream rustdesk (1.4.7); pull the current one from unstable.
      rustdesk = pkgs-unstable.rustdesk;
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
