# System-level account for greg (merged into users.users.greg by
# modules/nixos/users.nix). This is a NixOS attrset, NOT home-manager —
# greg's home-manager config is in ./default.nix.
{ pkgs, ... }:
{
  description = "Greg Laurent";
  extraGroups = [ "networkmanager" "wheel" "video" "audio" "libvirtd" "scanner" "lp" "uinput" ];
  shell = pkgs.zsh;
}
