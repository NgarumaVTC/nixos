{
  # Globale Infrastruktur-Variablen
  domain = "ngarumavtc.ac.tz";
  gateways = {
    default = "172.20.0.1";
    students = "172.20.90.1";
  };
  nameservers = [ "172.20.0.1" ];

  # Die Single Source of Truth für alle Geräte
  nodes = {
    # --- INFRASTRUKTUR / HOSTS ---
    hapax3 = {
      ip = "172.20.0.1";
      vlan = 1;
    };
    ngarumavtc1 = {
      ip = "172.20.0.10";
      # Falls du der Bridge/dem Host-Interface auch das Muster aufzwingen willst:
      mac = "02:00:00:00:00:10";
      vlan = 1;
    };

    # --- VIRTUELLE CONTAINER (Subnetz 0) ---
    mgmt1 = {
      ip = "172.20.0.11";
      mac = "02:00:00:00:00:11"; # Muster generiert
      vlan = 1;
    };
    web01 = {
      ip = "172.20.0.21";
      mac = "02:00:00:00:00:21"; # Muster generiert
      vlan = 1;
    };

    # --- VIRTUELLE CONTAINER (Subnetz 90 - Students) ---
    ct90051 = {
      ip = "172.20.90.51";
      mac = "02:00:00:00:90:51"; # Muster generiert
      vlan = 90;
    };

    # --- PHYSISCHE THIN CLIENTS ---
    tc90151 = {
      ip = "172.20.90.151";
      # Physische Hardware -> Echte, eingebrannte MAC für DHCP/PXE behalten!
      mac = "30:9C:23:DB:3F:41";
      vlan = 90;
    };
    tc01 = {
      ip = "172.20.90.100";
      # MAC noch eintragen, sobald der Client ans Netz geht
      vlan = 90;
    };
  };
}
