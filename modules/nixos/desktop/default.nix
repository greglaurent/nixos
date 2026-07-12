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
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };
    fonts.packages = with pkgs; [ ];
    programs = {
      firefox.enable = true;
      localsend.enable = true;
    };
  };
}
