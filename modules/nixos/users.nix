{ config, lib, pkgs, ... }:
let
  cfg = config.myUsers;
in {
  options.myUsers = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Users present on this host: ../../users).";
  };

  config = {
    users.users = lib.genAttrs cfg (name:
      let account = ../../users/${name}/account.nix;
      in { isNormalUser = true; }
         // lib.optionalAttrs (builtins.pathExists account) (import account { inherit pkgs; })
    );

    home-manager.backupFileExtension = "bak";
    home-manager.users = lib.genAttrs cfg (name: {
      imports = [ ../../users/${name} ];
      home.username = name;
      home.homeDirectory = "/home/${name}";
      home.stateVersion = "26.05";
    });
  };
}
