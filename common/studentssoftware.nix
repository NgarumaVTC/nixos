{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    bat                        # Modern cat with syntax highlighting
    bind                       # DNS diagnostic tools like dig
    btop                       # Interactive resource monitor
    chromium                   # Open-source web browser
    dbeaver-bin                # Universal database tool
    evince                     # Lightweight PDF viewer
    exfatprogs                 # ExFAT flash drive tools
    freecad                    # Parametric 3D CAD modeler
    fzf                        # Command-line fuzzy finder
    geogebra                   # Dynamic math software
    gimp                       # GNU Image Manipulation Program
    git                        # Version control system
    gnome-boxes                # KISS virtual machine manager
    hunspell                   # Spell checker
    hunspellDicts.de_DE        # German dictionary
    hunspellDicts.en_US-large  # Large English dictionary
    hyphenDicts.de_DE          # German hyphenation rules
    hyphenDicts.en_US          # English hyphenation rules
    inkscape                   # Vector graphics editor
    keepassxc                  # Offline password manager
    klavaro                    # Touch typing tutor
    librecad                   # 2D CAD application
    libreoffice                # Open-source office suite
    ntfs3g                     # Windows NTFS read/write driver
    python3                    # Python 3 interpreter
    qelectrotech               # Electrical circuit editor
    qemu_kvm                   # Hypervisor backend for VMs
    ripgrep                    # Fast line-oriented search
    seamly2d                   # Parametric pattern design for tailoring
    sqlite                     # Lightweight SQL database
    unzip                      # Extract .zip archives
    usbutils                   # USB device query tools
    vim                        # Terminal text editor
    vlc                        # Cross-platform media player
    wxmaxima                   # Maxima algebra system GUI
    zed-editor                 # High-performance code editor
    zip                        # Create .zip archives
  ];
}
