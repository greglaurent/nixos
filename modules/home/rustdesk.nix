# RustDesk (remote desktop), NATIVE — run directly on the host (official Flutter binary,
# packaged by our rustdesk-bin overlay). This is the upstream *unattended-wayland* build:
# it captures the screen via DRM/KMS (libdrmtap) from a root service and injects input via
# /dev/uinput, so it needs NO screencast/remote-desktop portal. Both the service and uinput
# are set up by modules/nixos/rustdesk.nix. The stock build needs the RemoteDesktop portal,
# which niri does not implement (niri #390), so its capture fails on niri.
#
# Known upstream glitch: cursor position on fractional-scale outputs (rustdesk/rustdesk#15916).
{ lib, pkgs, osConfig, ... }:
lib.mkIf (osConfig.myRustdesk.enable or false) {
  # The official unattended-wayland build (pkgs/rustdesk-bin, flake overlay): captures via
  # DRM/KMS through the root service in modules/nixos/rustdesk.nix, no portal needed.
  # Self-updating alternative (stock build, needs the RemoteDesktop portal niri lacks):
  # pkgs.rustdesk-flutter via nixpkgs-unstable -- see the commented line in flake.nix.
  home.packages = [ pkgs.rustdesk-bin ];
}
