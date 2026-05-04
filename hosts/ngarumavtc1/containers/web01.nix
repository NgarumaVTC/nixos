{ config, pkgs, ... }:

{
  containers.web01 = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br0";

    config = { config, pkgs, ... }: 
      let
        # 1. Das zentrale Lexikon importieren
        net = import ../../../common/network.nix;
        myConfig = net.nodes.web01;

        tcEval = import (pkgs.path + "/nixos/lib/eval-config.nix") {
          system = "x86_64-linux";
          modules = [ ./tc-image.nix ];
        };
        targetInit = "${tcEval.config.system.build.toplevel}/init";
      in {
        imports = [ ../../../common/default.nix ../../../common/ct.nix ];

        networking = {
          firewall.enable = false;

          hostName = "web01";
          useDHCP = false;
          
          # 2. Werte aus dem Lexikon ziehen
          defaultGateway = net.gateways.default;
          interfaces.eth0 = {
            ipv4.addresses = [{ address = myConfig.ip; prefixLength = 24; }];
            macAddress = myConfig.mac;
          };
        };

        services.nginx.enable = true;
        services.nginx.virtualHosts."web01" = { root = "/var/www/public"; extraConfig = "autoindex on;"; };
        services.atftpd = { enable = true; root = "/var/www/public"; };
        systemd.tmpfiles.rules = [ "d /var/www/public 0755 nginx nginx -" ];

        systemd.services.deploy-pxe = {
          description = "Deploy PXE files";
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Type = "oneshot";
          script = ''
            ln -sf ${tcEval.config.boot.customIpxe}/undionly.kpxe /var/www/public/undionly.kpxe
            ln -sf ${tcEval.config.system.build.kernel}/bzImage /var/www/public/bzImage
            ln -sf ${tcEval.config.system.build.netbootRamdisk}/initrd /var/www/public/initrd
            ln -sf ${tcEval.config.system.build.squashfsStore}/squashfs.img /var/www/public/squashfs.img

            cat > /var/www/public/boot.ipxe <<'EOF_IPXE'
#!ipxe
echo ========================================
echo !!! AFRIKA-BOOT-V10 (STAGE 2 INIT)   !!!
echo ========================================
# 3. IP in der iPXE-Datei dynamisch durch Nix setzen lassen
set base-url http://${myConfig.ip}
# Wir übergeben den berechneten Pfad als init= Argument
kernel ''${base-url}/bzImage initrd=initrd fetch=''${base-url}/squashfs.img init=${targetInit} boot.shell_on_fail console=tty1 ip=enp27s0:dhcp
initrd ''${base-url}/initrd
boot
EOF_IPXE
            chown -R nginx:nginx /var/www/public
          '';
        };
      };
  };
}
