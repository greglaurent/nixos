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

  # Hibernation target: the LUKS swap mapper already declared in
  # hardware-configuration.nix and unlocked by initrd below, so there is no
  # decrypted-swap UUID to look up as there is on rhizome. stage-1 would find it
  # by probing swapDevices for an swsuspend signature, but naming it keeps the
  # target deterministic across zram + partition.
  # Keep the swap partition >= RAM (68G vs 61Gi today) or the image cannot be
  # written and hibernate fails at the point of use; zram carries runtime swap.
  #
  # Hibernate is CONSOLE-ONLY here. It powers off completely, so a Wake-on-LAN
  # packet lands at the initrd passphrase prompt with no network and nothing can
  # reach the machine. Suspend-to-RAM — what the idle path actually does — keeps
  # the LUKS volume open, which is why WoL works there. Nothing below changes the
  # idle behaviour: `systemctl hibernate` is a deliberate, at-the-keyboard act.
  boot.resumeDevice = "/dev/mapper/luks-a3791415-752c-4222-909e-d5e16bf8fbb7";

  # DO NOT re-add SSH-in-initrd without physical access to this machine.
  # It was tried and backed out after locking the box out twice:
  #   * On systemd stage 1, initrd networkd configures enp74s0 and hands it to
  #     stage 2 STILL CONFIGURED — boot.initrd.network.flushBeforeStage2 only
  #     flushes for the script initrd (it is gated on !boot.initrd.systemd.enable),
  #     so it is a no-op here whatever its value.
  #   * NetworkManager then treats the device as unmanaged. The interface keeps
  #     its initrd DHCP lease, so the box answers on an unexpected address, but
  #     nothing writes resolv.conf: DNS and mDNS both die, Moonlight cannot see
  #     the host, and `git fetch` fails to resolve.
  #   * Recovery required a manual rollback at the console.
  # The missing piece is an initrd unit ordered before initrd-switch-root.target
  # that flushes the address and downs the link. Until that exists and is proven
  # in an extracted initrd, hibernate stays console-only and WoL stays paired with
  # suspend-to-RAM, which works.

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
  # Stream the 4K EDID dongle on HDMI-A-1 rather than the HP U32 on DP-3: each
  # session gets the connecting client's own resolution and the desktop monitor
  # is never retimed. The dongle is off by default (dots/niri/outputs.kdl) and
  # brought up by Sunshine's prep-cmd for the duration of the stream.
  mySunshine.captureOutput = "HDMI-A-1";
  myObsbot.enable = true;

  # CachyOS-style perf stack (zram, earlyoom, ananicy, scx). Defaults to scx_lavd;
  # if this many-core desktop wants a throughput scheduler later, set
  # `myPerformance.scheduler = "scx_rusty";` here.
  myPerformance.enable = true;
}
