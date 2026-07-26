# CachyOS-flavoured performance stack, on the stock kernel + native nixpkgs (no
# bleeding-edge kernel channel). Machine-level, opt-in per host via
# `myPerformance.enable` — mirrors myGaming/myPodman. Bundles the pieces that are
# universally beneficial (zram, memory-pressure handling, process priorities) and
# exposes the one hardware/workload-specific knob (the scx scheduler) as an option.
{ config, lib, pkgs, ... }:
let
  cfg = config.myPerformance;
in
{
  options.myPerformance = {
    enable = lib.mkEnableOption "CachyOS-style performance stack (zram, earlyoom, ananicy, scx)";

    scheduler = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "scx_lavd";
      example = "scx_rusty";
      description = ''
        sched-ext userspace CPU scheduler to load (CachyOS-style scheduling on the
        stock kernel; linuxPackages_latest carries sched_ext, mainline since 6.12).
        scx_lavd is latency/laptop-tuned; a many-core desktop may prefer a
        throughput scheduler like scx_rusty. Set to null to skip scx entirely
        while keeping the rest of the stack.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # zram: compressed swap in RAM (zstd, ~2-3x). Swapping to compressed RAM is
      # far cheaper than disk, so this lifts effective capacity and keeps the
      # system responsive under memory pressure. mkDefault so a host can still
      # override. Coexists with the disk swapDevices in each host's
      # hardware-configuration.nix — zram's higher priority means the kernel fills
      # zram first and only spills to the partition.
      zramSwap = {
        enable = lib.mkDefault true;
        algorithm = "zstd";
        memoryPercent = 50;          # zram device capped at 50% of RAM
      };

      # Sysctls tuned for the zram-as-primary-swap case (vs disk swap):
      #   swappiness 180 — swapping to RAM is cheap, so lean into it (max 200).
      #   page-cluster 0 — disable swap read-ahead; zram random access is fast, so
      #                    batching pages in just wastes decompression work.
      boot.kernel.sysctl = {
        "vm.swappiness" = lib.mkDefault 180;
        "vm.page-cluster" = lib.mkDefault 0;
      };

      # Memory-pressure handler. The kernel OOM killer acts too late (system
      # already thrashing); earlyoom kills a process while things are still
      # responsive, on free-RAM/free-swap thresholds — pairs with the zram swap.
      # Disable systemd-oomd (NixOS default-on) rather than run both: different
      # signals (cgroup pressure vs whole-system free memory), stacking them just
      # means two daemons racing to kill. Pick one.
      systemd.oomd.enable = false;
      services.earlyoom.enable = true;

      # ananicy-cpp: auto-applies nice / ionice / scheduling classes per process
      # from a rule set, so background jobs yield to interactive ones — a core part
      # of the CachyOS "feel". Complements scx (scx schedules; ananicy sets the
      # priorities it schedules by). rulesProvider is CachyOS's own ruleset.
      services.ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos;
        # Turn off ananicy-cpp's cgroup features, broken under systemd cgroup-v2
        # (they only spam `add_pid_to_cgroup: Invalid argument`):
        #   cgroup_realtime_workaround — THE culprit (worker.cpp:209): for any rule
        #     with an RT sched policy it moves the process to the *root* cgroup (a
        #     cgroup-v1 RT-throttle workaround). cgroup-v2 forbids PIDs in the root,
        #     so every RT process errors. Unnecessary on v2. mkForce because the
        #     module hard-sets it true (plain def, not mkOptionDefault).
        #   cgroup_load / apply_cgroup — the .cgroups CPU-throttle path; off so
        #     nothing tries to create/populate those either.
        # Working parts stay on: nice, ionice, sched, oom_score_adj, and cpuset
        # (which uses sched_setaffinity, not cgroups).
        settings = {
          cgroup_realtime_workaround = lib.mkForce false;
          cgroup_load = false;
          apply_cgroup = false;
        };
      };
    }

    # scx is optional within the stack: null scheduler = skip it (e.g. a host whose
    # kernel lacks sched_ext, or where you want the rest of the stack only).
    (lib.mkIf (cfg.scheduler != null) {
      services.scx = {
        enable = true;
        scheduler = cfg.scheduler;
      };
    })
  ]);
}
