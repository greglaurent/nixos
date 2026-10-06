{ config, lib, pkgs, ... }:
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

  # Books itself is the working tree, not Books/library. Bootstrap once using
  # the installed GitHub SSH config; never pull/reset an existing checkout.
  # Git refuses a nonempty destination, preserving any books already there.
  home.activation.cloneBooks = lib.hm.dag.entryAfter [ "linkGeneration" "ensureMarginaliaLibrary" ] ''
    books=${lib.escapeShellArg config.xdg.userDirs.extraConfig.BOOKS}
    if [ ! -e "$books/.git" ] && [ ! -L "$books/.git" ]; then
      run ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$books")"
      echo "books: cloning greglaurent/library directly into $books"
      run ${pkgs.git}/bin/git \
        -c core.sshCommand="${pkgs.openssh}/bin/ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new" \
        clone git@github.com:greglaurent/library.git "$books" \
        || echo "books: WARNING — clone failed; existing files were not overwritten. Check the destination, GitHub SSH access and network, then rebuild again." >&2
    fi
  '';
}
