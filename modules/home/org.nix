# Org/agenda data location — ONE configurable source of truth, fully generic.
# Defaults to users/<name>/doom/org (under myDoomDir), so all of Emacs's authored
# data lives under one folder in the writable git checkout — version-controlled
# and travelling with the config. Nothing hardcoded: derived from myDoomDir
# (myFlakeRoot + config.home.username). Override `myOrgDir` to relocate it.
#
# The value is exported as $ORG_DIRECTORY and Emacs reads that
# (users/greg/doom/config.el) — no path in the elisp. The dir plus the roam/ and
# noter/ subdirs the doom config uses are created if missing.
{ config, lib, ... }:
{
  options.myOrgDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.myDoomDir}/org";
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
