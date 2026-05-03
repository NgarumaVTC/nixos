{ config, pkgs, ... }:

{
  # Container-spezifische Grundeinstellungen (Kein Kernel, kein Bootloader)
  boot.isContainer = true;
  system.stateVersion = "26.05";
}
