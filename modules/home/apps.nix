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

    # ── Notes / office / reading ──
    pkgs.obsidian

    # ── Media ──
    pkgs.vlc
    pkgs.mpv
    pkgs.yt-dlp
    pkgs.obs-studio
    pkgs.tidal-hifi
    pkgs.imagemagick
    pkgs.ffmpegthumbnailer

    # ── Other Utils ──
    # default: localsend
    pkgs.satty
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
