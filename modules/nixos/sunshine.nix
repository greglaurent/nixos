# Sunshine — the game-streaming HOST (server) half. Pairs with Moonlight (the
# client, installed for greg in modules/home/apps.nix). Opt-in per host with
# `mySunshine.enable = true;`, mirroring myRustdesk. Enabled on both rhizome and
# plateau so either box can host a stream while the other plays it.
#
# What this wires up:
#   * services.sunshine — the host daemon (runs as a systemd *user* service).
#   * openFirewall — Sunshine's control/stream ports (47984-48010, TCP+UDP).
#   * capSysAdmin — CAP_SYS_ADMIN on the binary, required for KMS/DRM screen
#     capture, which is how Sunshine grabs the niri (Wayland) session.
#   * /dev/uinput — Sunshine injects a virtual gamepad/keyboard/mouse from the
#     client's input, same synthetic-input path RustDesk needs under Wayland.
#
# First run is interactive: open https://localhost:47990 on the HOST to set the
# admin user/PIN, then pair Moonlight to it. That pairing state is per-machine
# and lives outside the Nix store.
{ config, lib, ... }:
let
  cfg = config.mySunshine;
in
{
  options.mySunshine.enable = lib.mkEnableOption "Sunshine game-streaming host";

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      openFirewall = true;   # 47984-48010 TCP/UDP (HTTPS control + RTSP/video/audio/control)
      capSysAdmin = true;    # needed for KMS/DRM capture of the Wayland session
      autoStart = true;      # start the host service on login
    };

    # uinput: Sunshine emits synthetic gamepad/keyboard/mouse from the remote
    # client (Wayland blocks injected input otherwise). services.sunshine already
    # sets hardware.uinput.enable (which creates the `uinput` group + a 0660 udev
    # rule on /dev/uinput), but it does NOT join users to that group — so do that
    # here, otherwise the user-level Sunshine service can't open /dev/uinput.
    users.users = builtins.listToAttrs (map (name: {
      inherit name;
      value.extraGroups = [ "uinput" ];
    }) config.myUsers);
  };
}
