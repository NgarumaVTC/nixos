{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # nvme bewusst nicht im initrd — mkuu1 bootet von SATA/md0
  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" "raid1" ];
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = "ARRAY /dev/md0 metadata=1.2 UUID=73b0de17:96901961:9b77ab07:34e8b4d4";
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # LVM: NUR vg_mkuu1 aktivieren — ignoriert fremde VGs (vg_nixos, vg-peano, etc.)
  # lvmlocal.conf wird NACH lvm.conf gelesen und überschreibt gezielt
  boot.initrd.systemd.contents."/etc/lvm/lvmlocal.conf".text = ''
    activation {
      auto_activation_volume_list = [ "vg_mkuu1" ]
    }
  '';
  environment.etc."lvm/lvmlocal.conf".text = ''
    activation {
      auto_activation_volume_list = [ "vg_mkuu1" ]
    }
  '';

  # md RAID1 (sda2+sdb2+sdc2) → LVM vg_mkuu1 → root + swap
  fileSystems."/" = {
    device = "/dev/mapper/vg_mkuu1-root";
    fsType = "ext4";
  };

  # Primäre EFI-Partition (sda1); sdb1+sdc1 werden manuell synchronisiert
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/SN602891-EFI";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [
    { device = "/dev/mapper/vg_mkuu1-swap"; }
  ];

  # ZFS: Pool "tank" per GUID importieren — vermeidet Konflikte bei gleichnamigen Pools
  systemd.services."zfs-import-tank".script = let
    zfs = config.boot.zfs.package;
  in lib.mkForce ''
    if ! ${zfs}/bin/zpool list tank > /dev/null 2>&1; then
      ${zfs}/bin/zpool import -d /dev/disk/by-partlabel -N 14376766170460333860
    fi
  '';

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
