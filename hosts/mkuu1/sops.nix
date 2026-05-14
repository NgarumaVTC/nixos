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

    # nslcd-Konfiguration für Alpine hybridclient (wird in web01 bind-gemountet)
    # nss-pam-ldapd ist der Alpine-Ersatz für sssd (musl-kompatibel)
    templates."hybridclient-nslcd.conf" = {
      mode = "0600";
      content = ''
        uid nslcd
        gid nslcd

        uri ldap://172.20.90.12:3890
        base dc=ngarumavtc,dc=lan
        binddn uid=admin,ou=people,dc=ngarumavtc,dc=lan
        bindpw ${config.sops.placeholder.lldap_bind_password}

        ssl off
        tls_reqcert never

        map passwd uid              uid
        map passwd uidNumber        uidNumber
        map passwd gidNumber        gidNumber
        map passwd homeDirectory    homeDirectory
        map passwd loginShell       loginShell
      '';
    };
  };
}
