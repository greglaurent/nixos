# System-wide (root-included) SSH client config for private git+ssh flake
# inputs. `nix-rbs` (users/greg/zsh.nix) runs `sudo nixos-rebuild switch`,
# so the WHOLE build — including fetching typst-libs/cascade over git+ssh —
# happens as root. users/greg/ssh.nix is home-manager: it only ever writes
# greg's own ~/.ssh/config, so root has no identity for github.com and every
# root-driven fetch fails with "Permission denied (publickey)" even though
# gh_personal is a valid, GitHub-trusted key. This is the system-level
# `programs.ssh` module (distinct from home-manager's), applying to every
# user including root.
{ ... }:
{
  programs.ssh.extraConfig = ''
    Host github.com
      User git
      IdentityFile /run/agenix/gh_personal
      IdentitiesOnly yes
  '';
}
