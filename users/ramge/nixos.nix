{ config, pkgs, ... }:

{
  users.users.ramge = {
    isNormalUser = true;
    uid = 1001;
    description = "Axel Ramge";
    extraGroups = [ "wheel" ];
    shell = pkgs.bash; # Zurück zum Standard, spart ZSH-Konfig-Frust
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIsxiVYNp+LHETdBg14rYMaS13FJHa/29sD3PlLRglrn axel@ramge.de"
    ];
  };

  # Nur das Nötigste im System
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    tmux
  ];
}
