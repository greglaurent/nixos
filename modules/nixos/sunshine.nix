# Sunshine — the game-streaming HOST (server) half. Pairs with Moonlight (the
# client, installed for greg in modules/home/apps.nix). Opt-in per host with
# `mySunshine.enable = true;`, mirroring myRustdesk. Enabled on both rhizome and
# plateau so either box can host a stream while the other plays it.
#
# What this wires up:
#   * services.sunshine — the host daemon (runs as a systemd *user* service).
#   * openFirewall — Sunshine's control/stream ports (47984-48010, TCP+UDP).
#   * capSysAdmin — CAP_SYS_ADMIN on the binary, required for KMS/DRM screen
#     capture, which is how Sunshine grabs the niri (Wayland) session.
#   * /dev/uinput — Sunshine injects a virtual gamepad/keyboard/mouse from the
#     client's input, same synthetic-input path RustDesk needs under Wayland.
#
# First run is interactive: open https://localhost:47990 on the HOST to set the
# admin user/PIN, then pair Moonlight to it. That pairing state is per-machine
# and lives outside the Nix store.
{ config, lib, pkgs, ... }:
let
  cfg = config.mySunshine;

  # Per-session resolution matching (see mySunshine.captureOutput).
  #
  # Sunshine execs prep commands DIRECTLY — boost::process with no shell (see
  # run_command in src/platform/linux/misc.cpp) — so `&&` chains and shell
  # syntax are not available and multi-step work has to live in a script.
  #
  # The client's geometry is read from the ENVIRONMENT, not passed as argv.
  # Sunshine's own $(VAR) syntax is expanded in proc::parse() when apps.json and
  # the config are loaded, which happens long before any client connects — the
  # SUNSHINE_CLIENT_* vars do not exist yet at that point and expand to empty
  # strings. They are injected into the launched child's environment at session
  # start instead (process.cpp, proc_t::execute), so the script picks them up
  # here. (Sunshine's Windows examples use %VAR%, expanded by cmd.exe at
  # runtime, which is why they don't hit this.)
  niriPrep = pkgs.writeShellScript "sunshine-niri-prep" ''
    out="$1"
    w="''${SUNSHINE_CLIENT_WIDTH:-}"
    h="''${SUNSHINE_CLIENT_HEIGHT:-}"
    fps="''${SUNSHINE_CLIENT_FPS:-}"

    # Validate BEFORE touching the output: a prep-cmd that fails part-way leaves
    # the display on, because Sunshine skips the undo when the launch aborts.
    if [ -z "$w" ] || [ -z "$h" ] || [ -z "$fps" ]; then
      echo "sunshine-niri-prep: no client geometry in environment" >&2
      exit 1
    fi

    niri=${pkgs.niri}/bin/niri
    # Order matters: the output has to exist before a mode can land on it.
    "$niri" msg output "$out" on
    # Scale 1 so the client receives 1:1 pixels and Moonlight is not scaling an
    # already-scaled desktop.
    "$niri" msg output "$out" scale 1
    # custom-mode, not mode: the client's resolution is whatever its Moonlight
    # asks for and will generally not be in the dongle's EDID mode list.
    "$niri" msg output "$out" custom-mode "''${w}x''${h}@''${fps}"
  '';

  niriUndo = pkgs.writeShellScript "sunshine-niri-undo" ''
    ${pkgs.niri}/bin/niri msg output "$1" off
  '';
in
{
  options.mySunshine = {
    enable = lib.mkEnableOption "Sunshine game-streaming host";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Start the Sunshine host daemon at login. Leave this true on a desktop
        that hibernates (a fully powered-off machine can't be drained by an idle
        daemon). Set it false on a laptop that only s2idles: an idle host daemon
        holds the DRM/GPU capture path open, blocking deep sleep and draining the
        battery. With it false, Sunshine stays fully installed and configured —
        start it on demand with `systemctl --user start sunshine` to host.
      '';
    };

    captureOutput = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "HDMI-A-1";
      description = ''
        niri output to stream, as named by `niri msg outputs` (e.g. "HDMI-A-1").

        Setting this points Sunshine's capture at that one output AND installs a
        global prep-cmd that, per session, turns it on, forces scale 1, and sets
        a custom mode matching the resolution/fps the connecting client asked
        for — then turns it back off when the stream ends. The intended target
        is a 4K EDID dongle rather than a real monitor: every client gets its own
        native resolution and the desktop display is never touched.

        Sunshine's docs claim output_name is a numeric index, but the Wayland
        capture path matches the connector name first and only falls back to the
        index (src/platform/linux/wlgrab.cpp) — the name is used here because it
        is stable across hotplug.

        Leave null to stream the primary output with no mode juggling.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      openFirewall = true;   # 47984-48010 TCP/UDP (HTTPS control + RTSP/video/audio/control)
      capSysAdmin = true;    # needed for KMS/DRM capture of the Wayland session
      autoStart = cfg.autoStart;   # per-host: off on the laptop (see option above)

      # Force Xbox One virtual-pad emulation. Sunshine's default `gamepad = auto`,
      # together with the on-by-default motion_as_ds4/touchpad_as_ds4, makes it
      # emulate a PlayStation (ds5) pad whenever the *client's* controller reports
      # a gyro or touchpad — which Flydigi pads do even in Xbox mode. Steam on the
      # host then sees a DualSense (which needs "PlayStation Configuration Support"
      # enabled) instead of the Xbox pad actually in hand, so it looks like the
      # controller "isn't picked up". Pinning xone gives Steam a plug-and-play Xbox
      # controller. (settings is a freeform submodule, so this merges with the
      # module's default port.)
      settings = {
        gamepad = "xone";
      } // lib.optionalAttrs (cfg.captureOutput != null) {
        output_name = cfg.captureOutput;
        # global_prep_cmd is a JSON array in sunshine.conf; the settings format
        # writes values verbatim, so hand it real JSON. Global rather than
        # per-app deliberately: it keeps `applications` undeclared, which leaves
        # the app list editable in the web UI (declaring it would repoint
        # file_apps at the store and drop everything configured there).
        global_prep_cmd = builtins.toJSON [
          {
            do = "${niriPrep} ${cfg.captureOutput}";
            undo = "${niriUndo} ${cfg.captureOutput}";
          }
        ];
      };
    };

    # /dev/uhid: inputtino creates Sunshine's virtual gamepad (DS5) emulation
    # through uhid, but neither the kernel nor the sunshine package ships a udev
    # rule for it — it stays root-only, so the user service can't open it and
    # Sunshine logs "Gamepad ds5 disabled due to Permission denied". Grant the
    # `input` group rw so the user service can emit a streamed gamepad. uhid is a
    # kernel-created *static* node (udev has no db entry — `udevadm info` reports
    # "No such device"), so the rule needs OPTIONS+="static_node=uhid" to apply,
    # same shape as the working uinput rule.
    services.udev.extraRules = ''
      SUBSYSTEM=="misc", KERNEL=="uhid", MODE="0660", GROUP="input", OPTIONS+="static_node=uhid"
    '';

    # Group membership for the user-level Sunshine service:
    #   * uinput — services.sunshine sets hardware.uinput.enable (creating the
    #     `uinput` group + a 0660 udev rule on /dev/uinput) but does NOT join
    #     users to it; without membership Sunshine can't create virtual devices.
    #   * input — evdev controller access, plus rw on the uhid rule above.
    #     Sunshine's docs: "If controllers are not detected, ensure the user is
    #     in the input group."
    users.users = builtins.listToAttrs (map (name: {
      inherit name;
      value.extraGroups = [ "uinput" "input" ];
    }) config.myUsers);
  };
}
