# direnv + nix-direnv: auto-load a project's flake devShell on `cd` into it
# (drop a `.envrc` containing `use flake` in the project). nix-direnv makes the
# load fast and cached, and hooks into zsh automatically.
{ ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
