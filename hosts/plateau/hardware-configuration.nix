# ┌─────────────────────────────────────────────────────────────────────────┐
# │ PLACEHOLDER — DO NOT BUILD/INSTALL AS-IS.                                  │
# │ Replace this ENTIRE file with the one generated ON plateau by:            │
# │     sudo nixos-generate-config --root /mnt   (during install), or         │
# │     sudo nixos-generate-config               (already-running system)     │
# │ It lives at /etc/nixos/hardware-configuration.nix after install. The real │
# │ file has correct filesystem UUIDs, the LUKS-mapped root device, kernel    │
# │ modules, and swap for THIS machine. The values below are generic AMD-     │
# │ desktop guesses only so the flake still evaluates.                        │
# └─────────────────────────────────────────────────────────────────────────┘
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # REPLACE: on a LUKS system the root is the unlocked mapper device, e.g.
  #   device = "/dev/mapper/luks-<uuid>";
  fileSystems."/" = {
    device = "/dev/mapper/luks-REPLACE-WITH-LUKS-UUID";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-BOOT-UUID";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
