# RustDesk via distrobox. The native builds (nixpkgs source AND upstream
# AppImage) crash on niri from glibc/gdk-pixbuf ABI mismatches, so run RustDesk
# in an Ubuntu container with its native libraries. Uses the rootless podman
# from modules/home/podman.nix.
#
# Two integration problems this solves:
#  1. The host's nixpkgs GTK/gio/xdg env leaks into Ubuntu and makes it load host
#     nixpkgs modules (glibc mismatch) + a host-only browser .desktop — breaking
#     icons and URL opening. The `rustdesk` wrapper strips those vars so the
#     container uses its OWN Ubuntu resources. Display/D-Bus/$XDG_RUNTIME_DIR are
#     kept, so it still captures/controls niri via the host portal + /dev/uinput.
#  2. Clicking a link (account sign-in) failed: the container has no browser, and
#     the shared mimeapps points https -> vivaldi-stable.desktop which doesn't
#     exist in Ubuntu. We drop a vivaldi-stable.desktop into the container that
#     forwards URLs to the HOST browser via `distrobox-host-exec xdg-open`.
#
# Setup after `nixos-rebuild switch` (needs network):
#   distrobox rm -f rustdesk 2>/dev/null
#   distrobox assemble create --file ~/.config/distrobox/rustdesk.ini
#   rustdesk        # (or launch "RustDesk" from the menu)
{ config, pkgs, ... }:
let
  rustdesk = pkgs.writeShellScriptBin "rustdesk" ''
    exec distrobox enter rustdesk -- env \
      -u GIO_MODULE_DIR -u GIO_EXTRA_MODULES -u GDK_PIXBUF_MODULE_FILE \
      -u GDK_PIXBUF_MODULEDIR -u GTK_PATH -u GTK_EXE_PREFIX \
      -u GTK_IM_MODULE_FILE -u GSETTINGS_SCHEMA_DIR -u LD_LIBRARY_PATH \
      XDG_DATA_DIRS=/usr/local/share:/usr/share \
      rustdesk "$@"
  '';
in
{
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

  # The URL forwarder shipped as a real file (NOT inline in the .ini — its
  # "[Desktop Entry]" header would be misparsed as an ini section). init_hooks
  # copies it into the container as the https handler the mimeapps expects.
  xdg.configFile."distrobox/rustdesk-url-forwarder.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Open on host
    Exec=distrobox-host-exec xdg-open %u
    MimeType=x-scheme-handler/http;x-scheme-handler/https;
    Terminal=false
    NoDisplay=true
  '';

  xdg.configFile."distrobox/rustdesk.ini".text = ''
    [rustdesk]
    image=ubuntu:22.04
    init=true
    additional_packages=wget desktop-file-utils
    init_hooks=wget -qO /tmp/rustdesk.deb "https://github.com/rustdesk/rustdesk/releases/download/1.4.9/rustdesk-1.4.9-x86_64.deb" && apt-get install -y /tmp/rustdesk.deb && install -Dm644 ${config.home.homeDirectory}/.config/distrobox/rustdesk-url-forwarder.desktop /usr/share/applications/vivaldi-stable.desktop && update-desktop-database /usr/share/applications 2>/dev/null || true
  '';
}
