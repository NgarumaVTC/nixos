{ config, pkgs, ... }:
{
  containers.mgmt1 = {
    bindMounts = {
      # Staff-Homes vom Host (/staff) erscheinen im Container als /home/<user>.
      "/home" = { hostPath = "/staff"; isReadOnly = false; };

      # Klassenmaterial RW fuer Teacher.
      "/media/ClassMaterial" = { hostPath = "/media/ClassMaterial"; isReadOnly = false; };

      # Flake-Repo fuer Admin-Arbeit aus mgmt1 heraus.
      "/home/ramge/sync" = { hostPath = "/home/ramge/sync"; isReadOnly = false; };

      # LDAP-Bind-Passwort fuer sssd (sops-template auf dem Host).
      "/run/sssd.env" = {
        hostPath = config.sops.templates."students-sssd.env".path;
        isReadOnly = true;
      };
    };

    config = { config, pkgs, ... }: {
      # ramge user wird via common/default.nix → users/ramge/nixos.nix angezogen
      # (common/containers.nix importiert default.nix in jeden container).

      environment.systemPackages = with pkgs; [
        # Admin/Dev-Werkzeug
        bat
        claude-code
        fzf
        gh
        git
        htop
        jq
        rsync
        ripgrep
        sops
        age
        tmux
        vim
        # GUI fuer Teacher
        firefox-esr
        libreoffice
        evince
        gimp
        inkscape
      ];

      services.xserver = {
        enable = true;
        desktopManager.xfce.enable = true;
        xkb.layout = "de";
      };

      services.xrdp = {
        enable = true;
        defaultWindowManager = "${pkgs.xfce4-session}/bin/xfce4-session";
        openFirewall = true;
      };

      users.ldap.enable = false;

      services.sssd = {
        enable = true;
        config = ''
          [sssd]
          config_file_version = 2
          services = nss, pam
          domains = lldap

          [domain/lldap]
          id_provider = ldap
          auth_provider = ldap
          # PAM-Access ueber LDAP-Filter, weil lldap-Gruppen kein gidNumber haben
          # und damit nicht per NSS/getent group aufloesbar sind. memberOf ist
          # aber direkt am User vorhanden.
          access_provider = ldap
          ldap_access_order = filter
          ldap_access_filter = (|(memberOf=cn=lldap_admin,ou=groups,dc=ngarumavtc,dc=lan)(memberOf=cn=lldap_teacher,ou=groups,dc=ngarumavtc,dc=lan))

          ldap_uri = ldap://172.20.90.12:3890
          ldap_search_base = dc=ngarumavtc,dc=lan
          ldap_default_bind_dn = uid=admin,ou=people,dc=ngarumavtc,dc=lan
          ldap_default_authtok_type = password
          ldap_default_authtok = $LDAP_PASS

          ldap_id_use_start_tls = False
          ldap_tls_reqcert = never
          ldap_auth_disable_tls_never_use_in_production = True

          ldap_id_mapping = False
          ldap_user_uid_number = uidnumber
          ldap_user_gid_number = gidnumber

          fallback_homedir = /home/%u
          default_shell = /run/current-system/sw/bin/bash
        '';
      };

      systemd.services.sssd.serviceConfig.EnvironmentFile = "/run/sssd.env";

      security.pam.services.login = { makeHomeDir = true; sssdStrictAccess = true; };
      security.pam.services.xrdp-sesman = { makeHomeDir = true; sssdStrictAccess = true; };
      security.pam.services.sshd.sssdStrictAccess = true;

      # Hinweis: sudo fuer lldap_admin-Mitglieder ist hier nicht aktiv —
      # lldap-Gruppen haben keine gidNumber, daher nicht via NSS aufloesbar.
      # ramge kommt via deklarativem NixOS-User in wheel (common/default.nix).
      # Weitere Admins muessen ebenfalls deklarativ als wheel-User definiert
      # werden, oder lldap-Gruppen brauchen ein POSIX-gid-Mapping.

      # Browser/Office mit ordentlichen Limits.
      security.pam.loginLimits = [
        { domain = "@users"; type = "hard"; item = "nproc"; value = "16384"; }
        { domain = "@users"; type = "hard"; item = "nofile"; value = "65536"; }
      ];
    };
  };
}
