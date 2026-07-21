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

  # Wake-on-LAN on the onboard NIC so Moonlight can wake plateau from sleep.
  # enp74s0 = onboard PCIe NIC (MAC 9c:6b:00:58:c3:14). The USB ethernet
  # dongle (enp8s0u2u4u5) is intentionally excluded — USB NICs can't reliably
  # wake from S3/S5. Requires "Wake on LAN" enabled and ErP/EuP disabled in BIOS.
  networking.interfaces.enp74s0.wakeOnLan.enable = true;

  # LUKS root. REPLACE both the mapper name and the UUID with the real values
  # from plateau (`sudo blkid` → the crypto_LUKS partition's UUID). The name
  # after "luks-" is conventionally that same UUID.


  boot.initrd.luks.devices."luks-a3791415-752c-4222-909e-d5e16bf8fbb7"
    .device = "/dev/disk/by-uuid/a3791415-752c-4222-909e-d5e16bf8fbb7";

  myDesktop.environment = "niri";
  myUsers = [ "greg" ];
  myGaming.enable = true;
  myPodman.enable = true;           # rootless podman + docker compatibility
  myRustdesk.enable = true;         # remote desktop (native) — provides uinput
  mySunshine.enable = true;         # game-streaming host (pairs with Moonlight)
  myObsbot.enable = true;
}
