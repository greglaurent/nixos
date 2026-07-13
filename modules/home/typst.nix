# Make locally-authored Typst libraries resolvable as `@local/<name>:<version>`.
# Typst looks up the @local namespace in
#   $XDG_DATA_HOME/typst/packages/local/<name>/<version>/
# We out-of-store-symlink that path to the live library source in the
# cascade-typeset project (under the PROJECTS xdg dir, ~/Workspace — tracked via
# config.xdg.userDirs.extraConfig.PROJECTS, not hardcoded), keeping it editable
# in place: a plain home.file would copy it read-only into the nix store.
# tinymist (Emacs LSP) and the `typst` CLI both resolve @local this way, so this
# fixes `#import "@local/cascade:0.1.0"`.
#
# This is the nix equivalent of the project's `just link' dev helper — you do NOT
# need to run that on this machine. `force = true' lets home-manager reclaim the
# symlink if `just link' (or a stale copy) ever created a foreign one at this
# path; both point at the SAME target, so it's idempotent and activation never
# fails on a "would be clobbered" collision again.
{ config, ... }:
let
  cascade = "${config.xdg.userDirs.extraConfig.PROJECTS}/cascade-typeset/cascade-typst";
in
{
  xdg.dataFile."typst/packages/local/cascade/0.1.0" = {
    source = config.lib.file.mkOutOfStoreSymlink cascade;
    force = true;
  };
}
