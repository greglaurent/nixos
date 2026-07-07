{ config, lib, pkgs, doom-emacs, ... }:
{
  imports = [ doom-emacs.homeModule ];

  programs.doom-emacs = {
    enable = true;
    # Build Doom from the config .el only. EXCLUDE the authored-data dirs so
    # editing a snippet / template / abbrev / org note is NOT a build input and
    # never triggers a Doom rebuild — they still live under users/<name>/doom/ in
    # the checkout and are read at runtime (via $DOOM_SOURCE_DIR / $ORG_DIRECTORY).
    doomDir = lib.fileset.toSource {
      root = ./doom;
      fileset = lib.fileset.difference ./doom (lib.fileset.unions [
        (lib.fileset.maybeMissing ./doom/org)
        (lib.fileset.maybeMissing ./doom/snippets)
        (lib.fileset.maybeMissing ./doom/file-templates)
        (lib.fileset.maybeMissing ./doom/abbrev_defs)
      ]);
    };
    doomLocalDir = "${config.home.homeDirectory}/.local/share/nix-doom";
    emacs = pkgs.emacs-pgtk;                        # native Wayland (niri)
    extraPackages = epkgs: [
      epkgs.typst-ts-mode
      # typst-ts-mode needs the typst tree-sitter grammar; without it the mode
      # errors during init (parser creation fails *before* mode hooks run), so
      # .typ buffers get no highlighting AND no wrapping. Shipping it here lands
      # libtree-sitter-typst.so on Emacs' treesit search path
      # (…-emacs-packages-deps/lib), which is what the "grammar unavailable"
      # error was looking for.
      (epkgs.treesit-grammars.with-grammars (g: [ g.tree-sitter-typst ]))
    ];
  };

  # The editable Doom source in the flake checkout (writable, version-controlled)
  # — where Emacs authors snippets/file-templates/abbrevs/org, read at runtime.
  # Single generic source of truth (myDoomDir); no hardcoded path or username.
  home.sessionVariables.DOOM_SOURCE_DIR = config.myDoomDir;

  # Spell-checker for Doom's `:checkers spell` module (it prefers aspell; the
  # "can't find ispell" warning means no checker was on PATH). en-computers/
  # en-science extend coverage for code and technical prose.
  home.packages = with pkgs; [
    (aspellWithDicts (d: with d; [ en en-computers en-science ]))
  ];

  # Emacs daemon (user service), ordered after graphical-session.
  services.emacs = {
    enable = true;
    defaultEditor = false;  # keep nvim as $EDITOR for now; flip to emacs later
  };
}
