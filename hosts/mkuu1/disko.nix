{ ... }:

# Deklaratives Disk-Layout für mkuu1 (MSI Granate, AMD A10-9700)
#
# Physische Disks:
#   sda  ata-SAMSUNG_MZ7KH480HAHQ-00005_S47MNE0M602439  447G
#   sdb  ata-SAMSUNG_MZ7KH480HAHQ-00005_S47MNE0M602891  447G  ← /boot
#   sdc  ata-SAMSUNG_MZ7KH480HAHQ-00005_S47MNE0M601569  447G
#   sdd  ata-Samsung_SSD_870_EVO_250GB_S6PENJ0RB38470R   250G  ← homes
#
# Pools:
#   zroot  3-way mirror (sda+sdb+sdc)  →  System + VIP-Daten
#   homes  single disk (sdd)           →  Schüler-Homes (später mirror 2×2TB)
#
# ESP: sdb1 ist primäre /boot; sda1+sdc1 werden von efi-sync.nix gespiegelt.

{
  disko.devices = {

    disk = {

      sda = {
        type   = "disk";
        device = "/dev/disk/by-id/ata-SAMSUNG_MZ7KH480HAHQ-00005_S47MNE0M602439";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size    = "1G";
              type    = "EF00";
              content = {
                type   = "filesystem";
                format = "vfat";
                # kein Mountpoint — wird von efi-sync.nix gespiegelt
              };
            };
            zfs = {
              size    = "100%";
              content = { type = "zfs"; pool = "zroot"; };
            };
          };
        };
      };

      sdb = {
        type   = "disk";
        device = "/dev/disk/by-id/ata-SAMSUNG_MZ7KH480HAHQ-00005_S47MNE0M602891";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size    = "1G";
              type    = "EF00";
              content = {
                type       = "filesystem";
                format     = "vfat";
                mountpoint = "/boot";             # primäre ESP
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size    = "100%";
              content = { type = "zfs"; pool = "zroot"; };
            };
          };
        };
      };

      sdc = {
        type   = "disk";
        device = "/dev/disk/by-id/ata-SAMSUNG_MZ7KH480HAHQ-00005_S47MNE0M601569";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size    = "1G";
              type    = "EF00";
              content = {
                type   = "filesystem";
                format = "vfat";
                # kein Mountpoint — wird von efi-sync.nix gespiegelt
              };
            };
            zfs = {
              size    = "100%";
              content = { type = "zfs"; pool = "zroot"; };
            };
          };
        };
      };

      sdd = {
        type   = "disk";
        device = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_250GB_S6PENJ0RB38470R";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size    = "100%";
              content = { type = "zfs"; pool = "homes"; };
            };
          };
        };
      };

    };

    zpool = {

      zroot = {
        type = "zpool";
        mode = "mirror";              # 3-way mirror (alle drei sda/sdb/sdc-Partitionen)
        rootFsOptions = {
          compression = "zstd";
          acltype     = "posixacl";
          xattr       = "sa";
          atime       = "off";
        };
        options.ashift = "12";        # 4K-Sektoren

        datasets = {
          root = {
            type    = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
          };
          nix = {
            type    = "zfs_fs";
            mountpoint = "/nix";
            options = {
              mountpoint = "legacy";
              atime      = "off";     # Nix-Store braucht kein atime
            };
          };
          home = {
            type    = "zfs_fs";
            mountpoint = "/home";     # VIP-Homes: admin + Lehrer
            options.mountpoint = "legacy";
          };
          containers = {
            type    = "zfs_fs";
            mountpoint = "/var/lib/nixos-containers";
            options.mountpoint = "legacy";
          };
          classmaterial = {
            type    = "zfs_fs";
            mountpoint = "/media/ClassMaterial";
            options.mountpoint = "legacy";
          };
        };
      };

      homes = {
        type = "zpool";
        # Jetzt: single disk (sdd, 870 EVO 250G) — kein Mirror
        # Später: zpool attach homes <neue-2TB-SSD> für Mirror-Ausbau
        rootFsOptions = {
          compression = "zstd";
          acltype     = "posixacl";
          xattr       = "sa";
          atime       = "off";
        };
        options.ashift = "12";

        # Keine Datasets hier — werden per Script/manuell
        # pro Schüler angelegt: zfs create -o quota=10G homes/studentXXXX
        datasets = {};
      };

    };
  };
}
