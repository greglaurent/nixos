{ config, lib, pkgs, doom-emacs, ... }:
{
  imports = [ doom-emacs.homeModule ];

  # Doom's two dirs under the dots/content standard (paths.nix). Both are per-app
  # override points, defaulting to the standard <root>/doom location:
  #   • config  -> dots/doom:    reproducible .el, the Doom build input.
  #   • content -> content/doom: authored, tracked, NOT built (snippets,
  #     file-templates, abbrevs, org). Editing it never triggers a rebuild.
  options.myDoomConfigDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.myDotsDir}/doom";
    description = "Reproducible Doom config (the .el build input); dots/doom.";
  };
  options.myDoomContentDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.myContentDir}/doom";
    description = "Authored, tracked-but-not-built Doom content; content/doom.";
  };

  config = {
    programs.doom-emacs = {
      enable = true;
      # doomDir is the reproducible dots/doom tree, whole and unfiltered. The
      # split is topological now, so there's nothing to exclude: authored content
      # physically lives in content/doom, a different tree that is never a build
      # input. Editing an .el here needs `home-manager switch'; editing content
      # does not.
      doomDir = ./dots/doom;
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

    # Emacs reads these at runtime (config.el) to route editing/authoring to the
    # writable checkout: $DOOM_CONFIG_DIR for the reproducible .el (dots/doom),
    # $DOOM_CONTENT_DIR for authored snippets/templates/abbrevs (content/doom).
    # No paths hardcoded in elisp.
    home.sessionVariables = {
      DOOM_CONFIG_DIR = config.myDoomConfigDir;
      DOOM_CONTENT_DIR = config.myDoomContentDir;
    };

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

    # THE daemon is a systemd USER service — it does NOT inherit
    # home.sessionVariables (those are sourced by interactive shells only). So a
    # rebuild alone leaves the running daemon on STALE paths: it keeps resolving
    # org-directory to the OLD location and re-seeding .agenda-files there every
    # time org loads, which is why deleting the folder + rebuilding didn't stop
    # it. Pin the paths on the unit itself so `systemctl --user restart emacs`
    # gives the daemon the correct DOOM_*/ORG_DIRECTORY values deterministically.
    systemd.user.services.emacs.Service.Environment = [
      "DOOM_CONFIG_DIR=${config.myDoomConfigDir}"
      "DOOM_CONTENT_DIR=${config.myDoomContentDir}"
      "ORG_DIRECTORY=${config.myOrgDir}"
    ];
  };
}
