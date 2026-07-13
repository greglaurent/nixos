# Per-user command-line utilities.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gh
    just
    glances
    wget
    # (archive tools — unzip/zip/p7zip/rar/file-roller — live in apps.nix)
    wl-clipboard
    cliphist

    # Font metric tooling — reads x-height/cap-height/ascent from a font's OS/2
    # table (the designer's declared values) when tuning cascade font presets.
    # Provides the `ttx` / `fonttools` CLIs. (Scripted metric extraction uses an
    # ephemeral `nix-shell -p 'python3.withPackages …'` to avoid a python3 clash.)
    python3Packages.fonttools

    # Deno — the runtime + toolchain for the cascade-typeset repo (~/Documents):
    # runs the token generator/verifier, type-checks them (Node types built-in,
    # so no @types/node / node_modules), and serves the dev viewer.
    deno
  ];
}
