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

  home.packages = with pkgs; [
    # DMS defaults
    inter                    # UI       — "Inter Variable"
    fira-code                # monospace — "Fira Code"  (also doom-font)
    fira                     # "Fira Sans" — doom variable-pitch font
    material-symbols         # icons    — "Material Symbols {Rounded,Outlined,Sharp}"
    nerd-fonts.symbols-only  # glyphs   — "Symbols Nerd Font"

    # General coverage
    noto-fonts
    noto-fonts-color-emoji

    # Document / typesetting text faces (cascade + dead-tongue). Lora is the
    # serif body; Inter (above) is the sans. Just Lora is pulled from the Google
    # Fonts collection to avoid installing the whole set.
    (google-fonts.override { fonts = [ "Lora" ]; })
  ];
}
