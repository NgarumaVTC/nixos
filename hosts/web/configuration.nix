{ config, pkgs, ... }:
let
  net      = import ../../common/network.nix;
  myConfig = net.nodes.web01;
  alpine   = import ../hybridclient/alpine-image.nix { inherit pkgs; };

  # apkovl aus Alpine-VM (lbu package), enthält alle Configs + Runlevels
  baseApkovl = ../hybridclient/apkovl.tar.gz;

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
      systemd.tmpfiles.rules = [
        "d /var/www/public 0755 nginx nginx -"
        "d /var/cache/nginx/apk 0750 nginx nginx -"
      ];

      systemd.services.deploy-pxe = {
        description = "Deploy Alpine hybridclient PXE files";
        wantedBy    = [ "multi-user.target" ];
        path        = [ pkgs.gzip pkgs.coreutils pkgs.gnutar pkgs.gnused ];
        serviceConfig = {
          Type            = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # iPXE-Loader
          ln -sf ${customIpxe}/undionly.kpxe /var/www/public/undionly.kpxe
          ln -sf ${customIpxe}/ipxe.efi       /var/www/public/ipxe.efi

          # Alpine Netboot-Kernel, initramfs, modloop
          ln -sf ${alpine.vmlinuz}   /var/www/public/vmlinuz-lts
          ln -sf ${alpine.initramfs} /var/www/public/initramfs-lts
          ln -sf ${alpine.modloop}   /var/www/public/modloop-lts

          # apkovl: VM-Basis entpacken, Patches anwenden, neu packen
          WORK=$(mktemp -d)
          trap "rm -rf $WORK" EXIT

          tar xzf ${baseApkovl} -C "$WORK"

          # --- Patches auf die VM-Basis ---

          # LDAP-Passwort aus sops-Template
          cp /run/hybridclient-nslcd.conf "$WORK"/etc/nslcd.conf
          chmod 600 "$WORK"/etc/nslcd.conf

          # APK-Repos auf lokalen Proxy
          printf 'http://${myConfig.ip}/apks/main\nhttp://${myConfig.ip}/apks/community\n' \
            > "$WORK"/etc/apk/repositories

          # DNS (Kernel-DHCP setzt kein resolv.conf)
          printf 'nameserver 172.20.90.1\n' \
            > "$WORK"/etc/resolv.conf

          # fix-rootperms: Alpine setzt / auf 700 (tmpfs), muss 755 sein
          # MUSS in sysinit laufen, VOR allen Services die als non-root starten
          mkdir -p "$WORK"/etc/init.d
          cat > "$WORK"/etc/init.d/fix-rootperms << 'FIXRP'
#!/sbin/openrc-run
description="Fix root directory permissions (Alpine sets / to 700 on tmpfs)"
depend() {
    before *
}
start() {
    ebegin "Setting / to 755"
    chmod 755 /
    eend $?
}
FIXRP
          chmod +x "$WORK"/etc/init.d/fix-rootperms
          mkdir -p "$WORK"/etc/runlevels/sysinit
          ln -sf /etc/init.d/fix-rootperms "$WORK"/etc/runlevels/sysinit/fix-rootperms

          # nslcd: "need net" → "need localmount" + start_pre mkdir
          if [ -f "$WORK"/etc/init.d/nslcd ]; then
            sed -i 's/need net/need localmount/' "$WORK"/etc/init.d/nslcd
          else
            cat > "$WORK"/etc/init.d/nslcd << 'NSLCD_INIT'
#!/sbin/openrc-run
extra_commands="checkconfig"
cfg="/etc/nslcd.conf"
command=/usr/sbin/nslcd
pidfile=/var/run/nslcd/nslcd.pid

depend() {
	need localmount
	after firewall
	use dns logger
}

checkconfig() {
	if [ -f "$cfg" ] ; then
		return 0
	fi
	eerror "Please create $cfg"
	return 1
}

start_pre() {
	checkconfig || return 1
	mkdir -p /var/run/nslcd
	chown nslcd:nslcd /var/run/nslcd
}
NSLCD_INIT
            chmod +x "$WORK"/etc/init.d/nslcd
          fi

          # xprop in world (Remmina braucht es)
          grep -q xprop "$WORK"/etc/apk/world || echo xprop >> "$WORK"/etc/apk/world

          # --- Fertig packen ---
          tar czf /var/www/public/hybridclient.apkovl.tar.gz -C "$WORK" .

          # boot.ipxe
          cat > /var/www/public/boot.ipxe << 'IPXE'
#!ipxe
set base http://${myConfig.ip}
kernel ''${base}/vmlinuz-lts ip=dhcp modloop=''${base}/modloop-lts alpine_repo=''${base}/apks/main apkovl=''${base}/hybridclient.apkovl.tar.gz video=HDMI-A-1:1280x1024@60 quiet
initrd ''${base}/initramfs-lts
boot
IPXE

          chown -R nginx:nginx /var/www/public
        '';
      };
    };
  };
}
