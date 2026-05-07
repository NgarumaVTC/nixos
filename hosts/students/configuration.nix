{ config, pkgs, ... }:

{
  containers.students = {
    bindMounts = {
      "/home" = {
        hostPath = "/home";
        isReadOnly = false;
      };
      # ENV-Datei mit LDAP-Passwort (sops-Template) — wird von sssd preStart gelesen
      "/run/sssd.env" = {
        hostPath = config.sops.templates."students-sssd.env".path;
        isReadOnly = true;
      };
    };

    config = { config, pkgs, ... }: {
      imports = [ ./software.nix ];

      environment.systemPackages = [ pkgs.bash ];
      environment.binsh = "${pkgs.bash}/bin/bash";

      services.xserver = {
        enable = true;
        desktopManager.xfce.enable = true;
      };

      services.xrdp = {
        enable = true;
        defaultWindowManager = "${pkgs.xfce4-session}/bin/xfce4-session";
        openFirewall = true;
      };

      users.ldap.enable = false;

      services.sssd = {
        enable = true;
        # $LDAP_PASS wird von envsubst aus EnvironmentFile substituiert
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
          ldap_default_authtok = $LDAP_PASS

          ldap_id_use_start_tls = False
          ldap_tls_reqcert = never
          ldap_auth_disable_tls_never_use_in_production = True

          ldap_id_mapping = False
          ldap_user_uid_number = uidnumber
          ldap_user_gid_number = gidnumber

          fallback_homedir = /home/%u
          default_shell = /run/current-system/sw/bin/bash
        '';
      };

      systemd.services.sssd.serviceConfig.EnvironmentFile = "/run/sssd.env";

      # Home-Verzeichnisse beim ersten LDAP-Login automatisch anlegen
      security.pam.services.xrdp-sesman.makeHomeDir = true;

      # PAM-Limits: verhindert Fork-Bombs und Dateideskriptor-Erschöpfung
      security.pam.loginLimits = [
        { domain = "@users"; type = "hard"; item = "nproc"; value = "512"; }
        { domain = "@users"; type = "hard"; item = "nofile"; value = "2048"; }
      ];

      # Gesamtbudget für alle Schüler-Sessions im Container
      systemd.slices.user = {
        sliceConfig = {
          MemoryMax = "20G";
          MemorySwapMax = "0";
        };
      };
    };
  };
}
