# RustDesk (remote desktop) as a single opt-in feature: `myRustdesk.enable`.
# RustDesk runs in a distrobox container (modules/home/rustdesk-distrobox.nix)
# because the native builds crash on niri. That home-manager launcher can't turn
# on the SYSTEM prerequisites itself, so this module bundles them behind one
# switch:
#   * rootless podman  — the container runtime (pulls in myPodman + subuid)
#   * /dev/uinput      — RustDesk injects keyboard/mouse into the niri session
# The home half activates automatically off `osConfig.myRustdesk.enable`, so you
# can never end up with the launcher present but the runtime missing (which is
# what silently broke rhizome). Screen capture uses the desktop portal already
# provided by the niri desktop. Enable per host with `myRustdesk.enable = true;`.
{ config, lib, ... }:
let
  cfg = config.myRustdesk;
in
{
  options.myRustdesk.enable = lib.mkEnableOption "RustDesk remote desktop (distrobox)";

  config = lib.mkIf cfg.enable {
    myPodman.enable = true;          # container runtime + per-user subuid ranges

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
