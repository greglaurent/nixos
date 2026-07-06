{ config, pkgs, lib, doom-emacs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" ] ++ config.myUsers;
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  # Kill the PC-speaker system beep (e.g. backspace with nothing focused) everywhere.
  boot.blacklistedKernelModules = [ "pcspkr" "snd_pcsp" ];
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 20;
    efi.canTouchEfiVariables = true;
  };

  services.printing.enable = true;
  services.fwupd.enable = true;
  services.automatic-timezoned.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  services.xserver.xkb = {
    layout = lib.mkDefault "us";
      variant = lib.mkDefault "";
    };

  security.rtkit.enable = true;

  networking.networkmanager.enable = lib.mkDefault true;

  hardware.bluetooth = {
    enable = lib.mkDefault true;
    powerOnBoot = lib.mkDefault true;
  };

  # time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  i18n.extraLocaleSettings = lib.mkDefault {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };  

  environment.systemPackages = with pkgs; [ zsh git neovim ];
  programs.git.enable = true;
  programs.zsh.enable = true;

  environment.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    NIXOS_OZONE_WL = "1";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit doom-emacs; };
  };
}
