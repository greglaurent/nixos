# OBSBOT camera control (aaronsb/obsbot-camera-control, vendored in pkgs/).
# Machine-level, opt-in per host via `myObsbot.enable` (mirrors myGaming etc.).
# The package bundles a closed-source SDK, so it is unfree (allowUnfree is
# already set in system.nix).
{ config, lib, pkgs, ... }:
let
  cfg = config.myObsbot;
in
{
  options.myObsbot.enable = lib.mkEnableOption "OBSBOT camera control software";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.obsbot-camera-control ];

    # Camera control goes through the V4L2 device node (/dev/video*), which is
    # owned by the `video` group — greg is already a member (account.nix), so no
    # extra udev rules are needed. (The optional v4l2loopback "virtual camera"
    # feature is intentionally left out; ask if you want it wired up.)
  };
}
