# Rootless podman with docker compatibility. Machine-level, opt-in per host via
# `myPodman.enable = true;` (mirrors myGaming/myDesktop). The rootless per-user
# API socket + DOCKER_HOST live in modules/home/podman.nix, gated on this being
# enabled (detected through osConfig), so they never activate on a host without
# podman.
{ config, lib, ... }:
let
  cfg = config.myPodman;
in
{
  options.myPodman.enable = lib.mkEnableOption "rootless podman with docker compatibility";

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;                          # `docker` -> podman shim
      defaultNetwork.settings.dns_enabled = true;   # inter-container DNS (compose)
      autoPrune.enable = true;
    };

    # Rootless containers need a subordinate uid/gid range per user.
    users.users = lib.genAttrs config.myUsers (_: { autoSubUidGidRange = true; });
  };
}
