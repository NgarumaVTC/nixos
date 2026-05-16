# NixOS Netboot Client — diskless mit NFS /nix/store + tmpfs root
{ config, pkgs, lib, ... }:
let
  net = import ../../common/network.nix;
  server = "172.20.90.10";
  authServer = net.nodes.ctauth.ip;
in {
  imports = [
    ./software.nix
  ];

  system.stateVersion = "26.05";

  # --- Boot (PXE, kein Bootloader) ---
  boot.loader.grub.enable = false;
  boot.initrd.supportedFilesystems = [ "nfs" ];
  boot.initrd.systemd.contents."/etc/netconfig".source = "${pkgs.libtirpc}/etc/netconfig";
  boot.initrd.kernelModules = [ "i915" "r8169" "nfs" "nfsv3" "lockd" "sunrpc" ];
  boot.kernelParams = [ "panic=10" "quiet" ];

  # Netzwerk im initrd (systemd stage 1) — noetig fuer NFS-Mount vor switch_root
  boot.initrd.systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Type = "ether";
      networkConfig.DHCP = "yes";
    };
  };

  # --- Dateisysteme ---
  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=512M" "mode=0755" ];
  };

  fileSystems."/nix/store" = {
    device = "${server}:/nix/store";
    fsType = "nfs";
    options = [ "nfsvers=3" "ro" "nolock" "addr=172.20.90.10" ];
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "${server}:/home";
    fsType = "nfs";
    options = [ "nfsvers=3" "rw" "soft" "timeo=30" "addr=172.20.90.10" ];
  };

  # --- Netzwerk ---
  networking = {
    useDHCP = true;
    hostName = "";
  };

  # --- Desktop ---
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    xkb.layout = "de";
  };

  # --- LDAP-Auth via sssd ---
  services.sssd = {
    enable = true;
    config = ''
      [sssd]
      config_file_version = 2
      services = nss, pam
      domains = lldap

      [domain/lldap]
      id_provider = ldap
      auth_provider = ldap
      ldap_uri = ldap://${authServer}:3890
      ldap_search_base = dc=ngarumavtc,dc=lan
      ldap_default_bind_dn = uid=readonly,ou=people,dc=ngarumavtc,dc=lan
      ldap_default_authtok_type = password
      ldap_default_authtok = XTV8riqKZwwOFYnPBhNjcuSxnx7wAV6a

      ldap_id_use_start_tls = False
      ldap_tls_reqcert = never

      ldap_id_mapping = False
      ldap_user_uid_number = uidNumber
      ldap_user_gid_number = gidNumber

      fallback_homedir = /home/%u
      default_shell = /bin/sh
    '';
  };

  security.pam.services.login.makeHomeDir = true;

  security.pam.loginLimits = [
    { domain = "@users"; type = "hard"; item = "nproc"; value = "512"; }
    { domain = "@users"; type = "hard"; item = "nofile"; value = "2048"; }
  ];

  # --- System ---
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "de";

  nix.enable = false;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIsxiVYNp+LHETdBg14rYMaS13FJHa/29sD3PlLRglrn axel@ramge.de"
  ];
}
