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

  # marginalia's source-document libraries (the reading-notes tool): the folders its
  # notes resolve books from, by content hash. A LIST — books may live in several
  # unrelated roots. Default sits inside the org tree; override to where books actually
  # live. Exported as $MARGINALIA_LIBRARY_DIRS (colon-joined), read by the doom config
  # into `marginalia-library-dirs' — so the path is defined ONCE, here.
  options.myMarginaliaLibrary = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ "${config.myOrgDir}/library" ];
    example = [ "\${config.home.homeDirectory}/Media/Books" ];
    description = "Book/source libraries marginalia resolves by content hash. Exported as $MARGINALIA_LIBRARY_DIRS.";
  };

  config = {
    home.sessionVariables.ORG_DIRECTORY = config.myOrgDir;
    home.sessionVariables.MARGINALIA_LIBRARY_DIRS =
      lib.concatStringsSep ":" config.myMarginaliaLibrary;

    home.activation.ensureOrgDir =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${lib.escapeShellArg "${config.myOrgDir}/roam"} \
                     ${lib.escapeShellArg "${config.myOrgDir}/noter"}
      '';

    # Book roots are the ONE thing that may sit outside org (and aren't standard XDG
    # dirs), so create them explicitly from the same option that feeds the env var.
    home.activation.ensureMarginaliaLibrary =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${lib.escapeShellArgs config.myMarginaliaLibrary}
      '';
  };
}
