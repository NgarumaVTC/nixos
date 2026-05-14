{ config, ... }:

{
  sops = {
    defaultSopsFile = ../../secrets/tc.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      tc_ssh_host_ed25519_key = {
        path = "/var/lib/tc-secrets/ssh_host_ed25519_key";
        mode = "0600";
      };
      tc_ssh_host_ed25519_key_pub = {
        path = "/var/lib/tc-secrets/ssh_host_ed25519_key.pub";
        mode = "0644";
      };
      lldap_bind_password = {};
    };

    # ENV-Datei mit LDAP-Passwort — NixOS' sssd-Modul nutzt envsubst,
    # ersetzt $LDAP_PASS in der Config zur Laufzeit.
    templates."students-sssd.env" = {
      mode = "0600";
      content = ''
        LDAP_PASS=${config.sops.placeholder.lldap_bind_password}
      '';
    };

    # SSSD-Konfiguration für Alpine hybridclient (wird in web01 bind-gemountet)
    templates."hybridclient-sssd.conf" = {
      mode = "0600";
      content = ''
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
        ldap_default_authtok = ${config.sops.placeholder.lldap_bind_password}

        ldap_id_use_start_tls = False
        ldap_tls_reqcert = never
        ldap_auth_disable_tls_never_use_in_production = True

        ldap_id_mapping = False
        ldap_user_uid_number = uidnumber
        ldap_user_gid_number = gidnumber

        fallback_homedir = /home/%u
        default_shell = /bin/sh

        cache_credentials = true
      '';
    };
  };
}
