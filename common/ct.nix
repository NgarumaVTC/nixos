{ config, pkgs, ... }:
{
  boot.isContainer = true;
  system.stateVersion = "26.05";

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
