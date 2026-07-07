{ config, pkgs, doom-emacs, ... }:
{
  imports = [ doom-emacs.homeModule ];

  programs.doom-emacs = {
    enable = true;
    doomDir = ./doom;
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

  # Spell-checker for Doom's `:checkers spell` module (it prefers aspell; the
  # "can't find ispell" warning means no checker was on PATH). en-computers/
  # en-science extend coverage for code and technical prose.
  # Where the editable Doom source lives (a writable git checkout), so Emacs can
  # author snippets/file-templates straight into the flake — version-controlled,
  # not the read-only store. Derived from myFlakeRoot; no hardcoded path.
  home.sessionVariables.DOOM_SOURCE_DIR =
    "${config.myFlakeRoot}/users/${config.home.username}/doom";

  home.packages = with pkgs; [
    (aspellWithDicts (d: with d; [ en en-computers en-science ]))
  ];

  # Emacs daemon (user service), ordered after graphical-session.
  services.emacs = {
    enable = true;
    defaultEditor = false;  # keep nvim as $EDITOR for now; flip to emacs later
  };
}
