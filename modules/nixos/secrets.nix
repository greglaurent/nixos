# agenix: decrypt secrets/*.age at activation using this host's SSH host key
# (age.identityPaths defaults to /etc/ssh/ssh_host_ed25519_key), then place them
# where consumers expect. Recipients are declared in ../../secrets/secrets.nix.
{ agenix, ... }:
{
  imports = [ agenix.nixosModules.default ];

  # greg's GitHub / LAN / Forgejo SSH key. Lands at the default /run/agenix/gh_personal
  # (tmpfs — plaintext never persists to disk), owned by greg; users/greg/ssh.nix
  # points every IdentityFile there.
  age.secrets.gh_personal = {
    file  = ../../secrets/gh_personal.age;
    owner = "greg";
    mode  = "600";
  };
}
