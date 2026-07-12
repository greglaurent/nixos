{ config, ... }:
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
      # Path from myFlakeRoot (single source of truth), host from $(hostname) at
      # runtime — so the same alias rebuilds the right config on any machine.
      nix-rbs = "sudo nixos-rebuild switch --flake ${config.myFlakeRoot}#$(hostname)";
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

  programs.starship = {
    enable = true;
    settings = {
      # Command duration on the right edge, out of the way of the command line.
      # Referencing it here removes it from the left ($all), so it isn't
      # duplicated.
      right_format = "$cmd_duration";

      # Host always visible — you rebuild per-host (#plateau / #rhizome), so the
      # prompt should say which machine you're on even locally.
      hostname = {
        ssh_only = false;
        format = "[$hostname](bold blue) ";
      };

      # Which flake devShell is active (nix-direnv exports IN_NIX_SHELL); shows
      # the shell name so you can tell which project's env you dropped into.
      nix_shell = {
        format = "[$symbol$name]($style) ";
        symbol = "❄️ ";
        style = "bold cyan";
      };

      # Time long commands (nixos-rebuild, cargo) — only when they actually run
      # long enough to care about. Shown right-aligned via right_format above.
      cmd_duration = {
        min_time = 2000; # ms
        format = "took [$duration]($style)";
        style = "yellow";
      };

      directory = {
        truncation_length = 4;
        truncate_to_repo = true;
      };

      # Language version modules. Your Doom :lang stack (init.el) — rust, python,
      # cc, javascript/web (node), lua, sh, nix, typst, yaml, markdown — is left
      # on; starship only shows each when its files are present. Silence the
      # default-on languages outside that stack so the prompt stays clean.
      golang.disabled = true;
      java.disabled = true;
      kotlin.disabled = true;
      scala.disabled = true;
      swift.disabled = true;
      dart.disabled = true;
      ruby.disabled = true;
      php.disabled = true;
      perl.disabled = true;
      elixir.disabled = true;
      erlang.disabled = true;
      haskell.disabled = true;
      ocaml.disabled = true;
      julia.disabled = true;
      zig.disabled = true;
      dotnet.disabled = true;
    };
  };
}
