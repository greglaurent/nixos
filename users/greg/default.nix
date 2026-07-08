{ osConfig, pkgs, ... }:
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
    ../../modules/home/typst.nix
    ../../modules/home/org.nix
    ../../modules/home/podman.nix
    ../../modules/home/packages.nix
    ./emacs.nix
    ../../modules/home/xdg.nix
    ../../modules/home/zsh.nix
    ./ssh.nix
    ./git.nix
    ./hosts/${host}.nix
  ];

  home.packages = with pkgs; [
    claude-code
  ];
}
