{ ... }:
{
  imports = [
    ./system.nix
    ./users.nix
    ./virtualisation.nix
    ./desktop
    ./gaming.nix
    ./podman.nix
  ];
}
