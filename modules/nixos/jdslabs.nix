# JDS Labs Element IV support for the web configurator + firmware updater
# (https://core.jdslabs.com). The Element IV exposes several USB interfaces:
#
#   * CDC-ACM serial port (/dev/ttyACM*) — the Core Configurator reads/writes
#     settings over WebSerial. Access to that comes from greg being in the
#     `dialout` group (see users/greg/account.nix).
#   * DFU interface (bInterfaceClass 0xfe) — the firmware updater talks to the
#     raw USB device over WebUSB, which needs rw on the /dev/bus/usb/*/* node.
#
# During a firmware flash the device DROPS OFF and RE-ENUMERATES in bootloader
# mode (a fresh USB add event, possibly a different product id). Relying on the
# "uaccess" ACL alone is fragile there: (a) there's a race between the node
# appearing and systemd-logind applying the ACL, and the updater opens the node
# inside that window; (b) if the bootloader enumerates as any PID other than the
# one we listed, no rule matches and it gets no access at all. That is why the
# "USB Permissions Setup Required" prompt keeps reappearing at flash time.
#
# So instead of a per-PID ACL we match the whole JDS Labs vendor (152a) and set
# a persistent world-rw mode on the raw USB node. This is timing-independent,
# survives re-enumeration into any bootloader PID, and needs no re-login. 152a
# is JDS Labs' own vendor id; 0666 on their audio/DFU nodes is the same approach
# dfu-util / stlink udev rules ship. uaccess is kept as a bonus for the runtime
# device. This is the declarative equivalent of JDS's /etc/udev/rules.d
# instructions, which don't persist on NixOS.
{ ... }:
{
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="152a", TAG+="uaccess", MODE="0666"
  '';
}
