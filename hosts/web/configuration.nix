{ config, pkgs, ... }:
let
  net      = import ../../common/network.nix;
  myConfig = net.nodes.web01;
in {
  containers.web01 = {
    config = { config, pkgs, ... }: {
      networking.firewall.enable = false;

      services.nginx = {
        enable = true;
        virtualHosts."web01" = {
          root        = "/var/www/public";
          extraConfig = ''
            autoindex on;
          '';
        };
      };

      services.atftpd = { enable = true; root = "/var/www/public"; };

      systemd.tmpfiles.rules = [
        "d /var/www/public 0755 nginx nginx -"
      ];

      # TODO Phase 3: NixOS netboot deploy-service hier ergaenzen
      # - Kernel + Initrd aus NixOS-Client-Build verlinken
      # - iPXE-Script fuer NFS-Root generieren
    };
  };
}
