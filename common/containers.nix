{ config, lib, ... }:
let
  net = import ./network.nix;
  
  isContainer = name: node:
    name == "mgmt1" ||
    name == "web01" ||
    name == "students" ||
    builtins.substring 0 2 name == "ct";
    
  containerNodes = lib.filterAttrs isContainer net.nodes;
in {
  containers = lib.mapAttrs (name: node: {
    autoStart = true;
    privateNetwork = true;
    hostBridge = if node.vlan == 90 then "br90" else "br0";

    config = {
      imports = [
        ./default.nix
        ./ct.nix
      ];

      networking = {
        useDHCP = false;
        defaultGateway = if node.vlan == 90 then net.gateways.students else net.gateways.default;
        nameservers = [ (if node.vlan == 90 then net.gateways.students else net.gateways.default) ];

        interfaces.eth0 = {
          ipv4.addresses = [{
            address = node.ip;
            prefixLength = 24;
          }];
          macAddress = node.mac;
        };
      };
    };
  }) containerNodes;
}
