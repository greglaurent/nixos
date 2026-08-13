# Home-manager font set. Trimmed to a sane baseline plus exactly what
# DankMaterialShell (DMS) asks for. DMS ships no fonts of its own, and its
# defaults (quickshell/Common/Theme.qml) are:
#   UI    "Inter Variable"     -> inter
#   mono  "Fira Code"          -> fira-code
#   icons  Material Symbols    -> material-symbols
#   glyphs nerd-fonts          -> nerd-fonts.symbols-only
{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;

  # nixpkgs' jetbrains-mono (and some google-fonts) ship WOFF2 web-font files
  # alongside the OTF/TTF. freetype — thus Emacs and GTK — cannot render WOFF2,
  # yet fontconfig ranks the .woff2 face FIRST for a family and hands apps an
  # unloadable file, which then silently falls back to a default font. That is
  # exactly why Emacs would not switch to JetBrains Mono, and why its ligatures
  # never composed. Reject WOFF2 outright: it is a web-delivery format with no
  # purpose on a desktop font path.
  xdg.configFile."fontconfig/conf.d/10-reject-woff2.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <selectfont>
        <rejectfont>
          <glob>*.woff2</glob>
        </rejectfont>
      </selectfont>
    </fontconfig>
  '';

  home.packages = with pkgs; [
    # DMS defaults
    inter                    # UI       — "Inter Variable"
    fira-code                # monospace — "Fira Code"  (DMS mono)
    fira                     # "Fira Sans" — doom variable-pitch font
    jetbrains-mono           # "JetBrains Mono" — doom-font
    material-symbols         # icons    — "Material Symbols {Rounded,Outlined,Sharp}"
    nerd-fonts.symbols-only  # glyphs   — "Symbols Nerd Font"

    # General coverage
    noto-fonts
    noto-fonts-color-emoji

    # Document / typesetting text faces (cascade + dead-tongue). Lora is the
    # serif body; Inter (above) is the sans; Jost is the geometric-sans preset.
    # Just Lora is pulled from the Google Fonts collection to avoid the whole set.
    (google-fonts.override { fonts = [ "Lora" ]; })
    jost                     # geometric sans — cascade "jost" preset
  ];
}
