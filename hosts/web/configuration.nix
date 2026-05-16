{ config, pkgs, ... }:
let
  net      = import ../../common/network.nix;
  myConfig = net.nodes.web01;
  server   = net.nodes.ngarumavtc1.ip;

  # Pfad zum gebauten Client-System — nach jedem Rebuild aktualisieren
  clientSystem = "/nix/store/6jp5s5wx5ajc5f2jf8b0v3x8k2xch9ik-nixos-system-unnamed-26.05.20260430.15f4ee4";

  customIpxe = pkgs.ipxe.override {
    embedScript = pkgs.writeText "embed.ipxe" ''
      #!ipxe
      dhcp
      chain http://${myConfig.ip}/boot.ipxe
    '';
  };

  bootScript = pkgs.writeText "boot.ipxe" ''
    #!ipxe
    kernel http://${myConfig.ip}/vmlinuz init=${clientSystem}/init ip=dhcp root=/dev/nfs nfsroot=${server}:/export/nixos-client,nfsvers=4,ro quiet
    initrd http://${myConfig.ip}/initrd
    boot
  '';
in {
  containers.web01 = {
    config = { config, pkgs, ... }: {
      networking.firewall.enable = false;

      services.nginx = {
        enable = true;
        virtualHosts."web01" = {
          root = "/var/www/public";
          extraConfig = ''
            autoindex on;
          '';
        };
      };

      services.atftpd = { enable = true; root = "/var/www/public"; };

      systemd.tmpfiles.rules = [
        "d /var/www/public 0755 nginx nginx -"
      ];

      systemd.services.deploy-pxe = {
        description = "Deploy NixOS client PXE boot files";
        wantedBy    = [ "multi-user.target" ];
        serviceConfig = {
          Type            = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ln -sf ${customIpxe}/undionly.kpxe /var/www/public/undionly.kpxe
          ln -sf ${customIpxe}/ipxe.efi       /var/www/public/ipxe.efi
          ln -sf ${clientSystem}/kernel /var/www/public/vmlinuz
          ln -sf ${clientSystem}/initrd /var/www/public/initrd
          ln -sf ${bootScript}          /var/www/public/boot.ipxe
          chown -R nginx:nginx /var/www/public
        '';
      };
    };
  };
}
