{ config, pkgs, lib, ... }:

{
  containers.ctauth = {
    bindMounts = {
      "/var/lib/lldap/secrets.env" = {
        hostPath = "/var/lib/secrets/lldap.env";
        isReadOnly = true;
      };
    };

    config = { config, pkgs, ... }: 
      let
        net = import ../../common/network.nix;
        myConfig = net.nodes.ctauth;
      in {
        services.lldap = {
          enable = true;
          silenceForceUserPassResetWarning = true;
          settings = {
            ldap_host = "0.0.0.0";
            http_host = "0.0.0.0";
            ldap_base_dn = "dc=ngarumavtc,dc=lan";
            ldap_port = 3890;
            http_port = 17170;
            http_url = "http://${myConfig.ip}:17170";
            ldap_user_pass_file = "/var/lib/lldap/secrets.env";
          };
          environmentFile = "/var/lib/lldap/secrets.env";
        };

        # DER FIX: Wir zwingen systemd, das Rechtemanagement zu ignorieren
        systemd.services.lldap.serviceConfig = {
          StateDirectory = lib.mkForce ""; 
          DynamicUser = lib.mkForce false;
          User = lib.mkForce "root";
          Group = lib.mkForce "root";
        };

        networking.firewall.allowedTCPPorts = [ 3890 17170 ];
      };
  };
}
