{ config, pkgs, ... }:
let
  net      = import ../../common/network.nix;
  myConfig = net.nodes.web01;
  alpine   = import ../hybridclient/alpine-image.nix { inherit pkgs; };

  customIpxe = pkgs.ipxe.override {
    embedScript = pkgs.writeText "embed.ipxe" ''
      #!ipxe
      dhcp
      chain http://${myConfig.ip}/boot.ipxe
    '';
  };
in {
  containers.web01 = {
    bindMounts."/run/hybridclient-nslcd.conf" = {
      hostPath   = config.sops.templates."hybridclient-nslcd.conf".path;
      isReadOnly = true;
    };

    config = { config, pkgs, ... }: {
      networking.firewall.enable = false;

      services.nginx = {
        enable = true;
        commonHttpConfig = ''
          proxy_cache_path /var/cache/nginx/apk
            levels=2
            keys_zone=apk_cache:10m
            inactive=90d
            max_size=2g
            use_temp_path=off;
          resolver 1.1.1.1 valid=60s;
        '';
        virtualHosts."web01" = {
          root        = "/var/www/public";
          extraConfig = ''
            autoindex on;
            location /apks/ {
              proxy_pass         https://dl-cdn.alpinelinux.org/alpine/v3.21/;
              proxy_ssl_server_name on;
              proxy_cache        apk_cache;
              proxy_cache_valid  200 90d;
              proxy_cache_use_stale error timeout updating;
              proxy_cache_lock   on;
            }
          '';
        };
      };
      services.atftpd = { enable = true; root = "/var/www/public"; };
      systemd.tmpfiles.rules = [ "d /var/www/public 0755 nginx nginx -" "d /var/cache/nginx/apk 0750 nginx nginx -" ];

      systemd.services.deploy-pxe = {
        description = "Deploy Alpine hybridclient PXE files";
        wantedBy    = [ "multi-user.target" ];
        path        = [ pkgs.gzip pkgs.coreutils pkgs.gnutar ];
        serviceConfig = {
          Type            = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ln -sf ${customIpxe}/undionly.kpxe /var/www/public/undionly.kpxe
          ln -sf ${customIpxe}/ipxe.efi       /var/www/public/ipxe.efi
          ln -sf ${alpine.vmlinuz}   /var/www/public/vmlinuz-lts
          ln -sf ${alpine.initramfs} /var/www/public/initramfs-lts
          ln -sf ${alpine.modloop}   /var/www/public/modloop-lts

          WORK=$(mktemp -d)
          trap "rm -rf $WORK" EXIT

          mkdir -p \
            "$WORK"/etc/apk \
            "$WORK"/etc/nslcd \
            "$WORK"/etc/local.d \
            "$WORK"/etc/runlevels/boot \
            "$WORK"/etc/runlevels/default \
            "$WORK"/etc/skel/.local/share/remmina

          # APK-Repositories
          printf 'http://${myConfig.ip}/apks/main\nhttp://${myConfig.ip}/apks/community\n' \
            > "$WORK"/etc/apk/repositories

          # Paketliste
          cat > "$WORK"/etc/apk/world << 'WORLD'
xfce4
xfce4-terminal
firefox-esr
remmina
freerdp
nss-pam-ldapd
nss-pam-ldapd-openrc
nfs-utils
dbus
elogind
polkit-elogind
lightdm
lightdm-gtk-greeter
ttf-dejavu
WORLD

          # nslcd-Config mit echtem LDAP-Passwort (aus sops-Template)
          cp /run/hybridclient-nslcd.conf "$WORK"/etc/nslcd/nslcd.conf
          chmod 600 "$WORK"/etc/nslcd/nslcd.conf

          # nsswitch.conf: LDAP für passwd/group/shadow aktivieren
          cat > "$WORK"/etc/nsswitch.conf << 'NSW'
passwd:   files ldap
group:    files ldap
shadow:   files ldap
hosts:    files dns
NSW

          # NFS-Home beim Login mounten
          cat > "$WORK"/etc/local.d/nfs-home.start << 'NFS'
#!/bin/sh
mount -t nfs 172.20.0.10:/home /home -o rw,soft,intr,timeo=30
NFS
          chmod +x "$WORK"/etc/local.d/nfs-home.start

          # Remmina-Verbindung zum students-Container
          cat > "$WORK"/etc/skel/.local/share/remmina/kazilab.remmina << 'REMMINA'
[remmina]
name=KaziLab Server
protocol=RDP
server=172.20.90.51
username=
width=1920
height=1080
REMMINA

          # OpenRC-Services
          ln -sf /etc/init.d/dbus    "$WORK"/etc/runlevels/boot/dbus
          ln -sf /etc/init.d/nslcd   "$WORK"/etc/runlevels/default/nslcd
          ln -sf /etc/init.d/lightdm "$WORK"/etc/runlevels/default/lightdm
          ln -sf /etc/init.d/local   "$WORK"/etc/runlevels/default/local

          tar czf /var/www/public/hybridclient.apkovl.tar.gz -C "$WORK" .

          cat > /var/www/public/boot.ipxe << 'IPXE'
#!ipxe
set base http://${myConfig.ip}
kernel ''${base}/vmlinuz-lts ip=dhcp modloop=''${base}/modloop-lts alpine_repo=''${base}/apks/main apkovl=''${base}/hybridclient.apkovl.tar.gz quiet
initrd ''${base}/initramfs-lts
boot
IPXE

          chown -R nginx:nginx /var/www/public
        '';
      };
    };
  };
}
