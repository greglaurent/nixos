# Printing + scanning for HP multifunction devices, and network printer
# discovery. All printing/scanning config lives here (moved out of system.nix)
# so it's one coherent module.
{ pkgs, ... }:
{
  # CUPS with HP drivers. hplipWithPlugin bundles HP's proprietary binary plugin
  # (needed by many HP models and for full multifunction/scan support) — unfree,
  # but nixpkgs.config.allowUnfree is on (system.nix). Plain pkgs.hplip works for
  # models that don't need the plugin; the plugin variant is the safe default.
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplipWithPlugin ];
  };

  # Network printer auto-discovery: HP printers advertise over mDNS/IPP, and
  # avahi + nssmdns lets CUPS find them without hand-typing an IP. openFirewall
  # opens the mDNS port (5353/udp).
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Scanning for the HP multifunction — the hpaio SANE backend comes from the
  # same hplipWithPlugin. Users must be in the `scanner` group to access it
  # (greg is added in users/greg/account.nix).
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.hplipWithPlugin ];
  };

  # GUI scanning frontend (the SANE backend above is headless; this is the app).
  environment.systemPackages = [ pkgs.simple-scan ];
}
