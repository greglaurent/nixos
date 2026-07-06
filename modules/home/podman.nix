# Rootless podman, user side: the per-user API socket + DOCKER_HOST for
# docker-compatible tooling. Active only on hosts where the system enables
# podman (modules/nixos/podman.nix -> myPodman.enable), detected via osConfig,
# so this stays inert on hosts without podman.
{ osConfig, lib, ... }:
{
  config = lib.mkIf (osConfig.virtualisation.podman.enable or false) {
    # NixOS enables the rootful system socket; the rootless per-user socket must
    # be enabled here. Socket-activated, so podman starts on first connection.
    systemd.user.sockets.podman = {
      Unit.Description = "Podman API socket (rootless)";
      Socket = {
        ListenStream = "%t/podman/podman.sock";
        SocketMode = "0660";
      };
      Install.WantedBy = [ "sockets.target" ];
    };

    systemd.user.services.podman = {
      Unit = {
        Description = "Podman API service (rootless)";
        Requires = "podman.socket";
        After = "podman.socket";
      };
      Service = {
        Type = "exec";
        KillMode = "process";
        ExecStart = "${osConfig.virtualisation.podman.package}/bin/podman system service -t 0";
      };
      Install.Also = "podman.socket";
    };

    # docker-compatible clients (docker CLI/SDK, testcontainers, compose) talk to
    # the rootless socket. %t and $XDG_RUNTIME_DIR both resolve to /run/user/UID.
    home.sessionVariables.DOCKER_HOST = "unix://\${XDG_RUNTIME_DIR}/podman/podman.sock";
  };
}
