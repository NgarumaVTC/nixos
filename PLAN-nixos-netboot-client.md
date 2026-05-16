# Plan: NixOS Netboot Client (Ablösung Alpine Hybridclient)

## Kontext

Alpine Linux als Hybridclient funktioniert, bringt aber:
- Zweite Distribution = doppelte Komplexität (KISS-Verletzung)
- musl-libc: kein brauchbares LDAP (sssd/nslcd-Debugging-Hölle)
- Separates Build-System (apkovl, alpine-image.nix)

Entscheidung: Zurück zu NixOS, diesmal als schlanker Netboot-Client mit NFS-Root.

## Architektur

- PXE/iPXE Boot: Kernel + Initrd vom web01-Container
- Root-Filesystem: NFS read-only von mkuu1 (spart RAM vs. SquashFS-in-RAM)
- Home-Verzeichnisse: NFS read-write von mkuu1 (/home)
- Auth: sssd gegen lldap (172.20.90.12) — glibc, keine musl-Probleme
- Desktop: XFCE minimal, lokale Applikationen
- Video: Lokale Wiedergabe im Browser (kein RDP-Streaming)

## Software auf dem Client (Essentials für Handwerks-Lehrlinge)

- Firefox (YouTube-Tutorials, Recherche)
- LibreOffice (Berichte, Tabellen)
- Evince (PDFs, Datenblätter)
- VLC (lokale Videos)
- Klavaro (Tippen lernen)
- GIMP, Inkscape (je nach Beruf)
- Seamly2D (Schneider), QElectroTech (Elektriker)
- Grundtools: vim, git, bat, fzf, ripgrep

Schwere Apps (DBeaver, FreeCAD, gnome-boxes) nur auf dem Server via RDP.

## Phasen

### Phase 1: Alpine-Code entfernen
- [x] Git-Tag v0.1-alpine-final gesetzt
- [ ] Alpine-Dateien entfernen (hosts/hybridclient/, apkovl.tar.gz, alpine-image.nix)
- [ ] web01-Container vereinfachen (kein apkovl-Build mehr)

### Phase 2: NixOS Client-Image bauen
- [ ] hosts/hybridclient/configuration.nix — NixOS Netboot-Config
- [ ] NFS-Root Setup (read-only Export von mkuu1)
- [ ] tmpfs fuer /tmp, /run, /var
- [ ] XFCE + Essentials-Software
- [ ] sssd gegen lldap konfigurieren

### Phase 3: PXE-Infrastruktur anpassen
- [ ] web01 liefert NixOS-Kernel + Initrd
- [ ] iPXE-Script anpassen (NFS-Root statt apkovl)
- [ ] DHCP auf hapax3 bleibt wie gehabt

### Phase 4: Auth + Home testen
- [ ] sssd Login gegen lldap verifizieren
- [ ] NFS-Home mount mit korrekter Ownership
- [ ] PAM makeHomeDir testen

### Phase 5: students-Container obsolet machen
- [ ] Wenn Clients lokal laufen: xrdp/students-Container abschalten
- [ ] Optional: RDP-Zugang fuer Schwerlast-Apps auf dem Server behalten

## Hardware-Anforderungen Client

- CPU: x86_64, ca. 2010er Business-PC
- RAM: 2-4 GB (NFS-Root = kein RAM fuer rootfs noetig)
- GPU: Intel integriert (reicht fuer 720p/1080p Video-Decode)
- Disk: keine (diskless, PXE-Boot)
- Netz: Gigabit Ethernet empfohlen
