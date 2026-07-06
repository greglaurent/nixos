{ ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true; 
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      ignoreAllDups = true;
      expireDuplicatesFirst = true;
      share = true;
    };

    shellAliases = {
      nix-rbs = "sudo nixos-rebuild switch --flake ~/.config/nixos#$(hostname)";
      vim = "neovim";
      ec = "emacsclient -c -a ''";
      et = "emacsclient -t -a ''";
    };

    # Emacs' vterm/term mis-detects partial lines and shows zsh's end-of-line
    # marker (a reverse-video '%') on every prompt. Blank it inside Emacs only,
    # so real terminals keep the (occasionally useful) marker.
    initContent = ''
      [[ -n "$INSIDE_EMACS" ]] && export PROMPT_EOL_MARK=""
    '';
  };

  programs.starship.enable = true;

  home.sessionVariables.DOCKER_HOST = "unix://$HOME/.config/containers/podman/podman.sock";
}
