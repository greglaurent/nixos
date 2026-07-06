{ config, lib, ... }:
let home = config.home.homeDirectory;
in
{
  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    # setSessionVariables = false;

    desktop  = "${home}/Desktop";
    download = "${home}/Downloads";
    documents = "${home}/Media/Documents";
    music     = "${home}/Media/Music";
    pictures  = "${home}/Media/Pictures";
    videos    = "${home}/Media/Videos";

    templates   = home;
    publicShare = home;

    extraConfig = {
      PROJECTS = "${home}/Workspace";
    };
  };

  home.sessionVariables.XDG_DOCUMENTS_DIR = config.xdg.userDirs.documents;

  # Default applications for GUI link/file opening (xdg-open, clicked links).
  # MIME-type keys are stable (freedesktop shared-mime-info); the .desktop
  # values must match files under …/share/applications/. Rows with no installed
  # handler are left commented so they don't make xdg-open fail for that type.
  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      let
        browser = "firefox.desktop";
        video   = "mpv.desktop";
        audio   = "vlc.desktop";
        files   = "org.gnome.Nautilus.desktop";
        images  = "firefox.desktop";   # no dedicated viewer installed; Firefox opens images
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
        "application/pdf" = browser;          # Firefox has a PDF viewer
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
        "audio/mpeg"  = audio;   # mp3
        "audio/flac"  = audio;
        "audio/ogg"   = audio;
        "audio/opus"  = audio;
        "audio/wav"   = audio;
        "audio/aac"   = audio;
        "audio/mp4"   = audio;   # m4a
        "audio/x-m4a" = audio;

        # ── Video ──
        "video/mp4"        = video;
        "video/x-matroska" = video;   # mkv
        "video/webm"       = video;
        "video/quicktime"  = video;   # mov
        "video/x-msvideo"  = video;   # avi
        "video/mpeg"       = video;
        "video/3gpp"       = video;

        # ── Text / code ──
        "text/plain"       = browser;   # no GUI editor installed
        "text/markdown"    = "obsidian.desktop";
        "application/json" = browser;
        "text/xml"         = browser;
        "application/xml"  = browser;
        "text/csv"         = browser;

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
}
