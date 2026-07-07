# Org/agenda data location — ONE configurable source of truth, derived from your
# XDG config. Defaults to <xdg documents>/org, so it respects xdg.userDirs
# (modules/home/xdg.nix) and the Documents parent is already created there.
# Override `myOrgDir` per user/host to relocate it anywhere — a synced repo, a
# flake checkout for version control, whatever.
#
# The value is exported as $ORG_DIRECTORY and Emacs reads that (users/greg/doom/
# config.el) — no path is hardcoded in the elisp. The dir plus the roam/ and
# noter/ subdirs the doom config uses are created if missing.
{ config, lib, ... }:
{
  options.myOrgDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.xdg.userDirs.documents}/org";
    example = "/home/greg/Workspace/org";
    description = "Directory holding org-mode / agenda files. Exported as $ORG_DIRECTORY.";
  };

  config = {
    home.sessionVariables.ORG_DIRECTORY = config.myOrgDir;

    home.activation.ensureOrgDir =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${lib.escapeShellArg "${config.myOrgDir}/roam"} \
                     ${lib.escapeShellArg "${config.myOrgDir}/noter"}
      '';
  };
}
