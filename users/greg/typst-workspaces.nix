# Live @local Typst checkouts: where they live, and a clone-if-missing bootstrap.
#
# The typst-libs home module creates an mkOutOfStoreSymlink from Typst's @local
# namespace to its live checkout, so edits are picked up in place. cascade's @local
# comes from its flake (a store path), so its checkout is DEV-ONLY. nix can't
# generate these mutable working trees, so this module clones each once, if missing.
#
# Secrets stay out of scope: the clone uses your SSH key over the github.com
# block from ssh.nix. Seed ~/.ssh/gh_personal first (sops/agenix can automate
# that later); until then the clone just warns and skips — it never aborts.
{ config, pkgs, lib, ... }:
let
  # typst-libs' symlink target is a home-manager option (myTypstLibsDir). cascade's checkout is
  # DEV-ONLY now (its @local comes from the flake), so it's just a local path here — no option.
  # URLs match the flake inputs (cascade's repo is `cascade-typography`; its folder keeps the -v2 name).
  cascadeDir = "${config.home.homeDirectory}/Workspace/cascade-typography-v2";
  workspaces = [
    { dir = config.myTypstLibsDir; url = "git@github.com:greglaurent/typst-libs.git"; }
    { dir = cascadeDir;            url = "git@github.com:greglaurent/cascade-typography.git"; }
  ];
in
{
  myTypstLibsDir = "${config.home.homeDirectory}/Workspace/typst-libs";

  # Idempotent (skips existing trees) and NON-FATAL — a missing key or network
  # only warns, so it can never wedge `nixos-rebuild` / `home-manager switch`.
  # Runs after writeBoundary so ~/.ssh/config (github.com → gh_personal) is in place;
  # accept-new handles github.com's host key on a first, never-seen-before connect.
  home.activation.cloneTypstWorkspaces = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatMapStrings (w: ''
      if [ ! -e "${w.dir}" ]; then
        echo "typst-workspaces: cloning ${w.url} → ${w.dir}"
        ${pkgs.git}/bin/git \
          -c core.sshCommand="${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new" \
          clone "${w.url}" "${w.dir}" \
          || echo "typst-workspaces: WARNING — clone of ${w.url} failed; seed ~/.ssh/gh_personal and re-run 'home-manager switch'"
      fi
    '') workspaces
  );
}
