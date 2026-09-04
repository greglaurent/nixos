# Per-user command-line utilities.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gh
    just
    jq
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
