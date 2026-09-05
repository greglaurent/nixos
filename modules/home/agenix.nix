# Generic home-side agenix support. Opt in by importing this module in a user's
# home config. It warns — at activation, on EVERY switch however invoked (raw
# `sudo nixos-rebuild` included) — if this user's master identity is missing: the
# one carried key that edits/rekeys and recovers every secret, never stored in the
# repo. Override myAgenix.identityPath per user/machine if it lives elsewhere.
#
# Runtime check, deliberately: at eval `builtins.pathExists` on a home path is blind
# under pure eval (always false — verified), so an eval-time assertion can't see it.
# Warn-only: a rebuild on a working host doesn't need the file, so it never blocks.
{ config, lib, ... }:
{
  options.myAgenix.identityPath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.config/agenix/identity.txt";
    description = "This user's agenix master identity (age private key). Never committed; back up off-machine.";
  };

  config.home.activation.checkAgenixIdentity = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${config.myAgenix.identityPath}" ]; then
      echo "⚠ agenix master identity missing: ${config.myAgenix.identityPath}" >&2
      echo "  restore it from your password manager / USB — it's the one file that recovers every secret." >&2
    fi
  '';
}
