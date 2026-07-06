{ nixos-hardware, home-manager, ... }:
{
  imports = [
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.common-cpu-amd     # AMD microcode + common tweaks
    ../../modules/nixos
    home-manager.nixosModules.home-manager
  ];

  # ── Facts unique to this machine ──
  networking.hostName = "plateau";
  system.stateVersion = "26.05";

  # LUKS root. REPLACE both the mapper name and the UUID with the real values
  # from plateau (`sudo blkid` → the crypto_LUKS partition's UUID). The name
  # after "luks-" is conventionally that same UUID.
  boot.initrd.luks.devices."luks-REPLACE-WITH-LUKS-UUID".device =
    "/dev/disk/by-uuid/REPLACE-WITH-LUKS-UUID";

  myDesktop.environment = "niri";
  myUsers = [ "greg" ];
}
