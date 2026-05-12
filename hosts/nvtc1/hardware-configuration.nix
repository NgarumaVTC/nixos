{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ "dm-snapshot" "raid1" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # md RAID1 (sda2+sdb2+sdc2) → LVM vg_nixos → root + swap
  fileSystems."/" = {
    device = "/dev/mapper/vg_nixos-root";
    fsType = "ext4";
  };

  # Primäre EFI-Partition (sda1); sdb1+sdc1 werden manuell synchronisiert
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/SN602891-EFI";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [
    { device = "/dev/mapper/vg_nixos-swap"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
