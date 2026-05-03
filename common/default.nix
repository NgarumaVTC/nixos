{ config, pkgs, ... }:

{
  imports = [
    ../users/ramge/nixos.nix
  ];

  time.timeZone = "Africa/Dar_es_Salaam";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "de";

  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  security.sudo.wheelNeedsPassword = false;
  
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  environment.systemPackages = with pkgs; [
    vim git htop tmux zsh
  ];
}
