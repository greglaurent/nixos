{ home-manager, nixos-hardware, ... }:
{
  imports = [
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.framework-13-7040-amd
    ../../modules/nixos
    home-manager.nixosModules.home-manager
  ];

  # ── Facts unique to this machine ──
  networking.hostName = "rhizome";
  system.stateVersion = "26.05";

  boot.initrd.luks.devices."luks-49f5b87d-2b0f-4548-8bbd-3bf878e0f92d".device =
    "/dev/disk/by-uuid/49f5b87d-2b0f-4548-8bbd-3bf878e0f92d";

  # This machine's choices (override the global defaults just by stating them)
  myDesktop.environment = "niri";
  myUsers = [ "greg" ];
  myGaming.enable = true;          # Steam + gamescope session + gamemode
  myPodman.enable = true;          # rootless podman + docker compatibility
  myRustdesk.enable = true;        # remote desktop (native) — provides uinput
  mySunshine.enable = true;        # game-streaming host (pairs with Moonlight)

  # Laptop power management (integrates with DMS's power widget).
  services.power-profiles-daemon.enable = true;

  # sched-ext userspace scheduler (CachyOS-style scheduling on the stock kernel;
  # linuxPackages_latest carries sched_ext, mainline since 6.12). Per-host on
  # purpose — the right scheduler is hardware/workload-specific. scx_lavd is
  # latency/laptop-tuned. Reversible: drop it to fall back to kernel EEVDF.
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  # Fingerprint reader — enrol with `fprintd-enroll`. Enabling this also wires
  # fingerprint auth into PAM (login/sudo/lock) by default.
  services.fprintd.enable = true;
}
