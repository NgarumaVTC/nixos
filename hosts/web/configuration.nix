{ config, pkgs, ... }:
let
  net      = import ../../common/network.nix;
  myConfig = net.nodes.web01;
  alpine   = import ../hybridclient/alpine-image.nix { inherit pkgs; };

  # iPXE-Loader mit eingebettetem DHCP+chain-Script
  customIpxe = pkgs.ipxe.override {
    embedScript = pkgs.writeText "embed.ipxe" ''
      #!ipxe
      dhcp
      chain http://${myConfig.ip}/boot.ipxe
    '';
  };
in {
  containers.web01 = {
    # sops-Template mit LDAP-Passwort in den Container reichen
    bindMounts."/run/hybridclient-sssd.conf" = {
      hostPath   = config.sops.templates."hybridclient-sssd.conf".path;
      isReadOnly = true;
    };

    config = { config, pkgs, ... }: {
      networking.firewall.enable = false;

      services.nginx.enable = true;
      services.nginx.virtualHosts."web01" = {
        root        = "/var/www/public";
        extraConfig = "autoindex on;";
      };
      services.atftpd = { enable = true; root = "/var/www/public"; };
      systemd.tmpfiles.rules = [ "d /var/www/public 0755 nginx nginx -" ];
      environment.systemPackages = [ pkgs.gzip ];

      systemd.services.deploy-pxe = {
        description = "Deploy Alpine hybridclient PXE files";
        wantedBy    = [ "multi-user.target" ];
        path = [ pkgs.gzip pkgs.coreutils pkgs.gnutar ];
        serviceConfig = {
          Type            = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # iPXE-Loader
          ln -sf ${customIpxe}/undionly.kpxe /var/www/public/undionly.kpxe
          ln -sf ${customIpxe}/ipxe.efi       /var/www/public/ipxe.efi

          # Alpine Netboot-Kernel, initramfs, modloop (aus Nix-Store)
          ln -sf ${alpine.vmlinuz}   /var/www/public/vmlinuz-lts
          ln -sf ${alpine.initramfs} /var/www/public/initramfs-lts
          ln -sf ${alpine.modloop}   /var/www/public/modloop-lts

          # apkovl zur Laufzeit bauen (braucht das sops-LDAP-Passwort)
          WORK=$(mktemp -d)
          trap "${pkgs.coreutils}/bin/rm -rf $WORK" EXIT

          ${pkgs.coreutils}/bin/mkdir -p \
            "$WORK"/etc/apk \
            "$WORK"/etc/sssd \
            "$WORK"/etc/local.d \
            "$WORK"/etc/runlevels/boot \
            "$WORK"/etc/runlevels/default \
            "$WORK"/etc/skel/.local/share/remmina

          # APK-Repositories (lokal auf web01)
          printf 'http://${myConfig.ip}/apks/main\nhttp://${myConfig.ip}/apks/community\n' \
            > "$WORK"/etc/apk/repositories

          # Paketliste — wird von Alpine beim Boot installiert
          ${pkgs.coreutils}/bin/cat > "$WORK"/etc/apk/world << 'WORLD'
xfce4
xfce4-terminal
firefox-esr
remmina
remmina-plugin-rdp
freerdp
sssd
sssd-ldap
nfs-utils
dbus
elogind
polkit-elogind
lightdm
lightdm-gtk-greeter
ttf-dejavu
WORLD

          # SSSD-Config mit echtem LDAP-Passwort (aus sops-Template)
          ${pkgs.coreutils}/bin/cp /run/hybridclient-sssd.conf "$WORK"/etc/sssd/sssd.conf
          ${pkgs.coreutils}/bin/chmod 600 "$WORK"/etc/sssd/sssd.conf

          # NFS-Home beim Login mounten
          ${pkgs.coreutils}/bin/cat > "$WORK"/etc/local.d/nfs-home.start << 'NFS'
#!/bin/sh
mount -t nfs 172.20.0.10:/home /home -o rw,soft,intr,timeo=30
NFS
          ${pkgs.coreutils}/bin/chmod +x "$WORK"/etc/local.d/nfs-home.start

          # Remmina-Verbindung zum students-Container vorgespeichert
          ${pkgs.coreutils}/bin/cat > "$WORK"/etc/skel/.local/share/remmina/kazilab.remmina << 'REMMINA'
[remmina]
name=KaziLab Server
protocol=RDP
server=172.20.90.51
username=
width=1920
height=1080
REMMINA

          # OpenRC-Services aktivieren
          ln -sf /etc/init.d/dbus    "$WORK"/etc/runlevels/boot/dbus
          ln -sf /etc/init.d/sssd    "$WORK"/etc/runlevels/default/sssd
          ln -sf /etc/init.d/lightdm "$WORK"/etc/runlevels/default/lightdm
          ln -sf /etc/init.d/local   "$WORK"/etc/runlevels/default/local

          # apkovl packen
          ${pkgs.gnutar}/bin/tar czf /var/www/public/hybridclient.apkovl.tar.gz \
            -C "$WORK" .

          # boot.ipxe für Alpine
          ${pkgs.coreutils}/bin/cat > /var/www/public/boot.ipxe << 'IPXE'
#!ipxe
set base http://${myConfig.ip}
kernel ''${base}/vmlinuz-lts ip=dhcp modloop=''${base}/modloop-lts alpine_repo=''${base}/apks/main apkovl=''${base}/hybridclient.apkovl.tar.gz quiet
initrd ''${base}/initramfs-lts
boot
IPXE

          ${pkgs.coreutils}/bin/chown -R nginx:nginx /var/www/public
        '';
      };
    };
  };
}
