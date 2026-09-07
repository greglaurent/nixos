{ osConfig, pkgs, typst-libs, cascade, ... }:
let
  host = osConfig.networking.hostName;
in {
  imports = [
    ../../modules/home/fonts.nix
    ../../modules/home/apps.nix
    ../../modules/home/cli.nix
    ../../modules/home/direnv.nix
    ../../modules/home/paths.nix
    ../../modules/home/kitty.nix
    ../../modules/home/org.nix
    ../../modules/home/rustdesk.nix
    ../../modules/home/podman.nix
    ../../modules/home/packages.nix
    ../../modules/home/agenix.nix    # opt in: warn (at activation) if the master identity is missing
    ./emacs.nix
    ../../modules/home/xdg.nix
    ./xdg.nix                      # greg's overrides of the xdg defaults
    ../../modules/home/zsh.nix
    ./ssh.nix
    ./git.nix
    ./hosts/${host}.nix
    typst-libs.homeModules.default   # symlink typst-libs packages (press) into Typst's @local
    cascade.homeModules.default      # @local/cascade from the flake's built typst-assets + font provisioning
    ./typst-workspaces.nix           # dir source-of-truth + clone-if-missing bootstrap for both
  ];

  home.packages = with pkgs; [
    claude-code
    rtk           # Rust Token Killer: compresses CLI output before it hits the agent's context
    pkgs.cascade  # Org → CSS/Typst/LaTeX/EPUB typographic export (explicit: bare `cascade` is the flake-input arg)
  ];
}
