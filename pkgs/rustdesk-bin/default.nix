# The OFFICIAL upstream RustDesk binary (the same build Arch's `rustdesk-bin`
# ships), autopatched to run natively on NixOS. We use the prebuilt .deb rather
# than nixpkgs' from-source `rustdesk-flutter` (1.4.5) because that older build
# mishandles the Wayland session on niri ("Unsupported display server … x11
# expected"); the upstream 1.4.9 binary is what actually works there.
{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, wrapGAppsHook3
, makeWrapper
, glib
, gtk3
, gdk-pixbuf
, librsvg
, pango
, cairo
, at-spi2-atk
, wayland
, libxkbcommon
, libpulseaudio
, pipewire
, dbus
, pam
, zlib
, libva
, gst_all_1
, xorg
}:
let
  # GStreamer plugins RustDesk's Wayland capture pipeline needs at runtime:
  # pipewiresrc (pipewire), videoconvert + appsink (gst-plugins-base), core
  # elements (gstreamer).
  gstPath = lib.makeSearchPath "lib/gstreamer-1.0" [
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    pipewire
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "rustdesk-bin";
  version = "1.4.9";

  src = fetchurl {
    url = "https://github.com/rustdesk/rustdesk/releases/download/${finalAttrs.version}/rustdesk-${finalAttrs.version}-x86_64.deb";
    hash = "sha256-ckS6R8QOgEFyBEv75llGfFTORlVMmOeMjAQG8dYS/aM=";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook wrapGAppsHook3 makeWrapper ];

  buildInputs = [
    glib gtk3 gdk-pixbuf librsvg pango cairo at-spi2-atk
    wayland libxkbcommon libpulseaudio pipewire dbus pam zlib libva
    gst_all_1.gstreamer gst_all_1.gst-plugins-base
    xorg.libX11 xorg.libXfixes xorg.libXtst xorg.libxcb
  ];

  # Bundled Flutter plugin .so's live beside the binary; let the loader find them.
  appendRunpaths = [ "${placeholder "out"}/share/rustdesk/lib" ];

  dontWrapGApps = true;   # wrap manually in postFixup (after gappsWrapperArgs set)
  dontStrip = true;       # Dart snapshots carry data in symbols/sections

  # Do NOT let autoPatchelf touch libapp.so: it's a Dart AOT snapshot with no
  # library dependencies, and rewriting its ELF invalidates the snapshot
  # ("Invalid vm isolate snapshot seen"). We patch everything else by hand.
  dontAutoPatchelf = true;

  unpackCmd = "dpkg -x $curSrc .";
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/share $out/share
    for d in $out/share/applications/*.desktop; do
      substituteInPlace "$d" --replace-quiet "/usr/bin/rustdesk" "rustdesk"
    done
    runHook postInstall
  '';

  postFixup = ''
    # Patch every ELF EXCEPT libapp.so.
    elfs=( $out/share/rustdesk/rustdesk )
    for so in $out/share/rustdesk/lib/*.so; do
      [ "$(basename "$so")" = libapp.so ] || elfs+=( "$so" )
    done
    autoPatchelf "''${elfs[@]}"

    makeWrapper $out/share/rustdesk/rustdesk $out/bin/rustdesk \
      "''${gappsWrapperArgs[@]}" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gstPath}"
  '';

  meta = {
    description = "RustDesk remote desktop — official upstream binary, patched for NixOS";
    homepage = "https://rustdesk.com";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "rustdesk";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
