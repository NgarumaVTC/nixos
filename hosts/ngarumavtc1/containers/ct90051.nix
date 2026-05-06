{ config, pkgs, ... }:
{
  containers.ct90051 = {
    bindMounts = {
      "/home/student10013" = { 
        hostPath = "/home/student10013"; 
        isReadOnly = false; 
      };
    };

    config = { config, pkgs, ... }: {
      imports = [ ../../../common/studentssoftware.nix ];

      # Stellt sicher, dass bash im Container-Systemprofil landet
      environment.systemPackages = [ pkgs.bash ];
      
      # Verlinkt /bin/sh
      environment.binsh = "${pkgs.bash}/bin/bash";

      services.xserver = {
        enable = true;
        desktopManager.xfce.enable = true;
      };

      services.xrdp = {
        enable = true;
        defaultWindowManager = "${pkgs.xfce.xfce4-session}/bin/xfce4-session";
        openFirewall = true;
      };

      users.ldap.enable = false;

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
          ldap_uri = ldap://172.20.90.12:3890
          ldap_search_base = dc=ngarumavtc,dc=lan
          ldap_default_bind_dn = uid=admin,ou=people,dc=ngarumavtc,dc=lan
          ldap_default_authtok_type = password
          ldap_default_authtok = NgarumaVTC
          
          ldap_id_use_start_tls = False
          ldap_tls_reqcert = never
          ldap_auth_disable_tls_never_use_in_production = True
          
          ldap_id_mapping = False
          ldap_user_uid_number = uidnumber
          ldap_user_gid_number = gidnumber
          
          # HIER: Wir nutzen den Standardpfad, den NixOS garantiert auflöst
          fallback_homedir = /home/%u
          default_shell = /run/current-system/sw/bin/bash
        '';
      };
    };
  };
}
