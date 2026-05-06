{ config, pkgs, ... }:
{
  containers.mgmt1 = {
    bindMounts = {
      "/etc/nixos" = { hostPath = "/etc/nixos"; isReadOnly = false; };
    };

    config = { config, pkgs, ... }: 
      let
        net = import ../../../common/network.nix;
        yamlFormat = pkgs.formats.yaml { };
        ansibleInventory = {
          all = {
            hosts = builtins.mapAttrs (name: node: {
              ansible_host = node.ip;
              mac_address = node.mac or "unknown";
              vlan_id = node.vlan;
            }) net.nodes;
          };
        };
      in {
        environment.systemPackages = with pkgs; [ ansible sshpass ];
        environment.etc."ansible/inventory.yml".source = yamlFormat.generate "inventory.yml" ansibleInventory;
      };
  };
}
