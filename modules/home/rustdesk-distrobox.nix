# RustDesk via distrobox. The native builds (nixpkgs source AND upstream
# AppImage) crash on niri from glibc/gdk-pixbuf ABI mismatches, so run RustDesk
# in an Ubuntu container with its native libraries. Uses the rootless podman
# from modules/home/podman.nix.
#
# Two host-integration problems this solves:
#  1. Env leak: the host's nixpkgs GTK/gio/pixbuf env would make Ubuntu load host
#     nixpkgs modules (glibc mismatch). The `rustdesk` wrapper strips those vars
#     so the container uses its own Ubuntu libs. Display/D-Bus/$XDG_RUNTIME_DIR
#     are kept, so it still captures/controls niri via the host portal + uinput.
#  2. Account sign-in links (Google OAuth) must open on the HOST. RustDesk is a
#     Flutter app: it opens URLs through GIO (g_app_info_launch_default_for_uri),
#     which reads the shared ~/.config/mimeapps.list (https -> the host default
#     browser's desktop-id) and launches that .desktop from the container's app
#     registry. So we install, inside the container:
#       * /usr/local/bin/xdg-open  -> a python3-dbus shim that calls the HOST
#         xdg-desktop-portal OpenURI over the session bus exposed at /run/host
#         (distrobox-host-exec/host-spawn silently no-ops on NixOS, see #1198;
#         the portal route is distrobox #1984).
#       * /usr/share/applications/<host-default-browser>.desktop -> a GIO https
#         handler whose Exec runs that shim, named after the host default so
#         GIO's mimeapps lookup resolves to it.
#     rustdesk-integrate.sh wires both up; init_hooks runs it at build and the
#     wrapper re-runs it (idempotent) at launch.
#
# `rustdesk` on your PATH is the only command needed — it creates the container
# on first run (needs network), wires up host integration, and launches.
{ config, pkgs, lib, osConfig, ... }:
let
  home = config.home.homeDirectory;
  rustdesk = pkgs.writeShellScriptBin "rustdesk" ''
    # 1. Create the container on a clean system (idempotent; needs network).
    if ! distrobox list | grep -qw rustdesk; then
      echo "rustdesk: first run — building container (needs network)…" >&2
      distrobox assemble create --file "$HOME/.config/distrobox/rustdesk.ini"
    fi

    # 2. Wire up host-browser URL opening (shim + GIO handler). Idempotent, so it
    #    also heals an older container and tracks default-browser changes.
    distrobox enter rustdesk -- sudo sh \
      "$HOME/.config/distrobox/rustdesk-integrate.sh" "$HOME" >/dev/null 2>&1 || true

    # 3. Launch. Strip host nixpkgs GTK/gio/loader vars so Ubuntu uses its own,
    #    and point RustDesk's session bus at the HOST bus (exposed under /run/host
    #    with init=true) so it reaches the host xdg-desktop-portal — needed for
    #    the ScreenCast/RemoteDesktop portal calls RustDesk makes on connect.
    hostbus="unix:path=/run/host/run/user/$(id -u)/bus"
    exec distrobox enter rustdesk -- env \
      -u GIO_MODULE_DIR -u GIO_EXTRA_MODULES -u GDK_PIXBUF_MODULE_FILE \
      -u GDK_PIXBUF_MODULEDIR -u GTK_PATH -u GTK_EXE_PREFIX \
      -u GTK_IM_MODULE_FILE -u GSETTINGS_SCHEMA_DIR -u LD_LIBRARY_PATH \
      XDG_DATA_DIRS=/usr/local/share:/usr/share \
      DBUS_SESSION_BUS_ADDRESS="$hostbus" \
      rustdesk "$@"
  '';
in
# Active only where the host turns on RustDesk (modules/nixos/rustdesk.nix);
# inert everywhere else, so greg's home config is identical across all hosts.
lib.mkIf (osConfig.myRustdesk.enable or false) {
  home.packages = [ pkgs.distrobox rustdesk ];

  # Menu entry launches the sanitised wrapper, not the container's own .desktop.
  xdg.dataFile."applications/rustdesk.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=RustDesk
    Comment=Remote desktop (distrobox)
    Exec=rustdesk
    Icon=rustdesk
    Terminal=false
    Categories=Network;RemoteAccess;
  '';

  # Portal shim: installed as /usr/local/bin/xdg-open inside the container.
  xdg.configFile."distrobox/host-xdg-open" = {
    executable = true;
    text = ''
      #!/usr/bin/python3
      # Open URLs through the HOST desktop portal. init=true gives the container
      # its own /run/user/UID/bus (no portal); the HOST bus is exposed under
      # /run/host per distrobox useful_tips, so prefer that.
      import sys, os, dbus

      uid = os.getuid()
      for path in (f"/run/host/run/user/{uid}/bus", f"/run/user/{uid}/bus"):
          if os.path.exists(path):
              os.environ["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path={path}"
              break

      url = sys.argv[-1] if len(sys.argv) > 1 else ""
      bus = dbus.SessionBus()
      obj = bus.get_object("org.freedesktop.portal.Desktop", "/org/freedesktop/portal/desktop")
      iface = dbus.Interface(obj, "org.freedesktop.portal.OpenURI")
      iface.OpenURI("", url, dbus.Dictionary({}, signature="sv"))
    '';
  };

  # GIO https handler shipped into the container; Exec runs the portal shim.
  xdg.configFile."distrobox/host-url-forwarder.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Open on host
    Comment=Forward URLs to the host browser via the desktop portal
    Exec=/usr/local/bin/xdg-open %u
    MimeType=x-scheme-handler/http;x-scheme-handler/https;
    Terminal=false
    NoDisplay=true
  '';

  # Container-side wiring (runs inside the container as root). Shipped as a real
  # script so init_hooks and the launcher can both call it without shell-quoting
  # it through the .ini / nix strings.
  xdg.configFile."distrobox/rustdesk-integrate.sh" = {
    executable = true;
    text = ''
      #!/bin/sh
      # Wire up host-browser URL opening for RustDesk inside the container.
      # Idempotent. Arg 1 = host home directory.
      set -e
      home="''${1:-$HOME}"
      cfg="$home/.config/distrobox"

      install -Dm755 "$cfg/host-xdg-open" /usr/local/bin/xdg-open

      # Name the GIO handler after the HOST default browser so the shared
      # ~/.config/mimeapps.list (https=<id>) resolves to it.
      handler=$(sed -n 's#^x-scheme-handler/https=##p' "$home/.config/mimeapps.list" 2>/dev/null | head -1 | cut -d';' -f1)
      : "''${handler:=vivaldi-stable.desktop}"
      install -Dm644 "$cfg/host-url-forwarder.desktop" "/usr/share/applications/$handler"

      update-desktop-database /usr/share/applications 2>/dev/null || true
    '';
  };

  # Container build steps (init_hooks). Shipped as a script to avoid quoting a
  # long chain through the .ini. Runs as root at `distrobox assemble create`.
  xdg.configFile."distrobox/rustdesk-build.sh" = {
    executable = true;
    text = ''
      #!/bin/sh
      # Build the RustDesk container. Arg 1 = host home directory.
      set -e
      home="''${1:-$HOME}"

      # RustDesk itself.
      wget -qO /tmp/rustdesk.deb "https://github.com/rustdesk/rustdesk/releases/download/1.4.9/rustdesk-1.4.9-x86_64.deb"
      apt-get install -y /tmp/rustdesk.deb

      # Ubuntu 22.04 ships libpipewire 0.3.48 — too old for RustDesk Wayland
      # screen capture ("upgrade the PipeWire library", rustdesk #8600). Pull the
      # upstream client libs so it can talk to the host's modern pipewire daemon.
      add-apt-repository -y ppa:pipewire-debian/pipewire-upstream
      apt-get update
      apt-get install -y libpipewire-0.3-0 libpipewire-0.3-modules libspa-0.2-modules

      # Host-browser URL integration (portal shim + GIO https handler).
      sh "$home/.config/distrobox/rustdesk-integrate.sh" "$home"
    '';
  };

  xdg.configFile."distrobox/rustdesk.ini".text = ''
    [rustdesk]
    image=ubuntu:22.04
    init=true
    additional_packages=wget desktop-file-utils python3 python3-dbus software-properties-common
    init_hooks=sh ${home}/.config/distrobox/rustdesk-build.sh ${home} || true
  '';
}
