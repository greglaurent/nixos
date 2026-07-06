{ ... }:
{
  imports = [ ../../modules/home/git.nix ];

  programs.git.settings.user = {
    name  = "Gregory Laurent";
    email = "gregory.m.laurent@gmail.com";
  };

  # Per-company / per-tree identity. Any repo under `condition` transparently
  # uses these values instead of the personal default above. Add one entry per
  # company; list entries merge across modules, so a dev module could contribute
  # its own instead of listing them all here.
  programs.git.includes = [
    # {
    #   condition = "gitdir:~/work/acme/";
    #   contents.user = {
    #     email = "greg@acme.com";
    #     # name = "Greg (Acme)";
    #     # signingKey = "…";
    #   };
    # }
  ];
}
