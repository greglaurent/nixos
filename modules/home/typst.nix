# Make locally-authored Typst libraries resolvable as `@local/<name>:<version>`.
# Typst looks up the @local namespace in
#   $XDG_DATA_HOME/typst/packages/local/<name>/<version>/
# We out-of-store-symlink that path to the live source under
# ~/Media/Documents/typst-libs, so the library stays editable in place (a
# regular home.file would copy it read-only into the nix store). tinymist (the
# LSP in Emacs) and the `typst` CLI both resolve @local this way, so this alone
# fixes `#import "@local/cascade:0.1.0"`.
{ config, ... }:
let
  libs = "${config.home.homeDirectory}/Media/Documents/typst-libs";
in
{
  xdg.dataFile."typst/packages/local/cascade/0.1.0".source =
    config.lib.file.mkOutOfStoreSymlink "${libs}/cascade";
}
