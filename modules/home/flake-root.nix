# Absolute path to this user's WRITABLE checkout of the nixos flake. Needed for
# config that is authored at runtime and must stay writable AND version-
# controlled — snippets and file-templates written from inside Emacs land in the
# checkout, not the read-only /nix/store and not a throwaway ~/.local dir.
#
# It can't be derived from the flake at eval time (that's the store copy), so it
# must be declared. Defaults to the ~/.config/nixos convention; override per
# user/host if a checkout lives elsewhere.
{ config, lib, ... }:
{
  options.myFlakeRoot = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.config/nixos";
    example = "/home/greg/dotfiles/nixos";
    description = "Absolute path to this user's writable checkout of the nixos flake.";
  };
}
