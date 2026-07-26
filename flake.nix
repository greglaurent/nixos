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
    pkgs = import nixpkgs { inherit system; };
    hosts = [ "rhizome" "plateau" ];
    flakePkgs = final: prev: {
      zen-browser = zen-browser.packages.${system}.default;
      claude-desktop = claude-desktop.packages.${system}.claude-desktop-fhs;
      obsbot-camera-control = final.callPackage ./pkgs/obsbot-camera-control { };
      rustdesk-bin = final.callPackage ./pkgs/rustdesk-bin { };   # official 1.4.9 binary, patched for NixOS
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

    # Per-project dev shells kept OUT of the project repos. Enter with
    # `nix develop ~/.config/nixos#<name>`, or from the project via a
    # locally-excluded .envrc containing `use flake ~/.config/nixos#<name>`.
    devShells.${system}.pact-demo = pkgs.mkShell {
      packages = with pkgs; [
        git
        openssh          # pact-python is a git+ssh dep from forgejo.abmac.io
        nodejs           # Hono server + web renderer; bundles npm/npx
        just             # task runner (Justfile)
        python3          # capture engine; pytest/pact-python land in a local .venv
        ruff
        cargo            # build ../pact-runtime's `lifecycle` example
        rustc
        gcc              # linker/cc for the Rust build
        pkg-config
      ];
      shellHook = ''
        echo "▶ pact-demo dev shell (from ~/.config/nixos)"
      '';
    };
  };
}
