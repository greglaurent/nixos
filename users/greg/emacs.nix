{ config, pkgs, doom-emacs, ... }:
{
  imports = [ doom-emacs.homeModule ];

  programs.doom-emacs = {
    enable = true;
    doomDir = ./doom;
    doomLocalDir = "${config.home.homeDirectory}/.local/share/nix-doom";
    emacs = pkgs.emacs-pgtk;                        # native Wayland (niri)
    extraPackages = epkgs: [ epkgs.typst-ts-mode ];
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
}
