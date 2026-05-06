{ config, pkgs, ... }:

{
  containers.ct90052 = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br90"; # Wieder direkt ins Studenten-VLAN

    config = { config, pkgs, ... }: 
      let
        net = import ../../../common/network.nix;
        myConfig = net.nodes.ct90052;
      in {
        imports = [ ../../../common/default.nix ../../../common/ct.nix ];

        networking = {
          hostName = "ct90052";
          useDHCP = false;
          defaultGateway = net.gateways.students;
          
          interfaces.eth0 = {
            ipv4.addresses = [{ 
              address = myConfig.ip; 
              prefixLength = 24; 
            }];
            macAddress = myConfig.mac;
          };
          
          # RDP Port für den eingebauten GNOME Server freigeben
          firewall.allowedTCPPorts = [ 3389 ];
        };

        services = {
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = true;
          gnome.gnome-remote-desktop.enable = true;
        };

        users.users.student = {
          isNormalUser = true;
          password = "studentpassword"; 
          extraGroups = [ "video" "audio" ];
        };

        # Ein Tool, das wir gleich brauchen, um das RDP-Passwort zu setzen
        environment.systemPackages = with pkgs; [
          gnome-remote-desktop
        ];

        system.stateVersion = "26.05";
      };
  };
}
