{ config, pkgs, ... }:

{
  containers.ct90051 = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br90";

    config = { config, pkgs, ... }: 
      let
        # 1. Das zentrale Lexikon importieren
        net = import ../../../common/network.nix;
        myConfig = net.nodes.ct90051;
      in {
        imports = [ ../../../common/default.nix ../../../common/ct.nix ];

        networking = {
          hostName = "ct90051";
          useDHCP = false;
          
          # 2. Zentrale Variablen nutzen
          defaultGateway = net.gateways.students;
          
          interfaces.eth0 = {
            ipv4.addresses = [{ 
              address = myConfig.ip; 
              prefixLength = 24; 
            }];
            macAddress = myConfig.mac;
          };
        };

        services.xserver = {
          enable = true;
          desktopManager.xfce.enable = true;
        };

        services.xrdp = {
          enable = true;
          defaultWindowManager = "startxfce4";
          openFirewall = true;
        };

        users.users.student = {
          isNormalUser = true;
          password = "studentpassword"; 
          extraGroups = [ "video" "audio" ];
        };

        system.stateVersion = "26.05";
      };
  };
}
