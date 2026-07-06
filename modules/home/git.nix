# Reusable git base — shared, identity-free config. Opt in per user, then set
# user.name/user.email at the user level. Uses the current HM API: everything
# lives under `programs.git.settings` (a freeform gitconfig attrset).
{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;   # new branches track on first push
      pull.rebase = true;            # linear history on pull
      alias.st = "status";
    };
  };
}
