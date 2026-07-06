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

  # Laptop power management (integrates with DMS's power widget).
  services.power-profiles-daemon.enable = true;

  # Fingerprint reader — enrol with `fprintd-enroll`. Enabling this also wires
  # fingerprint auth into PAM (login/sudo/lock) by default.
  services.fprintd.enable = true;
}
