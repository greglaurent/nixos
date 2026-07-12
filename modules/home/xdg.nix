{ config, lib, ... }:
let home = config.home.homeDirectory;
in
{
  # Per-app default handlers, as options with DESKTOP defaults. A user overrides
  # any of them from their own layer (users/greg/xdg.nix -> vivaldi). Assigning
  # an option value overrides its default — same pattern as myOrgDir/myDotsDir.
  options.myXdgApps = {
    browser  = lib.mkOption {
      type = lib.types.str; default = "firefox.desktop";
      description = "Handler for web pages / URL schemes.";
    };
    images   = lib.mkOption {
      type = lib.types.str; default = "firefox.desktop";
      description = "Handler for image files (default set has no dedicated viewer).";
    };
    video    = lib.mkOption {
      type = lib.types.str; default = "mpv.desktop";
      description = "Handler for video files.";
    };
    audio    = lib.mkOption {
      type = lib.types.str; default = "mpv.desktop";
      description = "Handler for audio files.";
    };
    files    = lib.mkOption {
      type = lib.types.str; default = "org.gnome.Nautilus.desktop";
      description = "Handler for directories.";
    };
    text     = lib.mkOption {
      type = lib.types.str; default = "firefox.desktop";
      description = "Handler for plain-text / code files (generic default views in browser; a user with an editor overrides).";
    };
    markdown = lib.mkOption {
      type = lib.types.str; default = "firefox.desktop";
      description = "Handler for Markdown files.";
    };
    pdf      = lib.mkOption {
      type = lib.types.str;
      default = config.myXdgApps.browser;   # follow the browser unless overridden
      description = "Handler for PDF files (defaults to the browser; override for a dedicated viewer).";
    };
  };

  config = {
    xdg.enable = true;

    # userDirs: single source of truth for XDG dirs — writes user-dirs.dirs AND
    # (setSessionVariables) exports the complete matching XDG_*_DIR env set. Every
    # value is mkDefault so a user can override any individual dir from their own
    # layer without a conflict (same override capability as the app handlers).
    xdg.userDirs = {
      enable = true;
      createDirectories = lib.mkDefault true;
      setSessionVariables = lib.mkDefault true;

      desktop     = lib.mkDefault "${home}/Desktop";
      download    = lib.mkDefault "${home}/Downloads";
      documents   = lib.mkDefault "${home}/Documents";
      music       = lib.mkDefault "${home}/Media/Music";
      videos      = lib.mkDefault "${home}/Media/Videos";
      pictures    = lib.mkDefault "${home}/Media/Pictures";
      templates   = lib.mkDefault home;
      publicShare = lib.mkDefault home;

      extraConfig = {
        PROJECTS = lib.mkDefault "${home}/Workspace";
      };
    };

    # $BROWSER (a command) is set in the desktop layer (firefox) and overridden
    # per-user (greg -> vivaldi) — not here. XDG_*_DIR env vars are exported by
    # xdg.userDirs.setSessionVariables above, not hand-listed.

    # Default applications for GUI link/file opening (xdg-open, clicked links).
    # Every handler comes from an overridable option (myXdgApps.*); MIME-type keys
    # are stable (freedesktop shared-mime-info). Rows with no installed handler
    # are left commented so they don't make xdg-open fail for that type.
    xdg.mimeApps = {
      enable = true;
      defaultApplications =
        # Each value is mkDefault, so a user can override ANY individual mime type
        # directly — xdg.mimeApps.defaultApplications."image/svg+xml" = "x.desktop"
        # — without needing a per-type option. The category options (myXdgApps.*)
        # still change a whole group at once; a direct per-mime override wins over
        # both. Everything here is overridable two ways; nothing is locked.
        let
          browser  = lib.mkDefault config.myXdgApps.browser;
          images   = lib.mkDefault config.myXdgApps.images;
          video    = lib.mkDefault config.myXdgApps.video;
          audio    = lib.mkDefault config.myXdgApps.audio;
          files    = lib.mkDefault config.myXdgApps.files;
          text     = lib.mkDefault config.myXdgApps.text;
          markdown = lib.mkDefault config.myXdgApps.markdown;
          pdf      = lib.mkDefault config.myXdgApps.pdf;
        in {
          # ── URL scheme handlers ──
          "x-scheme-handler/http"    = browser;
          "x-scheme-handler/https"   = browser;
          "x-scheme-handler/about"   = browser;
          "x-scheme-handler/unknown" = browser;
          "x-scheme-handler/ftp"     = browser;
          "x-scheme-handler/chrome"  = browser;
          # "x-scheme-handler/mailto"  = "…";   # no mail client installed
          # "x-scheme-handler/magnet"  = "…";   # no torrent client installed

          # ── HTML / web documents ──
          "text/html"             = browser;
          "application/xhtml+xml" = browser;

          # ── PDF & e-books ──
          "application/pdf" = pdf;
          # "application/epub+zip"            = "…";
          # "application/x-mobipocket-ebook"  = "…";

          # ── Images ──
          "image/png"     = images;
          "image/jpeg"    = images;
          "image/gif"     = images;
          "image/webp"    = images;
          "image/svg+xml" = images;
          "image/bmp"     = images;
          "image/tiff"    = images;
          "image/x-icon"  = images;
          "image/heif"    = images;
          "image/avif"    = images;

          # ── Audio ──
          "audio/mpeg"  = audio;
          "audio/flac"  = audio;
          "audio/ogg"   = audio;
          "audio/opus"  = audio;
          "audio/wav"   = audio;
          "audio/aac"   = audio;
          "audio/mp4"   = audio;
          "audio/x-m4a" = audio;

          # ── Video ──
          "video/mp4"        = video;
          "video/x-matroska" = video;
          "video/webm"       = video;
          "video/quicktime"  = video;
          "video/x-msvideo"  = video;
          "video/mpeg"       = video;
          "video/3gpp"       = video;

          # ── Text / code ──
          "text/plain"       = text;
          "application/json" = text;
          "text/xml"         = text;
          "application/xml"  = text;
          "text/csv"         = text;
          "text/markdown"    = markdown;

          # ── Directories ──
          "inode/directory" = files;

          # ── Office (no suite installed — assign after adding one) ──
          # "application/vnd.oasis.opendocument.text"         = "…";  # odt
          # "application/vnd.oasis.opendocument.spreadsheet"  = "…";  # ods
          # "application/vnd.oasis.opendocument.presentation" = "…";  # odp
          # "application/msword"                                                        = "…";  # doc
          # "application/vnd.openxmlformats-officedocument.wordprocessingml.document"   = "…";  # docx
          # "application/vnd.ms-excel"                                                  = "…";  # xls
          # "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"         = "…";  # xlsx
          # "application/vnd.ms-powerpoint"                                             = "…";  # ppt
          # "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "…";  # pptx
          # "application/rtf"                                                           = "…";

          # ── Archives (no GUI archiver installed) ──
          # "application/zip"              = "…";
          # "application/x-tar"            = "…";
          # "application/gzip"             = "…";
          # "application/x-7z-compressed"  = "…";
          # "application/vnd.rar"          = "…";
          # "application/x-bzip2"          = "…";
          # "application/x-xz"             = "…";
        };
    };

    home.activation.ensureDevDirs =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "$HOME/Workspace"
      '';
  };
}
