# Make locally-authored Typst libraries resolvable as `@local/<name>:<version>`.
# Typst looks up the @local namespace in
#   $XDG_DATA_HOME/typst/packages/local/<name>/<version>/
# We out-of-store-symlink that path to the live source under the XDG Documents dir
# (config.xdg.userDirs.documents — so this tracks that setting instead of hardcoding
# a path), keeping the library editable in place: a regular home.file would copy it
# read-only into the nix store. tinymist (the LSP in Emacs) and the `typst` CLI both
# resolve @local this way, so this alone fixes `#import "@local/cascade:0.1.0"`. This
# replaces the manual `just link` — do not run that on this machine, it would clobber
# this symlink and fail activation.
{ config, ... }:
let
  cascade = "${config.xdg.userDirs.documents}/cascade-typeset/cascade-typst";
in
{
  xdg.dataFile."typst/packages/local/cascade/0.1.0".source =
    config.lib.file.mkOutOfStoreSymlink cascade;
}
