{ config, lib, pkgs, dms, ... }:
{
  imports = [
    dms.nixosModules.greeter
  ];

  config = lib.mkIf (config.myDesktop.environment == "niri") {
    programs.niri.enable = true;

    services.upower.enable = true;
    services.accounts-daemon.enable = true;
    # gvfs: trash, mounts, network — Nautilus is inert without it.
    services.gvfs.enable = true;
    # GTK apps (Nautilus) + gsettings backing store.
    programs.dconf.enable = true;
    # DankSearch: launcher file search (type "/" in the DMS launcher). nixpkgs module.
    programs.dsearch.enable = true;
    # External-monitor brightness for the DMS brightness widget (ddcutil/i2c).
    # The native dms-shell module defaults this on; our flake wiring doesn't.
    hardware.i2c.enable = true;
    # X11-only apps under niri. niri 26.04 manages xwayland-satellite natively
    # via the `xwayland-satellite` node in config.kdl (PATH lookup); this puts
    # the binary on PATH for it.
    environment.systemPackages = [ pkgs.xwayland-satellite ];

    programs.dank-material-shell.greeter = {
      enable = true;
      compositor.name = "niri";
    };

    home-manager.sharedModules = [
      dms.homeModules.dank-material-shell
      ({ lib, pkgs, ... }: {
        programs.dank-material-shell = {
          enable = true;
          systemd.enable = true;
        };

        # DMS (a Qt6 app) resolves app-launcher icons through Qt's platform
        # theme, which must be exposed to the systemd-launched dms user service
        # — the niri `environment {}` block only reaches niri-spawned processes,
        # not dms.service. dankinstall writes this to environment.d; we mirror
        # it. Both QT_QPA_PLATFORMTHEME and its Qt6-specific variant are needed;
        # with gtk3 selected DMS reads the theme from gtk-3.0/settings.ini, which
        # gtk.iconTheme generates below. Without these, the launcher grid is blank.
        xdg.configFile."environment.d/90-dms.conf".text = ''
          QT_QPA_PLATFORMTHEME=gtk3
          QT_QPA_PLATFORMTHEME_QT6=gtk3
        '';
        gtk = {
          enable = true;
          iconTheme = {
            name = "Papirus-Dark";      # DMS docs' top recommendation
            package = pkgs.papirus-icon-theme;
          };
        };
        home.packages = with pkgs; [
          adwaita-icon-theme            # fallback coverage (DMS docs troubleshooting)
          hicolor-icon-theme
          nautilus                      # DMS's window-rules target org.gnome.Nautilus
        ];

        xdg.configFile."niri/config.kdl".source = ../../../dots/niri/config.kdl;
        # Seed the dms/*.kdl includes from the repo so a fresh machine boots
        # with a valid config. COPY (not symlink) and make writable, so DMS
        # still owns/regenerates them at runtime. Only seed missing files —
        # never clobber DMS's live versions on an existing machine.
        home.activation.seedNiriDmsIncludes =
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run mkdir -p "$HOME/.config/niri/dms"
            for f in ${../../../dots/niri/dms}/*.kdl; do
              dest="$HOME/.config/niri/dms/$(basename "$f")"
              if [ ! -e "$dest" ]; then
                run cp "$f" "$dest"
                run chmod u+w "$dest"
              fi
            done
          '';
      })
    ];
  };
}
