{ pkgs, ... }:
{
  home.packages = [
    # ── Browsers
    # default: firefox
    pkgs.vivaldi
    pkgs.vivaldi-ffmpeg-codecs
    pkgs.zen-browser         # flake

    # ── Terminals
    # default: kitty
    pkgs.wezterm

    # ── Comms ──
    pkgs.slack
    pkgs.discord
    pkgs.zapzap

    # zoom runs under XWayland by default
    # (NIXOS_OZONE_WL doesn't touch it.
    # If Wayland screen-share still breaks, fix it 
    # in the flake `flakePkgs` overlay by wrapping 
    # zoom to force XWayland / unset XDG_SESSION_TYPE, 
    # e.g.:
    #   zoom-us = prev.zoom-us.overrideAttrs (o: {
    #     # ... wrap $out/bin/zoom with QT_QPA_PLATFORM=xcb / unset XDG_SESSION_TYPE
    #   });
    pkgs.zoom-us

    # ── Game streaming ── Moonlight is the client: it connects to a Sunshine
    # (or GeForce Experience) host and plays its stream. Installed on both hosts
    # so either can be the couch/laptop end; the box running the game still
    # needs a Sunshine host to pair with.
    pkgs.moonlight-qt

    # ── Remote desktop (interim: wayvnc bound to localhost + SSH tunnel; a mesh
    # VPN replaces the tunnel later). wayvnc = server (captures the niri session
    # via zwlr_screencopy, injects input via virtual kbd/pointer — both confirmed
    # present on niri). wlvncc = Wayland-native client. wayvnc listens on localhost
    # only by default, so it's never network-exposed — SSH provides auth+crypto.
    pkgs.wayvnc
    pkgs.wlvncc

    # ── Notes / office / reading ──
    pkgs.obsidian

    # ── Media ──
    pkgs.vlc
    pkgs.mpv
    pkgs.yt-dlp
    pkgs.obs-studio
    # tidal-hifi white-screens on Wayland: its Chromium sandbox zygote fails
    # (zygote_host_impl_linux.cc "Invalid argument") and the GPU process can't
    # launch. The maintainer's documented fix is the `--no-sandbox` flag
    # (docs/known-issues.md); the app's own "disableSandbox" config toggle applies
    # too late — from JS, after Electron has already init'd the sandbox — so it's
    # unreliable (the docs say as much). Wrap the binary so the flag is always on
    # the command line, covering terminal *and* .desktop (Exec=tidal-hifi,
    # PATH-resolved) launches. Other Electron apps here (slack/discord/obsidian)
    # don't need this — they use the userns sandbox fine; tidal-hifi is the outlier.
    (pkgs.symlinkJoin {
      name = "tidal-hifi-nosandbox";
      paths = [ pkgs.tidal-hifi ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/tidal-hifi --add-flags "--no-sandbox"
      '';
    })
    pkgs.imagemagick
    pkgs.ffmpegthumbnailer

    # ── Other Utils ──
    # default: localsend
    pkgs.satty
    pkgs.wayscriber  # ZoomIt-like on-screen annotation/zoom for Wayland (Rust)
    pkgs.mission-center
    pkgs.cloudflared

    # ── Archives ── file-roller = GNOME Archive Manager: opens archives on
    # double-click in Nautilus and drives extract/compress dialogs. zip/unzip/
    # p7zip are the CLI backends it shells out to (and give you zip/unzip/7z on
    # the command line). Nautilus's own Compress/Extract (gnome-autoar) covers
    # right-click compress-a-folder without needing file-roller.
    pkgs.file-roller
    pkgs.zip
    pkgs.unzip
    pkgs.p7zip
    pkgs.rar         # ships both `rar` (create) and `unrar` (extract); unfree

    # ── AI ──
    pkgs.claude-code
    pkgs.claude-desktop      # flake overlay; FHS variant = MCP/Cowork
  ];
}
