{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      alias.st = "status";
    };
  };
}
