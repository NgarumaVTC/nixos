{ config, pkgs, ... }:

{
  users.users.ramge = {
    isNormalUser = true;
    uid = 1001;
    description = "Axel Ramge";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWFdG02unkYNzRsOjrRSrSOc1s/feh2C9fOoOEAS4oA ramge@mbp2"
    ];
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [ stow ];

  system.userActivationScripts.stowDotfiles.text = ''
    echo "Applying Stow for dotfiles..."
    USER_HOME="/home/ramge"
    DOTFILES="$USER_HOME/sync/gh/dotfiles"

    export PATH="${pkgs.stow}/bin:$PATH"

    if [ -d "$DOTFILES" ]; then
      cd "$DOTFILES"
      
      packages=("zsh" "git" "tmux" "emacs" "vim")

      for pkg in "''${packages[@]}"; do
        if [ -d "$pkg" ]; then
          echo "Stowing $pkg..."
          stow --no-folding -t "$USER_HOME" -R "$pkg"
        fi
      done
    else
      echo "Warnung: Dotfiles directory not found at $DOTFILES"
    fi
  '';
}
