{ config, pkgs, ... }:

{
  boot.isContainer = true;
  system.stateVersion = "26.05";

  # SSH-Zugang für alle Container
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
