# Generic path roots for the flake checkout, and the dots/content/seed standard
# built on them. The checkout is a writable, version-controlled tree; per-app
# files split by LIFECYCLE — a file's location tells you how it's written and
# whether it's tracked:
#
#   • dots/<app>    — REPRODUCIBLE config: Nix, or manual files that must exist
#     verbatim and ARE build inputs, symlinked read-only (e.g. dots/doom's .el).
#   • content/<app> — AUTHORED content: you write it, it's tracked back, ships
#     WITH the config but is never a build input (e.g. org, snippets).
#   • seed/<app>    — SEED defaults: the repo ships an initial copy, but the app
#     OWNS and mutates it at runtime (copied writable, seeded only-if-missing,
#     never tracked back) (e.g. niri's dms/*.kdl → seed/niri/dms).
#
# The relation between an app's parts is the shared <app> segment
# (dots/doom ↔ content/doom; dots/niri ↔ seed/niri).
#
# The standard applies at TWO scopes, matching the module layers:
#   • system scope — dots/, content/, seed/ at the repo ROOT, consumed by
#     modules/nixos (e.g. niri, a desktop-level config).
#   • user scope   — users/<name>/{dots,content,seed}, consumed by home-manager.
# This module defines the USER-scope roots as options (below); the system-scope
# dirs are referenced by relative path from modules/nixos (a single consumer, so
# no option needed yet). A user-scope seed root can be added the same way as
# myDotsDir/myContentDir if/when a user app needs one. These are DEFAULTS —
# override here, or an app overrides its own derived dir in its own module.
{ config, lib, ... }:
{
  options.myFlakeRoot = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.config/nixos";
    example = "/home/greg/dotfiles/nixos";
    description = "Absolute path to this user's writable checkout of the nixos flake.";
  };

  # This user's subtree in the checkout — the root the dots/content standard
  # hangs off of. Generic via `config.home.username`.
  options.myUserDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.myFlakeRoot}/users/${config.home.username}";
    description = "This user's subtree in the flake checkout (users/<name>).";
  };

  # Reproducible per-app config root. Each app lives at ${myDotsDir}/<app>.
  options.myDotsDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.myUserDir}/dots";
    description = "Root of reproducible per-app config (users/<name>/dots).";
  };

  # Authored, tracked-but-not-built content root. Each app's content lives at
  # ${myContentDir}/<app>, paralleling its dots/<app> config.
  options.myContentDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.myUserDir}/content";
    description = "Root of authored, tracked-but-not-reproducible content (users/<name>/content).";
  };
}
