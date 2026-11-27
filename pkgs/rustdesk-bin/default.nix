# The OFFICIAL upstream RustDesk *unattended-wayland* build, autopatched to run
# natively on NixOS. It captures the screen via DRM/KMS (libdrmtap, in a root
# service -- see modules/nixos/rustdesk.nix) and injects input via uinput, so it
# needs NO screencast/remote-desktop portal. That is why it works on niri, which
# lacks the RemoteDesktop portal that the stock build (and nixpkgs'
# `rustdesk-flutter`) requires for capture.
#
# Hand-pinned: bump `version` + `hash` together. To go back to the self-updating
# package, see the commented-out `rustdesk-bin` line in flake.nix.
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
, libdrm
, libglvnd
, gst_all_1
, libx11
, libxfixes
, libxtst
, libxcb
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
  version = "1.5.3";

  src = fetchurl {
    url = "https://github.com/rustdesk/rustdesk/releases/download/${finalAttrs.version}/rustdesk-unattended-wayland-${finalAttrs.version}-x86_64.deb";
    hash = "sha256-cI85DEbDV7ciVe1qFWDaZEyDgcUd2bEIy/KjzspzPg0=";
  };
  # Stock (portal-based) build, kept for going back:
  # src = fetchurl {
  #   url = "https://github.com/rustdesk/rustdesk/releases/download/${finalAttrs.version}/rustdesk-${finalAttrs.version}-x86_64.deb";
  #   hash = "sha256-gQltL2X9QzUlQMNRvKFbsHEqKm+e+kyV6f/yXLl7O4E=";
  # };

  nativeBuildInputs = [ dpkg autoPatchelfHook wrapGAppsHook3 makeWrapper ];

  buildInputs = [
    glib gtk3 gdk-pixbuf librsvg pango cairo at-spi2-atk
    wayland libxkbcommon libpulseaudio pipewire dbus pam zlib libva libdrm libglvnd
    gst_all_1.gstreamer gst_all_1.gst-plugins-base
    libx11 libxfixes libxtst libxcb
  ];

  # Bundled Flutter plugin .so's live beside the binary; let the loader find them.
  # libglvnd: libdrmtap dlopen()s libEGL.so.1 / libGLESv2.so.2 (not in its NEEDED list) to
  # de-tile scanout buffers on the GPU. dlopen searches the caller's RUNPATH, and NixOS has no
  # global libEGL.so.1 (only mesa's vendor lib), so without this capture fails with
  # "drmtap_convert_dmabuf failed: errno 1" and then falls back to the portal.
  appendRunpaths = [
    "${placeholder "out"}/share/rustdesk/lib"
    "${lib.getLib libglvnd}/lib"
  ];

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
    # libdrmtap (DRM/KMS capture). RustDesk dlopens it by the absolute path
    # /usr/lib/rustdesk/libdrmtap.so.0; modules/nixos/rustdesk.nix links that path here.
    mkdir -p $out/lib
    cp -r usr/lib/rustdesk $out/lib/rustdesk
    for d in $out/share/applications/*.desktop; do
      substituteInPlace "$d" --replace-quiet "/usr/bin/rustdesk" "rustdesk"
    done
    runHook postInstall
  '';

  postFixup = ''
    # Patch every ELF EXCEPT libapp.so.
    elfs=( $out/share/rustdesk/rustdesk )
    # The real libdrmtap file (not its soname symlink), whatever version it is.
    while IFS= read -r -d "" so; do elfs+=( "$so" ); done \
      < <(find $out/lib/rustdesk -type f -name 'libdrmtap.so.*' -print0)
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
