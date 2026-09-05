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

    # cascade typography (private): ships its own flake exposing the `cascade' CLI
    # (packaging + emacs/typst/tectonic/pandoc runtime deps live in that repo). git+ssh
    # uses greg's SSH key; re-lock (`nix flake update cascade`) + rebuild to pick up
    # pushed changes.
    cascade = {
      url = "git+ssh://git@github.com/greglaurent/cascade-typography";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # local Typst libraries (press, …): a flake whose home-manager module symlinks each
    # package into Typst's @local namespace, editable in place. git+ssh, private.
    typst-libs = {
      url = "git+ssh://git@github.com/greglaurent/typst-libs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, dms, doom-emacs, nixos-hardware, zen-browser, claude-desktop, cascade, typst-libs, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    hosts = [ "rhizome" "plateau" ];
    flakePkgs = final: prev: {
      zen-browser = zen-browser.packages.${system}.default;
      claude-desktop = claude-desktop.packages.${system}.claude-desktop-fhs;
      obsbot-camera-control = final.callPackage ./pkgs/obsbot-camera-control { };
      rustdesk-bin = final.callPackage ./pkgs/rustdesk-bin { };   # official 1.4.9 binary, patched for NixOS
      cascade = cascade.packages.${system}.default;               # Org→CSS/Typst/LaTeX/EPUB CLI (own flake)
    };

    mkHost = host: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit home-manager dms doom-emacs nixos-hardware typst-libs cascade; };
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
