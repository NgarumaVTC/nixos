# /etc/nixos/hosts/ngarumavtc1/configuration.nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/default.nix
    ./sops.nix
    ./containers/base.nix
    ./containers/mgmt1.nix
    ./containers/web01.nix
    ./containers/ctauth.nix
    ./containers/students.nix
  ];

  system.stateVersion = "26.05";

  # 1. Bootloader & Kernel (Hardware-Ebene)
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
  };

  # 2. Netzwerk (Routing & Bridge)
  networking = {
    firewall.enable = false;
    hostName = "ngarumavtc1";
    hostId = "0346c59b";
    useDHCP = false;
    defaultGateway = "172.20.0.1";
    nameservers = [ "172.20.0.1" ];

    bridges."br0".interfaces = [ "enp2s0" ];
    interfaces.br0.ipv4.addresses = [{
      address = "172.20.0.10";
      prefixLength = 24;
    }];
    vlans."vlan90" = {
      interface = "enp2s0";
      id = 90;
    };
    bridges."br90".interfaces = [ "vlan90" ];
  };

  # 3. ZFS Dateisysteme (Storage-Ebene)
  fileSystems = {
    "/var/lib/nixos-containers" = { device = "tank/containers";  fsType = "zfs"; };
    "/home"                     = { device = "tank/data/homes";    fsType = "zfs"; };
    "/media/ClassMaterial"      = { device = "tank/data/lehrpult"; fsType = "zfs"; };
  };

  # 4. Host-spezifische Erweiterungen
  users.users.ramge.extraGroups = [ "zfs" ]; # Erweitert den User aus common/default.nix

  environment.systemPackages = with pkgs; [
    bridge-utils pciutils # Wird zu den Paketen aus common/default.nix hinzugefügt
  ];
}
