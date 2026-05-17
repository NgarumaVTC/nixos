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
    zfs.forceImportAll = true;      # homes-Pool hatte fremden hostid nach Installer-Import
    zfs.extraPools = [ "homes" ];   # Schüler-Homes auf separatem Pool (sdd)
  };

  # 2. Netzwerk (Routing & Bridge)
  networking = {
    firewall.enable = false;
    hostName = "mkuu1";
    hostId = "445febef";
    useDHCP = false;
    defaultGateway = "172.20.0.1";
    nameservers = [ "172.20.0.1" ];

    usePredictableInterfaceNames = false;

    bridges."br0".interfaces = [ "eth0" ];
    interfaces.br0.ipv4.addresses = [{
      address = "172.20.0.10";
      prefixLength = 24;
    }];
    vlans."vlan90" = {
      interface = "eth0";
      id = 90;
    };
    bridges."br90".interfaces = [ "vlan90" ];
    interfaces.br90.ipv4.addresses = [{
      address = "172.20.90.10";
      prefixLength = 24;
    }];
  };

  # 3. ZFS Dateisysteme — alle Datasets aus zroot (disko.nix)
  fileSystems = {
    "/"                         = { device = "zroot/root";         fsType = "zfs"; };
    "/nix"                      = { device = "zroot/nix";          fsType = "zfs"; };
    "/home"                     = { device = "zroot/home";         fsType = "zfs"; };
    "/var/lib/nixos-containers" = { device = "zroot/containers";   fsType = "zfs"; };
    "/media/ClassMaterial"      = { device = "zroot/classmaterial"; fsType = "zfs"; };
  };

  # 4. NFS-Exports: /nix/store (Client-Root) + /home (User-Daten)
  services.nfs.server = {
    enable = true;
    exports = ''
      /nix/store  172.20.90.0/24(ro,sync,no_subtree_check,no_root_squash)
      /home       172.20.90.0/24(rw,sync,no_subtree_check,no_root_squash)
    '';
  };

  # 5. Host-spezifische Erweiterungen
  users.users.ramge.extraGroups = [ "zfs" ];

  # /media/ClassMaterial gehoert der lldap_teacher-Gruppe (gid 4002).
  # Setgid-Bit (2) sorgt dafuer dass neue Files die Group erben.
  systemd.tmpfiles.rules = [
    "d /media/ClassMaterial 2775 root 4002 -"
  ];

  environment.systemPackages = with pkgs; [
    bridge-utils claude-code
    pciutils usbutils dmidecode smartmontools ethtool
    tcpdump nmap mtr
  ];
}
