{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/gh_personal.pub";
        IdentitiesOnly = true;
      };

      # Self-hosted Forgejo, reached via the `forgejo` alias. 
      # Set HostName to the real host; 
      # uncomment Port if SSH isn't on 22 (Forgejo often 2222).
      "forgejo" = {
        HostName = "FORGEJO_HOSTNAME";
        User = "git";
        # Port = 2222;
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
    };
  };
}
