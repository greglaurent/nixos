# RustDesk (remote desktop) as a single opt-in feature: `myRustdesk.enable`.
# RustDesk runs NATIVELY (nixpkgs rustdesk-flutter, see modules/home/rustdesk.nix)
# — the same Flutter build that works on Arch. This module provides the one
# SYSTEM-level prerequisite the home package can't set up itself:
#   * /dev/uinput — RustDesk injects keyboard/mouse into the niri session for
#     remote control (Wayland blocks synthetic input otherwise).
# Screen capture uses the plain ScreenCast portal, already provided by the niri
# desktop (xdg-desktop-portal-gnome). Enable per host with `myRustdesk.enable = true;`.
#
# (History: this used to pull in rootless podman for a distrobox container. That
# routed capture to the RemoteDesktop portal, which niri lacks — niri #390 — so
# it never worked. Native RustDesk uses ScreenCast, which niri supports.)
{ config, lib, ... }:
let
  cfg = config.myRustdesk;
in
{
  options.myRustdesk.enable = lib.mkEnableOption "RustDesk remote desktop (native)";

  config = lib.mkIf cfg.enable {
    # uinput: synthetic keyboard/mouse for remote *control* (Wayland blocks
    # injected input otherwise). Creates the `uinput` group + a udev rule
    # granting it 0660 on /dev/uinput; each configured user joins that group.
    hardware.uinput.enable = true;
    users.users = builtins.listToAttrs (map (name: {
      inherit name;
      value.extraGroups = [ "uinput" ];
    }) config.myUsers);
  };
}
