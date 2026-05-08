{ config, pkgs, ... }:
{
  containers.web01 = {
    config = { config, pkgs, ... }: 
      let
        net = import ../../common/network.nix;
        myConfig = net.nodes.web01;
        tcEval = import (pkgs.path + "/nixos/lib/eval-config.nix") {
          system = "x86_64-linux";
          modules = [
            ../thin-client/image.nix
          ];
        };
        targetInit = "${tcEval.config.system.build.toplevel}/init";
        # iPXE-Loader gehört hierher, nicht ins TC-Image
        customIpxe = pkgs.ipxe.override {
          embedScript = pkgs.writeText "embed.ipxe" ''
            #!ipxe
            dhcp
            chain http://${myConfig.ip}/boot.ipxe
          '';
        };
      in {
        networking.firewall.enable = false;

        services.nginx.enable = true;
        services.nginx.virtualHosts."web01" = { root = "/var/www/public"; extraConfig = "autoindex on;"; };
        services.atftpd = { enable = true; root = "/var/www/public"; };
        systemd.tmpfiles.rules = [ "d /var/www/public 0755 nginx nginx -" ];

        systemd.services.deploy-pxe = {
          description = "Deploy PXE files";
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Type = "oneshot";
          script = ''
            ln -sf ${customIpxe}/undionly.kpxe /var/www/public/undionly.kpxe
            ln -sf ${customIpxe}/ipxe.efi /var/www/public/ipxe.efi
            ln -sf ${tcEval.config.system.build.kernel}/bzImage /var/www/public/bzImage
            ln -sf ${tcEval.config.system.build.netbootRamdisk}/initrd /var/www/public/initrd
            ln -sf ${tcEval.config.system.build.squashfsStore}/squashfs.img /var/www/public/squashfs.img

            cat > /var/www/public/boot.ipxe <<'EOF_IPXE'
#!ipxe
echo ========================================
echo !!! AFRIKA-BOOT-V11 (FIXED SIZE)     !!!
echo ========================================
set base-url http://${myConfig.ip}
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
