# System-level account for greg (merged into users.users.greg by
# modules/nixos/users.nix). This is a NixOS attrset, NOT home-manager —
# greg's home-manager config is in ./default.nix.
{ pkgs, ... }:
{
  description = "Greg Laurent";
  # uinput is added conditionally by modules/nixos/rustdesk.nix when myRustdesk
  # is enabled — don't hardcode it here (it wouldn't exist on non-RustDesk hosts).
  # dialout: access to /dev/ttyACM* CDC-ACM serial ports. The JDS Labs Element IV
  # exposes its config interface as a USB serial port, and the JDS Labs Core
  # Configurator (web) opens it via WebSerial — without this the browser sees the
  # device but can't connect.
  extraGroups = [ "networkmanager" "wheel" "video" "audio" "libvirtd" "scanner" "lp" "dialout" ];
  shell = pkgs.zsh;
}
