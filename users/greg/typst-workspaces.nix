# Live @local Typst checkouts: where they live, and a clone-if-missing bootstrap.
#
# The typst-libs / cascade home modules create mkOutOfStoreSymlinks from Typst's
# @local namespace to these working trees, so edits are picked up in place. nix
# owns the symlinks and these dir options, but it CANNOT generate the mutable
# working trees themselves — on a fresh machine the symlink targets would dangle.
# This module closes that chicken-egg: clone each tree once, only if missing.
#
# Secrets stay out of scope: the clone uses your SSH key over the github.com
# block from ssh.nix. Seed ~/.ssh/gh_personal first (sops/agenix can automate
# that later); until then the clone just warns and skips — it never aborts.
{ config, pkgs, lib, ... }:
let
  # Source of truth for both the symlink targets (consumed by the typst-libs /
  # cascade home modules) and the clone bootstrap below. URLs match the flake
  # inputs (cascade's repo is `cascade-typography`; its folder keeps the -v2 name).
  workspaces = [
    { dir = config.myTypstLibsDir; url = "git@github.com:greglaurent/typst-libs.git"; }
    { dir = config.myCascadeDir;   url = "git@github.com:greglaurent/cascade-typography.git"; }
  ];
in
{
  myTypstLibsDir = "${config.home.homeDirectory}/Workspace/typst-libs";
  myCascadeDir   = "${config.home.homeDirectory}/Workspace/cascade-typography-v2";

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
