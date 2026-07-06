# Greg's Doom Emacs (nix-doom-emacs-unstraightened). Config is per-user in
# ./doom and built into the package — reproducible, no `doom sync`.
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

  # Emacs daemon (user service), ordered after graphical-session.
  services.emacs = {
    enable = true;
    defaultEditor = false;  # keep nvim as $EDITOR for now; flip to emacs later
  };
}
