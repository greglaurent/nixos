{ config, pkgs, lib, doom-emacs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" ] ++ config.myUsers;
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  # Kill the PC-speaker system beep (e.g. backspace with nothing focused) everywhere.
  boot.blacklistedKernelModules = [ "pcspkr" "snd_pcsp" ];
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 20;
    efi.canTouchEfiVariables = true;
  };

  # zram: compressed swap in RAM (zstd, ~2-3x). Swapping to compressed RAM is far
  # cheaper than disk, so this lifts effective capacity and keeps the system
  # responsive under memory pressure — the Arch/Fedora/CachyOS default. Baseline,
  # not per-host like scx: unlike a scheduler this is hardware-agnostic and always
  # a win. mkDefault so a future host can still override. Coexists with the disk
  # swapDevices in each host's hardware-configuration.nix — zram's higher priority
  # means the kernel fills zram first and only spills to the partition.
  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = "zstd";
    memoryPercent = 50;          # zram device capped at 50% of RAM
  };

  # Sysctls tuned for the zram-as-primary-swap case (vs disk swap):
  #   swappiness 180 — swapping to RAM is cheap, so lean into it (kernel max 200).
  #   page-cluster 0 — disable swap read-ahead; zram random access is fast, so
  #                    batching pages in just wastes decompression work.
  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkDefault 180;
    "vm.page-cluster" = lib.mkDefault 0;
  };

  # Memory-pressure handler. The kernel OOM killer acts too late (system already
  # thrashing); earlyoom kills a process while things are still responsive, using
  # free-RAM/free-swap thresholds — which pair naturally with the zram swap above.
  # We disable systemd-oomd (NixOS default-on) rather than run both: they use
  # different signals (cgroup pressure vs whole-system free memory) and stacking
  # them just means two daemons racing to kill. Pick one.
  systemd.oomd.enable = false;
  services.earlyoom.enable = true;

  # ananicy-cpp: auto-applies nice / ionice / scheduling classes per process from
  # a rule set, so background jobs yield to interactive ones — a core part of the
  # CachyOS "feel". Complements scx (scx schedules; ananicy sets the priorities it
  # schedules by). rulesProvider is CachyOS's own ruleset, packaged in nixpkgs.
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    # Turn off ananicy-cpp's cgroup features, which are broken under systemd's
    # cgroup-v2 and only spam `add_pid_to_cgroup: Invalid argument`:
    #   cgroup_realtime_workaround — THE culprit (worker.cpp:209): for any rule
    #     with an RT sched policy it moves the process to the *root* cgroup, a
    #     cgroup-v1 RT-throttle workaround. cgroup-v2 forbids PIDs in the root, so
    #     every RT process errors. Unnecessary on v2. Gating it off short-circuits
    #     the failing call entirely.
    #   cgroup_load / apply_cgroup — the .cgroups CPU-throttle path (cpu80/85/90);
    #     off so nothing tries to create/populate those either.
    # The valuable, working parts stay on: nice, ionice, sched, oom_score_adj, and
    # cpuset (which uses sched_setaffinity, not cgroups). settings is attrsOf with
    # mkOptionDefault defaults, so these override per-key.
    settings = {
      # mkForce: the module hard-sets this one to true (a plain definition, unlike
      # the mkOptionDefault-set flags below), so an equal-priority override collides.
      cgroup_realtime_workaround = lib.mkForce false;
      cgroup_load = false;
      apply_cgroup = false;
    };
  };

  services.fwupd.enable = true;
  services.automatic-timezoned.enable = true;

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  services.xserver.xkb = {
    layout = lib.mkDefault "us";
      variant = lib.mkDefault "";
    };

  security.rtkit.enable = true;

  networking.networkmanager.enable = lib.mkDefault true;

  hardware.bluetooth = {
    enable = lib.mkDefault true;
    powerOnBoot = lib.mkDefault true;
  };

  # time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  i18n.extraLocaleSettings = lib.mkDefault {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };  

  environment.systemPackages = with pkgs; [ zsh git neovim ];
  programs.git.enable = true;
  programs.zsh.enable = true;

  environment.sessionVariables = {
    EDITOR = "nvim";   # system-wide baseline (root, sudoedit, any user, GUI fallback)
    # BROWSER lives in the desktop layer (modules/nixos/desktop) — firefox only
    # exists when a desktop is present; the base system carries no browser.
    NIXOS_OZONE_WL = "1";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit doom-emacs; };
  };
}
