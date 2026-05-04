{ config, pkgs, ... }:

{
  containers.mgmt1 = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br0";
    
    bindMounts = {
      "/etc/nixos" = { hostPath = "/etc/nixos"; isReadOnly = false; };
    };

    config = { config, pkgs, ... }: 
      let
        net = import ../../../common/network.nix;
        myConfig = net.nodes.mgmt1;

        # --- INVENTORY GENERIERUNG ---
        # Nix-Formatierer für YAML laden
        yamlFormat = pkgs.formats.yaml { };
        
        # Das Nix-Lexikon in eine Ansible-taugliche Struktur umwandeln
        ansibleInventory = {
          all = {
            hosts = builtins.mapAttrs (name: node: {
              ansible_host = node.ip;
              # Fallback, falls ein Gerät (wie tc01) noch keine MAC eingetragen hat
              mac_address = node.mac or "unknown";
              vlan_id = node.vlan;
            }) net.nodes;
          };
        };
      in {
        imports = [
          ../../../common/default.nix
          ../../../common/ct.nix
        ];

        networking = {
          hostName = "mgmt1";
          useDHCP = false;
          defaultGateway = net.gateways.default;
          
          interfaces.eth0 = {
            ipv4.addresses = [{
              address = myConfig.ip;
              prefixLength = 24;
            }];
            macAddress = myConfig.mac;
          };
        };

        environment.systemPackages = with pkgs; [
          ansible
          sshpass
        ];

        # --- INVENTORY BEREITSTELLEN ---
        # Schreibt die generierte YAML-Struktur direkt in den Container
        environment.etc."ansible/inventory.yml".source = yamlFormat.generate "inventory.yml" ansibleInventory;
      };
  };
}
