# NixOS Netboot Client — diskless mit NFS /nix/store + tmpfs root
# Wird auf mkuu1 gebaut. Clients booten via PXE, mounten /nix/store per NFS.
{ config, pkgs, lib, ... }:
let
  net = import ../../common/network.nix;
  server = net.nodes.ngarumavtc1.ip;  # 172.20.0.10
  authServer = net.nodes.ctauth.ip;    # 172.20.90.12
in {
  imports = [
    ./software.nix
  ];

  system.stateVersion = "26.05";

  # --- Boot (PXE, kein Bootloader) ---
  boot.loader.grub.enable = false;
  boot.initrd.supportedFilesystems = [ "nfs" ];
  boot.initrd.kernelModules = [ "i915" "r8169" ];
  boot.initrd.network.enable = true;
  boot.kernelParams = [ "panic=10" "quiet" ];

  # --- Dateisysteme ---
  # Root: tmpfs (beschreibbar, fuer /etc /run /var etc.)
  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=512M" "mode=0755" ];
  };

  # Nix Store: NFS read-only (hier liegt das gesamte System)
  fileSystems."/nix/store" = {
    device = "${server}:/nix/store";
    fsType = "nfs";
    options = [ "nfsvers=4" "ro" "nolock" ];
    neededForBoot = true;
  };

  # Home: NFS read-write
  fileSystems."/home" = {
    device = "${server}:/home";
    fsType = "nfs";
    options = [ "nfsvers=4" "rw" "soft" "timeo=30" ];
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
      ldap_auth_disable_tls_never_use_in_production = True

      ldap_id_mapping = False
      ldap_user_uid_number = uidNumber
      ldap_user_gid_number = gidNumber

      fallback_homedir = /home/%u
      default_shell = /bin/sh
    '';
  };

  # Home-Verzeichnis beim ersten Login anlegen
  security.pam.services.login.makeHomeDir = true;

  # PAM-Limits gegen Fork-Bombs
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
