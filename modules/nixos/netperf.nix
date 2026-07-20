# Network throughput testing between hosts (rhizome <-> plateau).
# iperf3 is installed on every host so either end can act as server or client,
# and 5201/tcp (iperf3's default control+data port) is opened so an incoming
# `iperf3 -s` is reachable across the LAN. The server only listens while you're
# actively running it, so the open port is inert the rest of the time.
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.iperf3 ];
  networking.firewall.allowedTCPPorts = [ 5201 ];
}
