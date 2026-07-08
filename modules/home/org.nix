# Org/agenda data location — ONE configurable source of truth. Defaults to
# content/doom/org (under myDoomContentDir), so org lives in the authored-content
# half of the dots/content split: version-controlled, travelling with the config,
# but NOT a build input. Nothing hardcoded: derived from myDoomContentDir
# (emacs.nix) which derives from the standard myContentDir (paths.nix). Override
# `myOrgDir` to relocate it.
#
# The value is exported as $ORG_DIRECTORY and Emacs reads that
# (users/greg/dots/doom/config.el) — no path in the elisp. The dir plus the roam/
# and noter/ subdirs the doom config uses are created if missing.
{ config, lib, ... }:
{
  options.myOrgDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.myDoomContentDir}/org";
    example = "\${config.xdg.userDirs.documents}/org";
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
