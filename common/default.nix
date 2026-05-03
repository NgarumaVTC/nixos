# /etc/nixos/common/default.nix
{ config, pkgs, ... }:

{
  # 1. Lokalisierung & Zeitzone
  time.timeZone = "Africa/Dar_es_Salaam";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "de";

  # 2. Nix & Paketverwaltung
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

  # 3. Globale Sicherheit & SSH
  security.sudo.wheelNeedsPassword = false;
  
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # 4. Globaler Administrator
  users.users.ramge = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Die ZFS-Gruppe kommt nur auf den Host
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWFdG02unkYNzRsOjrRSrSOc1s/feh2C9fOoOEAS4oA ramge@mbp2"
    ];
  };

  # 5. Globale Standard-Werkzeuge
  environment.systemPackages = with pkgs; [
    vim git htop tmux
  ];
}
