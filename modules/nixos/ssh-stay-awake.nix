# Keep the machine awake while an SSH session is connected.
#
# Neither sshd nor logind does this on their own: logind's default IdleAction is
# "ignore", so what actually suspends these boxes is a *separate* idle mechanism
# (a desktop idle daemon calling `systemctl suspend`, or on rhizome lid-close ->
# suspend-then-hibernate), none of which know an SSH session is open. There is no
# `services.openssh` flag for it either — it has to be expressed as an inhibitor.
#
# So this service holds a systemd-inhibit BLOCK lock on `sleep` for as long as at
# least one inbound SSH connection is established, and drops it when the last one
# closes. A block/sleep lock makes logind REFUSE automatic suspend/hibernate
# (idle-daemon `systemctl suspend`, and lid-close on rhizome) while you're on —
# an explicit `systemctl suspend` you run by hand still overrides it, as intended.
#
# Detection is by established TCP connection to the local ssh port (22) rather
# than PAM/loginctl sessions, so it doesn't depend on session registration and
# covers IPv4+IPv6. Polled every 30s: a connect is noticed within 30s, and the
# lock lingers at most 30s after the last disconnect before sleep is allowed.
{ pkgs, ... }:
let
  monitor = pkgs.writeShellScript "ssh-sleep-inhibit-monitor" ''
    set -u
    inhibitor=""
    release() { [ -n "$inhibitor" ] && kill "$inhibitor" 2>/dev/null; inhibitor=""; }
    trap 'release; exit 0' TERM INT

    while :; do
      if ss -H -t state established '( sport = :ssh )' | grep -q .; then
        # (Re)arm the lock if we aren't already holding a live one.
        if [ -z "$inhibitor" ] || ! kill -0 "$inhibitor" 2>/dev/null; then
          systemd-inhibit --what=sleep --who=sshd \
            --why="SSH session connected" --mode=block \
            sleep infinity &
          inhibitor=$!
        fi
      else
        release
      fi
      sleep 30
    done
  '';
in
{
  systemd.services.ssh-stay-awake = {
    description = "Inhibit automatic sleep while an SSH session is connected";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    # ss (iproute2) + systemd-inhibit + grep/coreutils for the monitor loop.
    path = [ pkgs.iproute2 pkgs.systemd pkgs.gnugrep pkgs.coreutils ];
    serviceConfig = {
      ExecStart = monitor;
      Restart = "always";
      RestartSec = 5;
    };
  };
}
