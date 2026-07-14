# System-level account for greg (merged into users.users.greg by
# modules/nixos/users.nix). This is a NixOS attrset, NOT home-manager —
# greg's home-manager config is in ./default.nix.
{ pkgs, ... }:
{
  description = "Greg Laurent";
  # uinput is added conditionally by modules/nixos/rustdesk.nix when myRustdesk
  # is enabled — don't hardcode it here (it wouldn't exist on non-RustDesk hosts).
  extraGroups = [ "networkmanager" "wheel" "video" "audio" "libvirtd" "scanner" "lp" ];
  shell = pkgs.zsh;
}
