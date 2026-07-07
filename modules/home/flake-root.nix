# Generic path options for config that is authored at runtime and must stay
# writable AND version-controlled (Emacs config + snippets/templates/abbrevs/org).
# Nothing hardcoded — derived from the home dir and username. Override per
# user/host if a checkout lives elsewhere.
{ config, lib, ... }:
{
  options.myFlakeRoot = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.config/nixos";
    example = "/home/greg/dotfiles/nixos";
    description = "Absolute path to this user's writable checkout of the nixos flake.";
  };

  # The user's Doom folder in that checkout — the single home for their Emacs
  # config AND authored data (snippets, file-templates, abbrevs, org). Everything
  # Emacs-side derives from this; generic via `config.home.username`.
  options.myDoomDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.myFlakeRoot}/users/${config.home.username}/doom";
    description = "The user's Doom config + authored-data folder (users/<name>/doom).";
  };
}
