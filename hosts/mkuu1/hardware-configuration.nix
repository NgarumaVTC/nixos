{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../common/efi-sync.nix
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # /boot: primäre ESP auf sdb; sda1 wird von efi-sync gespiegelt.
  # sdc ist ausgebaut — nach Wiedereinbau efi-sync.esps ergänzen.
  fileSystems."/boot" = {
    device = "/dev/disk/by-id/ata-SAMSUNG_MZ7KH480HAHQ-00005_S47MNE0M602891-part1";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ ];

  services.efiSync = {
    enable = true;
    esps = [
      "/dev/disk/by-id/ata-SAMSUNG_MZ7KH480HAHQ-00005_S47MNE0M602891-part1"  # sdb → /boot (Quelle)
      "/dev/disk/by-id/ata-SAMSUNG_MZ7KH480HAHQ-00005_S47MNE0M602439-part1"  # sda → Mirror
      # sdc (S47MNE0M601569) ausgebaut — nach Wiedereinbau hier ergänzen
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
