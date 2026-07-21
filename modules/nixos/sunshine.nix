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

    # Input device access for the user-level Sunshine service:
    #   * uinput — services.sunshine sets hardware.uinput.enable (creating the
    #     `uinput` group + a 0660 udev rule on /dev/uinput) but does NOT join
    #     users to it; without membership Sunshine can't create virtual devices.
    #   * input — Sunshine's own udev rules (services.udev.packages, shipped by
    #     the module) grant /dev/uhid + controller access to the `input` group.
    #     Sunshine's docs: "If controllers are not detected, ensure the user is
    #     in the input group." Missing this causes flaky gamepad detection.
    users.users = builtins.listToAttrs (map (name: {
      inherit name;
      value.extraGroups = [ "uinput" "input" ];
    }) config.myUsers);
  };
}
