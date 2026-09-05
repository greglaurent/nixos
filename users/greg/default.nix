{ osConfig, pkgs, config, typst-libs, cascade, ... }:
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
    ./emacs.nix
    ../../modules/home/xdg.nix
    ./xdg.nix                      # greg's overrides of the xdg defaults
    ../../modules/home/zsh.nix
    ./ssh.nix
    ./git.nix
    ./hosts/${host}.nix
    typst-libs.homeModules.default   # symlink typst-libs packages (press) into Typst's @local
    cascade.homeModules.default      # symlink cascade's generated dist/typst into @local
  ];

  home.packages = with pkgs; [
    claude-code
    rtk           # Rust Token Killer: compresses CLI output before it hits the agent's context
    cascade       # Org → CSS/Typst/LaTeX/EPUB typographic export (from the cascade flake)
  ];

  # Local Typst libraries → Typst's @local namespace, editable in place. press lives in the
  # typst-libs repo; cascade's generated Typst package (dist/typst) lives in the cascade repo,
  # linked by cascade's own flake module.
  myTypstLibsDir = "${config.home.homeDirectory}/Documents/typst-libs";
  myCascadeDir    = "${config.home.homeDirectory}/Workspace/cascade-typography-v2";
}
