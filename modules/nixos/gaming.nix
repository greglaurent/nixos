# Steam + gaming support. Machine-level (Steam needs 32-bit graphics drivers),
# opt-in per host via `myGaming.enable = true;` — mirrors the myDesktop toggle.
{ config, lib, ... }:
let
  cfg = config.myGaming;
in
{
  options.myGaming.enable = lib.mkEnableOption "Steam and gaming support";

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;   # Steam Remote Play
      gamescopeSession.enable = true;   # gamescope session option in the DM
    };

    programs.gamemode.enable = true;    # feral gamemode: perf governor on launch

    # programs.steam already sets hardware.graphics.enable32Bit on modern
    # nixpkgs, so the 32-bit GL/Vulkan driver support is handled for us.
  };
}
