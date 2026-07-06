{ config, lib, pkgs, ... }:

lib.mkIf (config.myDesktop.environment == "kde") {
  services.xserver.enable = true;
  services.libinput.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.systemPackages = with pkgs; [ kdePackages.kate ];
}
