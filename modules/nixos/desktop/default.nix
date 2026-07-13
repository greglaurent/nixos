{ config, lib, pkgs, ... }:
{
  imports = [ ./kde.nix ./niri.nix ];
  options.myDesktop.environment = lib.mkOption {
    type = lib.types.enum [ "kde" "niri" ];
    description = "Desktop environment for hosts.";
  };
  config = {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libva-utils
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
    environment.systemPackages = with pkgs; [
      kitty
      firefox
      localsend
    ];
    # firefox is the desktop's default browser — present only when a desktop is
    # active. A user overrides this in their home config (greg -> vivaldi).
    environment.sessionVariables.BROWSER = "firefox";
    xdg.portal = {
      enable = true;
      # gtk = file chooser / open-uri; gnome = ScreenCast (screen sharing on
      # niri — RustDesk, Zoom, OBS, browser calls). niri implements the Mutter
      # ScreenCast/RemoteDesktop D-Bus that xdg-desktop-portal-gnome drives.
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-gnome ];
      # niri isn't a desktop xdg-desktop-portal recognises, so route interfaces
      # explicitly for XDG_CURRENT_DESKTOP=niri: ScreenCast -> gnome, rest -> gtk.
      config.niri = {
        default = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      };
    };
    fonts.packages = with pkgs; [ ];
    programs = {
      firefox.enable = true;
      localsend.enable = true;
    };
  };
}
