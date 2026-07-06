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
  };

  programs.starship.enable = true;

  home.sessionVariables.DOCKER_HOST = "unix://$HOME/.config/containers/podman/podman.sock";
}
