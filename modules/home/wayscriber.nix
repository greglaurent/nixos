# Wayscriber (ZoomIt-like on-screen annotation/zoom for Wayland). The package
# itself is installed in modules/home/apps.nix; this module declares the daemon
# unit and whether the session starts it.
#
# There was previously a HAND-WRITTEN ~/.config/systemd/user/wayscriber.service
# here, outside Nix, with the store path baked into ExecStart. When the package
# was rebuilt the old path was garbage-collected and the unit hit 203/EXEC on
# every start; Restart=on-failure + RestartSec=5 then looped it every ~5s
# indefinitely (it reached 2962 restarts). Declaring it here keeps ExecStart
# pinned to whatever ${pkgs.wayscriber} currently is, so a rebuild can't strand it.
#
# Autostart is OFF by default — flip it in Nix, not with `systemctl --user enable`,
# so the wants symlink stays owned by home-manager:
#   myWayscriber.autostart = true;   (e.g. in users/greg/hosts/<host>.nix)
{ config, lib, pkgs, ... }:
let
  cfg = config.myWayscriber;
in {
  options.myWayscriber.autostart = lib.mkEnableOption
    "starting the wayscriber daemon with the graphical session";

  config.systemd.user.services.wayscriber = {
    Unit = {
      Description = "Wayscriber - Screen annotation tool for Wayland";
      Documentation = "https://wayscriber.com";
      # Tie its lifetime to the graphical session so it dies with the session.
      PartOf = "graphical-session.target";
      After = "graphical-session.target";
    };
    Service = {
      Type = "simple";
      # Refuse to start outside a Wayland session rather than crash-looping.
      ExecStartPre = ''${pkgs.bash}/bin/sh -c '[ -n "$WAYLAND_DISPLAY" ] && [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]' '';
      ExecStart = "${pkgs.wayscriber}/bin/wayscriber --daemon";
      Restart = "on-failure";
      RestartSec = 5;
      # 75 (EX_TEMPFAIL) is wayscriber's "already running / nothing to do" exit.
      SuccessExitStatus = 75;
      RestartPreventExitStatus = 75;
    };
    # Empty when autostart is off: home-manager then owns the absence of the
    # graphical-session.target.wants symlink, the same way it owns its presence.
    Install.WantedBy = lib.optionals cfg.autostart [ "graphical-session.target" ];
  };

  # The package ships ONLY bin/wayscriber -- no .desktop file and no icon. That
  # is why it never showed up in the Meta+Space launcher, and why DMS logs
  # `Could not load icon "wayscriber"` (the tray item supplies its own pixmap,
  # so the tray still renders). Declare the entry here rather than dropping a
  # file into ~/.local/share/applications by hand.
  config.xdg.desktopEntries.wayscriber = {
    name = "Wayscriber";
    genericName = "Screen Annotation";
    comment = "On-screen annotation and zoom overlay for Wayland";
    # Starts the daemon (tray + the Mod+D binds in dots/niri/binds.kdl need it
    # running). --active would only throw up a one-shot overlay, leaving those
    # binds with nothing to talk to.
    exec = "${pkgs.wayscriber}/bin/wayscriber --daemon";
    # No icon ships with the package; input-tablet is Adwaita's scalable stand-in.
    icon = "input-tablet";
    terminal = false;
    categories = [ "Utility" "Graphics" ];
    settings.Keywords = "annotate;draw;zoom;screen;overlay;";
  };
}
