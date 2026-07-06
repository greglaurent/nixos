# Virtualization — default on every machine.
#   1. libvirt/QEMU host stack + virt-manager (run VMs).
#   2. virgl (virtio-gpu-gl + SPICE OpenGL) for 3D-accelerated guests.
{ pkgs, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true; 
    };
  };
  programs.virt-manager.enable = true;
  environment.systemPackages = with pkgs; [ virglrenderer ];
}
