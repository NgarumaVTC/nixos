{ config, pkgs, ... }:

{
  imports = [
    ../users/ramge/nixos.nix
  ];


  time.timeZone = "Europe/Berlin";
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
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIsxiVYNp+LHETdBg14rYMaS13FJHa/29sD3PlLRglrn axel@ramge.de"
  ];

  environment.systemPackages = with pkgs; [
    claude-code
    fzf
    gh
    git 
    htop 
    ripgrep
    tmux 
    vim 
    zsh 
  ];
}
