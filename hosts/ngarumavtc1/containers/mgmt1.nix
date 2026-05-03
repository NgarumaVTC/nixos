{ config, pkgs, ... }:

{
  containers.mgmt1 = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br0";
    
    # Durchreichen des NixOS-Git-Ordners für Ansible
    bindMounts = {
      "/etc/nixos" = { hostPath = "/etc/nixos"; isReadOnly = false; };
    };

    config = { config, pkgs, ... }: {
      imports = [
        ../../../common/default.nix
        ../../../common/ct.nix
      ];

      # Netzwerk (KISS: Statisch, passend zur MikroTik sLease .11)
      networking = {
        hostName = "mgmt1";
        useDHCP = false;
        defaultGateway = "172.20.0.1";
        nameservers = [ "172.20.0.1" ];
        interfaces.eth0.ipv4.addresses = [{
          address = "172.20.0.11";
          prefixLength = 24;
        }];
      };

      # mgmt1 spezifische Pakete
      environment.systemPackages = with pkgs; [
        ansible
        sshpass
      ];
    };
  };
}
