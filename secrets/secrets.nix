# agenix recipient rules — WHO can decrypt each secret. Not encrypted; only public
# keys live here. `agenix -e/-r` reads this to know who to encrypt to; the NixOS
# `age.secrets` blocks reference the resulting <name>.age files.
let
  # Admin identity (age): greg's workstation key. Its PRIVATE half lives at
  # ~/.config/agenix/identity.txt and is NEVER committed — it only edits/rekeys
  # secrets. This is the public half.
  greg = "age1g9akjwfqm7x2qvj5ey948w77mvjrq0y77nmjfkrs53faprf4gerqkxsy0u";

  # Host keys (/etc/ssh/ssh_host_ed25519_key.pub): each machine decrypts its
  # secrets at activation using its own host key. Add a new host here + rekey.
  rhizome = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAscroZdg4emds7jDvOHpgufajmkjI+m/O4jRP7QwH7 root@rhizome";
  plateau = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMNDbdEIEMhgFRe7n57We90sI8dKvf3OwANq6h6X20PM root@plateau";

  hosts = [ rhizome plateau ];
in
{
  # gh_personal: greg's GitHub SSH key. Decryptable by greg (to edit) and by both
  # hosts (to place at /run/agenix/gh_personal for git/ssh).
  "gh_personal.age".publicKeys = [ greg ] ++ hosts;
}
