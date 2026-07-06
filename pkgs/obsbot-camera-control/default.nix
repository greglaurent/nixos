# aaronsb/obsbot-camera-control — Qt6 GUI+CLI for controlling OBSBOT cameras
# (AI tracking, pan/tilt/zoom, HDR) on Linux. This is the tool packaged on the
# AUR as `obsbot-camera-control`; there is no official OBSBOT Linux app and
# nothing in nixpkgs, so we vendor a from-source build here.
#
# It bundles OBSBOT's CLOSED-SOURCE SDK (sdk/lib/libdev.so.1.0.2), so the
# package is unfree and the prebuilt .so must be patched with autoPatchelfHook.
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  autoPatchelfHook,
  qt6,
  libusb1,
  systemdLibs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "obsbot-camera-control";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "aaronsb";
    repo = "obsbot-camera-control";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Q9Y+TpD0W0CdFYrDNfi5CvF9crViCiSzc+nJUBh6MGI=";
  };

  nativeBuildInputs = [
    cmake
    autoPatchelfHook # fix RPATH/interpreter of the prebuilt SDK .so + binaries
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtmultimedia
    libusb1 # SDK talks to the camera over USB
    systemdLibs # libudev, pulled in by the SDK blob
    stdenv.cc.cc.lib # libstdc++ for the prebuilt libdev.so
  ];

  # CMake bakes a build RPATH to sdk/lib (/build/source/sdk/lib), which Nix
  # rejects as a forbidden /build reference. Suppress it; autoPatchelfHook then
  # points the binaries at $out/lib (where libdev.so is installed) instead.
  cmakeFlags = [ "-DCMAKE_SKIP_BUILD_RPATH=ON" ];

  # CMakeLists.txt ships NO install() rules; replicate the PKGBUILD's package().
  # The cmake setup hook builds in ./build, and CMake emits binaries to bin/ at
  # the source root, so tree paths are one level up (../) from the build dir.
  installPhase = ''
    runHook preInstall

    install -Dm755 ../bin/obsbot-gui $out/bin/obsbot-gui
    install -Dm755 ../bin/obsbot-cli $out/bin/obsbot-cli

    # Closed-source OBSBOT SDK library + soname symlinks.
    install -Dm755 ../sdk/lib/libdev.so.1.0.2 $out/lib/libdev.so.1.0.2
    ln -s libdev.so.1.0.2 $out/lib/libdev.so.1
    ln -s libdev.so.1.0.2 $out/lib/libdev.so

    install -Dm644 ../obsbot-control.desktop \
      $out/share/applications/obsbot-control.desktop
    install -Dm644 ../resources/icons/camera.svg \
      $out/share/icons/hicolor/scalable/apps/obsbot-control.svg

    runHook postInstall
  '';

  meta = {
    description = "Qt6 GUI/CLI to control OBSBOT cameras (AI tracking, PTZ, HDR) on Linux";
    homepage = "https://github.com/aaronsb/obsbot-camera-control";
    # Bundles OBSBOT's closed-source SDK (sdk/lib/libdev.so).
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "obsbot-gui";
  };
})
