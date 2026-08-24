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

  # Hibernation target. The swap here is the LUKS mapper already declared in
  # hardware-configuration.nix (swapDevices), and initrd already unlocks that
  # container just below — so the mapper path is deterministic and there is no
  # decrypted-swap UUID to look up, unlike rhizome. stage-1 would in fact find it
  # on its own (it scans swapDevices for an swsuspend signature when resumeDevice
  # is empty), but naming it makes the resume target explicit rather than
  # dependent on probe order across zram + partition.
  #
  # GATE before trusting this: the swap partition must be >= RAM, or the image
  # cannot be written and hibernate fails at the point of use. zram (myPerformance)
  # carries runtime swap; this partition exists to hold the image.
  #   free -h            → RAM
  #   swapon --show      → partition size, and confirm zram is separate
  #
  # WARNING — this conflicts with Wake-on-LAN above. Suspend-to-RAM resumes with
  # the LUKS volume still open, which is why WoL works today. Hibernate powers off
  # completely, so a magic packet wakes the box into the initrd passphrase prompt
  # with no network: Moonlight cannot reach it and it sits there until someone
  # types at the console. Remote wake + hibernate needs SSH in initrd
  # (boot.initrd.network.ssh), which additionally needs enp74s0's driver module in
  # boot.initrd.availableKernelModules — that list currently carries storage only.
  boot.resumeDevice = "/dev/mapper/luks-a3791415-752c-4222-909e-d5e16bf8fbb7";

  # SSH in initrd, so a Wake-on-LAN wake into the LUKS prompt is recoverable
  # remotely instead of stranding the machine. This is what makes hibernate and
  # remote wake coexist: WoL powers the box on, you ssh to port 2222 as root,
  # run `cryptsetup-askpass`, and boot proceeds — including the resume above.
  #
  # r8169 is enp74s0's driver (readlink /sys/class/net/enp74s0/device/driver).
  # It has to be in the initrd or there is no network to ssh into; the list in
  # hardware-configuration.nix carries storage controllers only. Lists merge, so
  # this adds to it rather than replacing it.
  boot.initrd.availableKernelModules = [ "r8169" ];

  # Bring the link up inside initrd. This host uses systemd stage 1
  # (boot.initrd.systemd.enable is true), where boot.initrd.network.udhcpc does
  # not exist — the build asserts on it — so DHCP is configured as an initrd
  # networkd unit. Scoped to initrd only; NetworkManager still owns addressing on
  # the booted system, and nothing here changes that.
  boot.initrd.systemd.network = {
    enable = true;
    networks."10-enp74s0" = {
      matchConfig.Name = "enp74s0";
      networkConfig.DHCP = "yes";
    };
  };

  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      # Deliberately not 22: this is a different host key than the booted system's,
      # and sharing the port would trip known_hosts mismatches on every unlock.
      port = 2222;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCKYK7X2lRe3AhbpmtzeRGIrwOrd2a7OQ9psxC1mzGa gregory.m.laurent@gmail.com"
      ];
      # STRING, not a Nix path. A string routes through boot.initrd.secrets and is
      # appended to the initrd by the bootloader; a path literal would copy the
      # PRIVATE key into the world-readable Nix store. Generate it once as root,
      # and do NOT reuse the booted system's host key — the initrd lives on the
      # unencrypted ESP:
      #   mkdir -p /etc/secrets/initrd
      #   ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/ssh_host_ed25519_key
      hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
    };
  };

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
