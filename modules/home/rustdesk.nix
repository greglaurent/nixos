# RustDesk (remote desktop), NATIVE — run directly on the host, the same way it
# works on Arch (Flutter build = nixpkgs rustdesk-flutter, matching Arch's
# rustdesk-bin). On niri it captures through the plain ScreenCast portal (approve
# the source picker once per connection) and injects input via /dev/uinput
# (enabled by modules/nixos/rustdesk.nix).
#
# We do NOT use distrobox anymore: running RustDesk in a container routed screen
# capture to the RemoteDesktop portal, which niri does not implement (niri #390),
# so capture always failed. Native RustDesk uses the plain ScreenCast portal,
# which niri DOES support (same path OBS uses).
{ lib, pkgs, osConfig, ... }:
lib.mkIf (osConfig.myRustdesk.enable or false) {
  home.packages = [ pkgs.rustdesk-flutter ];
}
