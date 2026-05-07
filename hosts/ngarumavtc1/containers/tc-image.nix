{ pkgs, modulesPath, config, lib, ... }:

let
  net = import ../../../common/network.nix;
  ctConfig = net.nodes.ct90051;
in
{
  imports = [
    (modulesPath + "/installer/netboot/netboot-base.nix")
  ];

  system.disableInstallerTools = true;

  boot = {
    kernelParams = [ "video=1920x1080@60" "quiet" "panic=10" ];

    # Beide Treiber laden — Kernel sucht sich den passenden raus
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "r8169" ];
    initrd.kernelModules = [ "radeon" "amdgpu" ];

    initrd.compressor = "zstd";
  };

  # Firmware-Block KOMPLETT raus — netboot-base sorgt selbst dafür
  # (kein hardware.enableRedistributableFirmware = false; mehr,
  #  kein hardware.firmware = [...] mehr)

  services.cage = {
    enable = true;
    user = "root";
    program = let
      kioskScript = pkgs.writeShellScriptBin "start-kiosk" ''
        while true; do
          USER=$(${pkgs.zenity}/bin/zenity --entry --title="Ngaruma VTC" --text="Benutzername:" 2>/dev/null)
          if [ -z "$USER" ]; then continue; fi
          PASS=$(${pkgs.zenity}/bin/zenity --password --title="Ngaruma VTC" --text="Passwort:" 2>/dev/null)
          if [ -z "$PASS" ]; then continue; fi

          ${pkgs.freerdp}/bin/xfreerdp /v:${ctConfig.ip} /f /cert:ignore /network:lan /u:"$USER" /p:"$PASS"
          sleep 2
        done
      '';
    in "${kioskScript}/bin/start-kiosk";
  };

  environment.systemPackages = with pkgs; [
    freerdp
    zenity
    glibcLocales
  ];

  system.stateVersion = "26.05";
}
