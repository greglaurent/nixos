# RustDesk (remote desktop) as a single opt-in feature: `myRustdesk.enable`.
# RustDesk runs NATIVELY (official rustdesk-bin overlay, see modules/home/rustdesk.nix)
# — the unattended-wayland build (DRM/KMS capture, no portal). This module provides the
# SYSTEM-level prerequisites the home package can't set up itself:
#   * the root `rustdesk --service` unit and the /usr/lib/rustdesk -> libdrmtap link
#   * /dev/uinput — RustDesk injects keyboard/mouse into the niri session for
#     remote control (Wayland blocks synthetic input otherwise).
# Capture needs no portal (DRM/KMS), which is why this works on niri; the stock build needs the
# RemoteDesktop portal niri lacks (niri #390). Enable per host with `myRustdesk.enable = true;`.
{ config, lib, pkgs, ... }:
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

    # DRM/KMS capture (unattended-wayland build). The deb ships a root systemd service that
    # runs `rustdesk --service`; it spawns the per-session server, which captures through
    # libdrmtap. RustDesk dlopens libdrmtap by the ABSOLUTE path /usr/lib/rustdesk/libdrmtap.so.0
    # (patching that string into librustdesk.so is not safe), so link that path to the package.
    systemd.tmpfiles.rules = [ "L+ /usr/lib/rustdesk - - - - ${pkgs.rustdesk-bin}/lib/rustdesk" ];
    systemd.services.rustdesk = {
      description = "RustDesk";
      wantedBy = [ "multi-user.target" ];
      requires = [ "network.target" ];
      after = [ "systemd-user-sessions.service" "network.target" ];
      path = [ pkgs.procps ];   # the upstream ExecStop uses pkill
      environment = {
        PULSE_LATENCY_MSEC = "60";
        PIPEWIRE_LATENCY = "1024/48000";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.rustdesk-bin}/bin/rustdesk --service";
        ExecStop = "${pkgs.procps}/bin/pkill -f \"rustdesk --\"";
        KillMode = "mixed";
        TimeoutStopSec = 30;
        User = "root";
        LimitNOFILE = 100000;
      };
    };
    users.users = builtins.listToAttrs (map (name: {
      inherit name;
      value.extraGroups = [ "uinput" ];
    }) config.myUsers);
  };
}
