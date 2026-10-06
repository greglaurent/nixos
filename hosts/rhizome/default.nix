{ home-manager, nixos-hardware, pkgs, ... }:
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

  # ── Machine-bound disk identity — the ONLY lines tied to this exact install ──
  # Both UUIDs are minted at install (luksFormat / mkswap) and change on a fresh
  # reinstall. Nothing to remember: if they go stale the swap-LUKS unlock FAILS
  # LOUD — boot drops to an emergency shell naming `luks-49f5b87d…` — which is the
  # cue to update BOTH from the new disk:
  #   swap LUKS UUID     ← `blkid /dev/nvme0n1p3`  (the .device line + mapper name)
  #   resume image UUID  ← `blkid` on the decrypted swap mapper  (resumeDevice)
  # (resumeDevice alone would fail *silently* — hibernate just wouldn't resume —
  # so it's parked next to the loud one so the one fix covers both. Not label-based:
  # a label is just another thing to remember to set a-priori.)
  boot.initrd.luks.devices."luks-49f5b87d-2b0f-4548-8bbd-3bf878e0f92d".device =
    "/dev/disk/by-uuid/49f5b87d-2b0f-4548-8bbd-3bf878e0f92d";
  boot.resumeDevice = "/dev/disk/by-uuid/6c2e1301-9c48-4280-badf-a04faed5f0a6";

  # This machine's choices (override the global defaults just by stating them)
  myDesktop.environment = "niri";
  myUsers = [ "greg" ];
  myGaming.enable = true;          # Steam + gamescope session + gamemode
  myPodman.enable = true;          # rootless podman + docker compatibility
  myRustdesk.enable = true;        # remote desktop (native) — provides uinput
  # Sunshine installed but NOT auto-started on the laptop: an idle host daemon
  # holds the DRM/GPU capture path open, which drains the battery during the
  # s2idle window before suspend-then-hibernate (below) powers off. It's the
  # streaming client (Moonlight); start the host on demand with
  # `systemctl --user start sunshine`.
  mySunshine = {
    enable = true;
    autoStart = false;
  };

  # Laptop power management (integrates with DMS's power widget).
  services.power-profiles-daemon.enable = true;

  # Deep hibernate to stop s2idle battery drain (Framework AMD has no S3; plain
  # suspend is shallow s2idle that leaks). suspend-then-hibernate: lid-close goes
  # to s2idle first (instant resume if reopened soon), then hibernates after the
  # delay below to fully power off. Resume reads the image from the swap set in the
  # disk-identity block up top (swap LUKS unlocked in initrd + resumeDevice).
  # Clamshell is unaffected: lidSwitchDocked keeps its default (ignore), so
  # lid-closed + external monitor still stays awake.
  # NOTE: keep the ~51G swap partition ≥ RAM — it's the hibernation target now
  # (zram carries runtime swap); do not shrink it below RAM size.
  # GATE: test `systemctl hibernate` by hand and confirm a clean resume before
  # trusting the lid — Framework 13 AMD hibernate can be quirky.
  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  systemd.sleep.settings.Sleep.HibernateDelaySec = "30min";

  # Intermittent PIXA3854 failures persist on 7.2.7 after removing the old
  # workaround. Re-probe on every resume: a registered input device does not
  # prove that its reports/MT state are healthy. This is a recovery workaround,
  # not a confirmed kernel fix. sleep.target teardown covers suspend, hibernate,
  # and suspend-then-hibernate. Keep the service available for manual recovery.
  powerManagement.resumeCommands = "${pkgs.systemd}/bin/systemctl start touchpad-reset.service";
  systemd.services.touchpad-reset = {
    description = "Reinitialize rhizome's PixArt touchpad";
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "15s";
    };
    script = ''
      driver=/sys/bus/i2c/drivers/i2c_hid_acpi
      device=i2c-PIXA3854:00
      if [ ! -d "/sys/bus/i2c/devices/$device" ]; then
        echo "Touchpad device $device is missing" >&2
        exit 1
      fi
      if [ -L "$driver/$device" ]; then
        echo "Unbinding $device for resume recovery"
        printf '%s' "$device" > "$driver/unbind"
      fi
      # Retry only binding; do not repeatedly tear down a recovered device.
      for delay in 0.3 1 2; do
        ${pkgs.coreutils}/bin/sleep "$delay"
        if printf '%s' "$device" > "$driver/bind"; then
          echo "Touchpad $device rebound successfully"
          exit 0
        fi
        echo "Touchpad bind failed; retrying if attempts remain" >&2
      done
      echo "Touchpad recovery failed" >&2
      exit 1
    '';
  };

  # CachyOS-style perf stack (zram, earlyoom, ananicy, scx). scheduler defaults to
  # scx_lavd (latency/laptop-tuned) — right for the Framework.
  myPerformance.enable = true;

  # Fingerprint reader — enrol with `fprintd-enroll`. Enabling this also wires
  # fingerprint auth into PAM (login/sudo/lock) by default.
  services.fprintd.enable = true;
}
