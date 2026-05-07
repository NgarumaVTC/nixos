{ pkgs, modulesPath, config, lib, ... }:

{
  imports = [
    # Nur Core-Netboot, ohne Installer-Bloat (base.nix, installation-device.nix)
    (modulesPath + "/installer/netboot/netboot.nix")
    # Perl + Python aus dem Image entfernen (~300MB)
    (modulesPath + "/profiles/perlless.nix")
  ];

  system.disableInstallerTools = true;

  # Nix nicht nötig auf TC — Image wird zentral gebaut
  nix.enable = false;
  # register-nix-paths überschreiben damit Nix aus dem Closure fällt
  systemd.services.register-nix-paths.script = lib.mkForce ''
    touch /etc/NIXOS
  '';

  # Nur Firmware für die tatsächliche Hardware (Carrizo/Bristol Ridge + r8169)
  hardware.enableAllHardware = false;
  hardware.enableRedistributableFirmware = false;
  hardware.firmware = [
    (pkgs.runCommand "tc-firmware" {} ''
      SRC=${pkgs.linux-firmware}/lib/firmware
      mkdir -p $out/lib/firmware/{amdgpu,rtl_nic,amd-ucode}

      # AMD Carrizo / Bristol Ridge GPU (PCI 1002:9874)
      cp $SRC/amdgpu/carrizo_*.bin $out/lib/firmware/amdgpu/

      # Realtek r8169 NIC (PCI 10EC:8168)
      cp $SRC/rtl_nic/rtl8168*.fw $out/lib/firmware/rtl_nic/ 2>/dev/null || true
      cp $SRC/rtl_nic/rtl8411*.fw $out/lib/firmware/rtl_nic/ 2>/dev/null || true

      # AMD CPU microcode (family 15h = Bristol Ridge)
      cp $SRC/amd-ucode/microcode_amd_fam15h.bin $out/lib/firmware/amd-ucode/
    '')
  ];

  # Keine Dokumentation
  documentation.enable = false;
  documentation.nixos.enable = lib.mkForce false;
  documentation.man.enable = false;
  documentation.info.enable = false;

  boot = {
    kernelParams = [ "video=1920x1080@60" "quiet" "panic=10" ];
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "r8169" ];
    initrd.kernelModules = [ "radeon" "amdgpu" ];
    initrd.compressor = "zstd";
  };

  time.timeZone = "Europe/Berlin";

  services.cage = {
    enable = true;
    user = "root";
    program = let
      kioskScript = pkgs.writeShellScriptBin "start-kiosk" ''
        # Auflösung auf 1920x1080 setzen (Monitor meldet ggf. 4K)
        OUTPUT=$(${pkgs.wlr-randr}/bin/wlr-randr 2>/dev/null | head -1 | cut -d' ' -f1)
        if [ -n "$OUTPUT" ]; then
          ${pkgs.wlr-randr}/bin/wlr-randr --output "$OUTPUT" --mode 1920x1080 2>/dev/null || true
        fi

        # Warten bis Netzwerk steht
        while true; do
          MY_IP=$(${pkgs.iproute2}/bin/ip -4 addr show scope global | grep inet | head -1 | awk '{print $2}' | cut -d/ -f1)
          if [ -n "$MY_IP" ]; then break; fi
          sleep 2
        done
        CT_IP="172.20.90.51"

        while true; do
          USER=$(${pkgs.zenity}/bin/zenity --entry --title="Ngaruma VTC" --text="Benutzername:" 2>/dev/null)
          if [ -z "$USER" ]; then continue; fi
          PASS=$(${pkgs.zenity}/bin/zenity --password --title="Ngaruma VTC" --text="Passwort:" 2>/dev/null)
          if [ -z "$PASS" ]; then continue; fi

          ${pkgs.freerdp}/bin/xfreerdp /v:"$CT_IP" /f /cert:ignore /network:lan /u:"$USER" /p:"$PASS"
          sleep 2
        done
      '';
    in "${kioskScript}/bin/start-kiosk";
  };

  environment.systemPackages = with pkgs; [
    freerdp
    wlr-randr
    zenity
    glibcLocales
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
    hostKeys = [];
  };

  environment.etc."ssh/ssh_host_ed25519_key" = {
    text = builtins.readFile /var/lib/tc-secrets/ssh_host_ed25519_key;
    mode = "0600";
  };
  environment.etc."ssh/ssh_host_ed25519_key.pub" = {
    text = builtins.readFile /var/lib/tc-secrets/ssh_host_ed25519_key.pub;
    mode = "0644";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWFdG02unkYNzRsOjrRSrSOc1s/feh2C9fOoOEAS4oA ramge@mbp2"
  ];

  systemd.services."cage-tty1" = {
    serviceConfig = {
      Restart = "always";
      RestartSec = "2s";
    };
  };

  system.stateVersion = "26.05";
}
