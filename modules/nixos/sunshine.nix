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

    # Validate BEFORE touching anything: a prep-cmd that fails part-way leaves
    # the display in a half-applied state, because Sunshine skips the undo when
    # the launch aborts. Numeric, because these end up in a mode string.
    case "$w$h$fps" in
      "" | *[!0-9]*)
        echo "sunshine-niri-prep: bad client geometry in environment: '$w' '$h' '$fps'" >&2
        exit 1
        ;;
    esac

    cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/niri/stream-output.kdl"
    # Both the output AND the placement rule are written here, because niri's
    # window-rule matchers (app-id, title, is-floating, at-startup, ...) have no
    # way to say "only on this output" — so a static rule forcing fullscreen
    # would force it all the time. Writing the rule per-session scopes it: it
    # exists while streaming and is gone the moment the stream ends.
    #
    # No match block, so it covers games too; their app-ids are arbitrary and
    # enumerating them is a losing game.
    cat > "$cfg" <<EOF
    // Written by sunshine-niri-prep at stream start. Do not edit.
    output "$out" {
        mode custom=true "''${w}x''${h}@''${fps}"
        scale 1
    }

    window-rule {
        open-on-output "$out"
        open-floating false
        open-fullscreen true
        open-focused true
    }
    EOF

    niri=${pkgs.niri}/bin/niri
    "$niri" msg action load-config-file

    # Do NOT assume that took effect. The reload is asynchronous, and if the
    # output never comes up there is no error anywhere: open-on-output silently
    # falls back to the focused monitor and niri parks the window on a fresh
    # workspace there. That silent fallback is how Steam ended up on a second
    # workspace on the desktop monitor.
    #
    # Failing loudly is the point: a non-zero prep exit aborts the launch and
    # Sunshine logs the reason instead of streaming the wrong display.
    for _ in $(${pkgs.coreutils}/bin/seq 60); do
      if "$niri" msg --json outputs | ${pkgs.jq}/bin/jq -e \
        --arg o "$out" --argjson w "$w" --argjson h "$h" '
          .[$o] as $m
          | $m.logical != null
            and $m.current_mode != null
            and $m.modes[$m.current_mode].width == $w
            and $m.modes[$m.current_mode].height == $h
        ' >/dev/null 2>&1; then
        # Focus it so anything not covered by an open-on-output rule still lands
        # here; placement rules are authoritative, this is for the rest.
        "$niri" msg action focus-monitor "$out"
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.05
    done

    echo "sunshine-niri-prep: $out never came up at ''${w}x''${h} - refusing to launch" >&2
    "$niri" msg --json outputs >&2 || true
    exit 1
  '';

  niriUndo = pkgs.writeShellScript "sunshine-niri-undo" ''
    cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/niri/stream-output.kdl"
    cat > "$cfg" <<EOF
    // Written by sunshine-niri-undo at stream end. Do not edit.
    output "$1" {
        off
    }
    EOF
    ${pkgs.niri}/bin/niri msg action load-config-file
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
