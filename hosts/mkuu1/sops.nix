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

    # lldap-Container: JWT-Secret + Admin-Passwort via Bind-Mount
    templates."lldap.env" = {
      path = "/var/lib/secrets/lldap.env";
      mode = "0600";
      content = ''
        LLDAP_JWT_SECRET=${config.sops.placeholder.lldap_bind_password}
        LLDAP_LDAP_USER_PASS=${config.sops.placeholder.lldap_bind_password}
      '';
    };
  };
}
