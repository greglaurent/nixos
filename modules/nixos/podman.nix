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

    # Rootless containers need subordinate uid/gid ranges in /etc/subuid and
    # /etc/subgid. `autoSubUidGidRange = true` did NOT populate them here
    # (subUidRanges stayed empty, so /etc/subuid was never generated and podman
    # wedged with "cannot re-exec process to join the existing user namespace").
    # Allocate explicit, non-overlapping 65536-wide ranges per user instead.
    users.users = builtins.listToAttrs (lib.imap0 (i: name: {
      inherit name;
      value = {
        subUidRanges = [{ startUid = 100000 + i * 65536; count = 65536; }];
        subGidRanges = [{ startGid = 100000 + i * 65536; count = 65536; }];
      };
    }) config.myUsers);
  };
}
