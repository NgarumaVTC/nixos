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

  options.boot.customIpxe = lib.mkOption { type = lib.types.package; };

  config = {
    hardware.enableRedistributableFirmware = true;
    
    hardware.firmware = [
      (pkgs.runCommand "tc-firmware" {} ''
        mkdir -p $out/lib/firmware/amdgpu $out/lib/firmware/rtl_nic
        cp ${pkgs.linux-firmware}/lib/firmware/amdgpu/carrizo* $out/lib/firmware/amdgpu/
        cp ${pkgs.linux-firmware}/lib/firmware/rtl_nic/rtl8168h-2.fw $out/lib/firmware/rtl_nic/
      '')
    ];

    boot.initrd.kernelModules = [ "amdgpu" "r8169" ];
    
    boot.initrd.systemd = {
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

    boot.zfs.forceImportRoot = false;

    users.users.root.initialHashedPassword = ""; 

    systemd.services."getty@tty2".enable = true;
    services.getty.autologinUser = lib.mkForce "root";

    boot.customIpxe = pkgs.ipxe.override {
      embedScript = pkgs.writeText "embed.ipxe" ''
        #!ipxe
        dhcp
        chain http://${webConfig.ip}/boot.ipxe
      '';
    };

    services.openssh.enable = true;
    services.openssh.settings.PermitRootLogin = "yes";
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWFdG02unkYNzRsOjrRSrSOc1s/feh2C9fOoOEAS4oA ramge@mbp2"
    ];

    services.cage = {
      enable = true;
      user = "root";
      program = let
        kioskScript = pkgs.writeShellScriptBin "start-kiosk" ''
          while true; do
            # Nativer Wayland-Client, direktes Login, robustes Rendering!
            ${pkgs.freerdp}/bin/wlfreerdp /v:${ctConfig.ip} /u:student /p:studentpassword /f /cert:ignore /network:lan
            sleep 5
          done
        '';
      in "${kioskScript}/bin/start-kiosk";
    };

    system.stateVersion = "26.05";
  };
}
