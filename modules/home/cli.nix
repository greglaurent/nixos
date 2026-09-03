# Per-user command-line utilities.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gh
    just
    gnumake
    glances
    wget
    clang
    wl-clipboard
    cliphist
    python3Packages.fonttools
    deno
  ];
}
