# greg's agenix admin side. The master identity (~/.config/agenix/identity.txt) is
# the ONE carried key that edits/rekeys and recovers every secret; it's never in the
# repo. This warns — at activation, on EVERY switch however it's invoked (raw
# `sudo nixos-rebuild` included, not just `nix-rbs`) — if it's absent, as the reminder
# to restore it from your password manager / USB on a fresh machine.
#
# Runtime check, deliberately: at eval `builtins.pathExists` on a home path is blind
# under pure eval (always false — verified), so an eval-time assertion can't see it.
# Warn-only: a rebuild on a working host doesn't need this file, so it never blocks.
{ config, lib, ... }:
{
  home.activation.checkAgenixIdentity = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/agenix/identity.txt" ]; then
      echo "⚠ agenix master identity missing: ~/.config/agenix/identity.txt" >&2
      echo "  restore it from your password manager / USB — it's the one file that recovers every secret." >&2
    fi
  '';
}
