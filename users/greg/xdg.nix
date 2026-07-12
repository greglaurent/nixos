# Greg's complete XDG config — greg's entire XDG lives here and overrides the
# generic defaults in modules/home/xdg.nix. Every app handler and every user dir
# is set explicitly, so this file is the single source for greg's XDG; the module
# only supplies fallback defaults for anything a user doesn't set.
{ config, ... }:
let home = config.home.homeDirectory;
in
{
  # ── App handlers (all of them) ──
  myXdgApps.browser  = "vivaldi-stable.desktop";
  myXdgApps.images   = "vivaldi-stable.desktop";
  myXdgApps.video    = "mpv.desktop";
  myXdgApps.audio    = "mpv.desktop";
  myXdgApps.files    = "org.gnome.Nautilus.desktop";
  myXdgApps.text     = "emacsclient.desktop";
  myXdgApps.markdown = "emacsclient.desktop";

  # ── $BROWSER command ──
  home.sessionVariables.BROWSER = "vivaldi";


  # DEFAULTS
  # ── User dirs ──
  # xdg.userDirs = {
  #   desktop     = "${home}/Desktop";
  #   download    = "${home}/Downloads";
  #   documents   = "${home}/Documents";
  #   music       = "${home}/Media/Music";
  #   videos      = "${home}/Media/Videos";
  #   pictures    = "${home}/Media/Pictures";
  #   templates   = home;
  #   publicShare = home;
  #   extraConfig.PROJECTS = "${home}/Workspace";
  # };
}
