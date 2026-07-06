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

      # zsh-autosuggestions' default highlight (fg=8) is near-invisible on many
      # themes, so suggestions look "missing". Use a readable mid-grey. Read
      # lazily by the plugin at display time, so setting it here is fine.
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=245"
    '';
  };

  programs.starship.enable = true;
}
