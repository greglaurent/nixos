# Kitty terminal config for greg. Main purpose: silence the bell. Kitty
# defaults to `enable_audio_bell yes`, which plays a sound through PipeWire on
# every BEL (\a) — tab-completion, `less` past the end, etc. That reads like a
# "pc-speaker" beep even though the pcspkr module is blacklisted (system.nix),
# because it's a *software* bell, not the hardware speaker.
#
# programs.kitty uses the same pkgs.kitty as the system package (identical store
# path), so this only adds ~/.config/kitty/kitty.conf; it doesn't double-install.
{ ... }:
{
  programs.kitty = {
    enable = true;
    # xero's "sourcerer" palette, pulled by name from the bundled kitty-themes
    # collection. The upstream Sourcerer.conf matches xero's original Xresources
    # exactly (bg #222222, fg #c2c2b0, all 16 ANSI colors).
    themeFile = "Sourcerer";
    settings = {
      enable_audio_bell = "no"; # the actual noise source
      window_alert_on_bell = "no"; # no urgency flash to the compositor
      bell_on_tab = "no"; # no bell glyph in the tab title
      # visual_bell_duration defaults to 0 (off). Set e.g. "0.1" for a silent
      # visual flash instead of no feedback at all.

      # Breathing room between the text and the window edge. Values are
      # "top right bottom left" (pts); equal horizontal padding, no vertical.
      window_padding_width = "0 12 0 12";
    };
  };
}
