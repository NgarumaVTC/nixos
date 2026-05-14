# /etc/nixos/hosts/mkuu1/configuration.nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/default.nix
    ../../common/containers.nix
    ./sops.nix
    ../auth/configuration.nix
    ../mgmt/configuration.nix
    ../web/configuration.nix
    ../students/configuration.nix
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
    zfs.devNodes = "/dev/disk/by-partlabel";
  };

  # 2. Netzwerk (Routing & Bridge)
  networking = {
    firewall.enable = false;
    hostName = "mkuu1";
    hostId = "445febef";
    useDHCP = false;
    defaultGateway = "172.20.0.1";
    nameservers = [ "172.20.0.1" ];

    bridges."br0".interfaces = [ "eno2" ];
    interfaces.br0.ipv4.addresses = [{
      address = "172.20.0.10";
      prefixLength = 24;
    }];
    vlans."vlan90" = {
      interface = "eno2";
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

  # 4. NFS-Export: Home-Verzeichnisse für hybridclient
  services.nfs.server = {
    enable = true;
    exports = ''
      /home  172.20.90.0/24(rw,sync,no_subtree_check,no_root_squash)
    '';
  };

  # 5. Host-spezifische Erweiterungen
  users.users.ramge.extraGroups = [ "zfs" ]; # Erweitert den User aus common/default.nix

  environment.systemPackages = with pkgs; [
    bridge-utils pciutils # Wird zu den Paketen aus common/default.nix hinzugefügt
  ];
}
