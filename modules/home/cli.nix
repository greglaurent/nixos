# Per-user command-line utilities.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gh
    glances
    wget
    unzip
    unrar
    wl-clipboard
    cliphist
  ];
}
