{ config, lib, pkgs, ... }:

# Synchronisiert /boot (primäre ESP) nach jedem nixos-rebuild auf alle
# weiteren ESPs der Maschine. Die Quelle wird automatisch aus
# config.fileSystems."/boot".device abgeleitet — alle anderen Einträge
# in services.efiSync.esps werden als Targets behandelt.
#
# Trigger: Änderung an /boot/loader/loader.conf, die bootctl nach
# jedem nixos-rebuild schreibt.
#
# Beispiel-Einbindung (3-Disk-RAID):
#   imports = [ ../../common/efi-sync.nix ];
#   services.efiSync = {
#     enable = true;
#     esps = [
#       "/dev/disk/by-partlabel/SN602891-EFI"  # = /boot → wird Quelle
#       "/dev/disk/by-partlabel/SN602439-EFI"
#       "/dev/disk/by-partlabel/SN601569-EFI"
#     ];
#   };

let
  cfg = config.services.efiSync;
  source  = config.fileSystems."/boot".device;
  targets = builtins.filter (esp: esp != source) cfg.esps;
in
{
  options.services.efiSync = {
    enable = lib.mkEnableOption "Automatische EFI-Partitions-Synchronisation";

    esps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [
        "/dev/disk/by-partlabel/DISK1-EFI"
        "/dev/disk/by-partlabel/DISK2-EFI"
        "/dev/disk/by-partlabel/DISK3-EFI"
      ];
      description = ''
        Alle ESP-Partitionen der Maschine. Die Partition die mit
        fileSystems."/boot".device übereinstimmt ist die Quelle;
        alle anderen werden nach jedem nixos-rebuild synchronisiert.
      '';
    };
  };

  config = lib.mkIf cfg.enable {

    assertions = [{
      assertion = builtins.elem source cfg.esps;
      message = ''
        services.efiSync: fileSystems."/boot".device ("${source}")
        ist nicht in services.efiSync.esps enthalten.
        Alle ESPs der Maschine angeben, einschließlich der primären.
      '';
    }];

    systemd.services.efi-sync = {
      description = "Sync primary EFI partition to mirrors";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;
      };
      script =
        let rsync = "${pkgs.rsync}/bin/rsync";
        in ''
          set -euo pipefail
          tmpdir=$(mktemp -d)
          trap 'umount "$tmpdir" 2>/dev/null || true; rmdir "$tmpdir"' EXIT

          ${lib.concatMapStringsSep "\n" (dev: ''
            echo "efi-sync: /boot → ${dev}"
            mount ${dev} "$tmpdir"
            ${rsync} -a --delete /boot/ "$tmpdir/"
            umount "$tmpdir"
          '') targets}
        '';
    };

    systemd.paths.efi-sync = {
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        # loader.conf wird von bootctl nach jedem nixos-rebuild neu geschrieben
        PathModified = "/boot/loader/loader.conf";
        Unit = "efi-sync.service";
      };
    };
  };
}
