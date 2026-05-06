{ pkgs, modulesPath, config, lib, ... }:

let
  net = import ../../../common/network.nix;
  webConfig = net.nodes.web01;
  ctConfig = net.nodes.ct90051;
in
{
  imports = [
    (modulesPath + "/installer/netboot/netboot-base.nix")
    (modulesPath + "/profiles/minimal.nix")
  ];

  options = {
    boot = {
      customIpxe = lib.mkOption { type = lib.types.package; };
    };
  };

  config = {
    boot = {
      # Zwingt den 4K-Monitor direkt auf Full HD
      kernelParams = [ "video=1920x1080@60" ];
      
      customIpxe = pkgs.ipxe.override {
        embedScript = pkgs.writeText "embed.ipxe" ''
          #!ipxe
          dhcp
          chain http://${webConfig.ip}/boot.ipxe
        '';
      };

      initrd = {
        kernelModules = [ "amdgpu" "r8169" ];
        systemd = {
          enable = true;
          emergencyAccess = true;
          extraBin = {
            ip = "${pkgs.iproute2}/bin/ip";
            ping = "${pkgs.iputils}/bin/ping";
          };
          network = {
            enable = true;
            networks."10-enp27s0" = {
              matchConfig.Name = "enp27s0";
              networkConfig.DHCP = "yes";
            };
          };
        };
      };

      zfs = {
        forceImportRoot = false;
      };
    };

    hardware = {
      enableRedistributableFirmware = true;
      firmware = [
        (pkgs.runCommand "tc-firmware" {} ''
          mkdir -p $out/lib/firmware/amdgpu $out/lib/firmware/rtl_nic
          cp ${pkgs.linux-firmware}/lib/firmware/amdgpu/carrizo* $out/lib/firmware/amdgpu/
          cp ${pkgs.linux-firmware}/lib/firmware/rtl_nic/rtl8168h-2.fw $out/lib/firmware/rtl_nic/
        '')
      ];
    };

    services = {
      cage = {
        enable = true;
        user = "root";
        program = let
          kioskScript = pkgs.writeShellScriptBin "start-kiosk" ''
            while true; do
              # Fehlerkanal (2>) ins Nichts umleiten, damit die Variable klinisch rein bleibt
              USER=$(${pkgs.zenity}/bin/zenity --entry \
                --title="Ngaruma VTC" \
                --text="Benutzername (z. B. student10013):" \
                --ok-label="Weiter" \
                --cancel-label="Neu starten" 2>/dev/null)
              
              if [ -z "$USER" ]; then continue; fi

              PASS=$(${pkgs.zenity}/bin/zenity --password \
                --title="Ngaruma VTC" \
                --text="Passwort für $USER:" \
                --ok-label="Anmelden" \
                --cancel-label="Zurück" 2>/dev/null)
              
              if [ -z "$PASS" ]; then continue; fi

              # Der exakt gleiche Aufruf, der bei dir vorhin mit harten Strings funktioniert hat
              ${pkgs.freerdp}/bin/xfreerdp /v:${ctConfig.ip} /f /cert:ignore /network:lan /u:"$USER" /p:"$PASS"
              
              sleep 2
            done
          '';
        in "${kioskScript}/bin/start-kiosk";
      };

      getty = {
        autologinUser = lib.mkForce "root";
      };
      
      openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "yes";
        };
      };
    };

    system = {
      stateVersion = "26.05";
    };

    systemd = {
      services = {
        "getty@tty2" = {
          enable = true;
        };
      };
    };

    users = {
      users = {
        root = {
          initialHashedPassword = "";
          openssh = {
            authorizedKeys = {
              keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWFdG02unkYNzRsOjrRSrSOc1s/feh2C9fOoOEAS4oA ramge@mbp2"
              ];
            };
          };
        };
      };
    };
  };
}
