{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # nvme bewusst nicht im initrd — nvtc1 bootet von SATA/md0
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ "dm-snapshot" "raid1" ];
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = "ARRAY /dev/md0 metadata=1.2 UUID=73b0de17:96901961:9b77ab07:34e8b4d4";
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # LVM: NUR vg_nvtc1 aktivieren — ignoriert fremde VGs (vg_nixos, vg-peano, etc.)
  # lvmlocal.conf wird NACH lvm.conf gelesen und überschreibt gezielt
  boot.initrd.systemd.contents."/etc/lvm/lvmlocal.conf".text = ''
    activation {
      auto_activation_volume_list = [ "vg_nvtc1" ]
    }
  '';
  environment.etc."lvm/lvmlocal.conf".text = ''
    activation {
      auto_activation_volume_list = [ "vg_nvtc1" ]
    }
  '';

  # md RAID1 (sda2+sdb2+sdc2) → LVM vg_nvtc1 → root + swap
  fileSystems."/" = {
    device = "/dev/mapper/vg_nvtc1-root";
    fsType = "ext4";
  };

  # Primäre EFI-Partition (sda1); sdb1+sdc1 werden manuell synchronisiert
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/SN602891-EFI";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [
    { device = "/dev/mapper/vg_nvtc1-swap"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
