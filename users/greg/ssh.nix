{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/gh_personal";
        IdentitiesOnly = true;
      };

      # Own machines on the LAN (sshd in modules/nixos/system.nix, key-only).
      # gh_personal isn't a default identity name, so name it explicitly or ssh
      # won't offer it → publickey failure. Log in as greg by default.
      "plateau plateau.local rhizome rhizome.local" = {
        User = "greg";
        IdentityFile = "~/.ssh/gh_personal";
        IdentitiesOnly = true;
      };

      # Self-hosted Forgejo, reached through a Cloudflare Access SSH tunnel.
      # The block name matches the repo remotes (git@git-ssh.abmac.io:...)
      # directly, so %h expands to git-ssh.abmac.io and no HostName rewrite
      # is needed.
      "git-ssh.abmac.io" = {
        User = "git";
        IdentityFile = "~/.ssh/gh_personal";
        IdentitiesOnly = true;
        ProxyCommand = "cloudflared access ssh --hostname %h";
      };
    };
  };
}
