{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Browser & Medien
    firefox
    vlc
    evince

    # Office
    libreoffice
    hunspell
    hunspellDicts.en_US-large
    hunspellDicts.de_DE

    # Lernen
    klavaro

    # Grafik (je nach Beruf)
    gimp
    inkscape

    # Fachspezifisch
    seamly2d          # Schneider: Schnittmuster
    qelectrotech      # Elektriker: Schaltplaene

    # Grundtools
    bat
    fzf
    git
    htop
    ripgrep
    unzip
    vim
    zip
  ];

  # Hardware-Video-Beschleunigung (Intel GPUs ab ~2010)
  hardware.graphics.enable = true;
  environment.sessionVariables.LIBVA_DRIVER_NAME = "i965";
}
