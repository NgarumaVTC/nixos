# Fujitsu Futro S740 — Hardware-Dokumentation

Erfasst: 2026-05-08
Erfassungsmethode: NixOS 26.05 Live-Installer (dmidecode, lscpu, lspci, ip)

---

## System

| Feld | Wert |
|------|------|
| Hersteller | FUJITSU |
| Modell | FUTRO S740 |
| Seriennummer | YMFW015324 |
| UUID | 07ed53e0-9db7-11e9-b1ce-4c5262a16833 |
| SKU | S26361-Kxxx-Vyyy |
| Familie | FUTRO-FTS |
| Gehäusetyp | Desktop |

---

## Mainboard

| Feld | Wert |
|------|------|
| Hersteller | FUJITSU |
| Modell | D3544-A1 |
| Version | S26361-D3544-A14 |
| Seriennummer | 60283836 |

---

## BIOS / UEFI

| Feld | Wert |
|------|------|
| Hersteller | FUJITSU // American Megatrends Inc. |
| Version | V5.0.0.13 R1.10.0 for D3544-A1x |
| Firmware-Revision | 1.10 |
| Datum | 05/10/2019 |
| Boot-Modus | UEFI |
| ROM-Groesse | 16 MiB |

---

## Prozessor

| Feld | Wert |
|------|------|
| Modell | Intel Celeron J4105 |
| Codename | Gemini Lake |
| Architektur | x86_64 |
| Kerne / Threads | 4 / 4 |
| Basistakt | 1500 MHz |
| Maximaltakt | 2500 MHz (Turbo: 2700 MHz laut BIOS) |
| Sockel | BGA1023 |
| Virtualisierung | VT-x |
| L1-Cache | 224 KiB |
| L2-Cache | 4 MiB |

---

## Arbeitsspeicher

| Feld | Wert |
|------|------|
| Max. Kapazitaet | 8 GiB (2 Slots) |
| Bestueckt | 1x 4 GiB |
| Freie Slots | 1 |

### Slot A1_DIMM0 (belegt)

| Feld | Wert |
|------|------|
| Groesse | 4 GiB |
| Typ | DDR4 SODIMM |
| Geschwindigkeit | 2400 MT/s |
| Spannung | 1.2 V |
| Hersteller | SK Hynix |
| Teilenummer | HMA851S6CJR6N-VK |
| Seriennummer | 46183324 |

### Slot A1_DIMM1 (leer)

---

## Grafik

| Feld | Wert |
|------|------|
| Modell | Intel UHD Graphics 600 |
| Codename | Gemini Lake (integriert) |
| PCI-Adresse | 00:02.0 |
| Ausgaenge | 2x DisplayPort (DP1, DP2) |

---

## Netzwerk

| Feld | Wert |
|------|------|
| Chipsatz | Realtek RTL8111/8168/8211/8411 |
| Typ | Gigabit Ethernet (1x RJ-45) |
| PCI-Adresse | 02:00.0 |
| Interface | eno1 (auch: enp2s0, enx4c5262a16833) |
| MAC-Adresse | 4c:52:62:a1:68:33 |
| WLAN | nicht vorhanden |

---

## Speicher

| Geraet | Groesse | Typ | Modell | Anmerkung |
|--------|---------|-----|--------|-----------|
| sdb | 14.9 GB | eMMC (M.2 KeyB) | DEM24-16GM41BC | interner Speicher |

---

## M.2-Slots

| Slot | Typ | Status | PCI-Adresse |
|------|-----|--------|-------------|
| KeyB | M.2 Socket 2 (SATA) | belegt (eMMC) | 0000:06:00.0 |
| KeyE | M.2 Socket 1-SD (WiFi/BT) | laut BIOS "In Use", kein Geraet in lspci | 0000:01:00.0 |

---

## Audio

| Feld | Wert |
|------|------|
| Chipsatz | Intel HDA (Celeron/Pentium Silver) |
| PCI-Adresse | 00:0e.0 |
| Anschluesse | Front-Audio-Jack, Rear-Audio-Jack |

---

## USB

| Feld | Wert |
|------|------|
| Controller | Intel USB 3.0 xHCI |
| Ports hinten | 4x USB (2x USB 2.0, 2x USB 3.0) |
| Ports vorne | 2x USB 3.0 |
| Intern | 2x USB 3.0 |

---

## PXE-Boot — Konfigurationsreferenz

| Parameter | Wert |
|-----------|------|
| MAC-Adresse | 4c:52:62:a1:68:33 |
| UUID | 07ed53e0-9db7-11e9-b1ce-4c5262a16833 |
| Boot-Modus | UEFI |
| Architektur | x86_64 |
| DHCP Client Architecture (Option 93) | 0x0007 (EFI x86-64) |
| Empfohlener Bootloader | grubx64.efi oder ipxe.efi |

---

## Vollstaendige PCI-Geraetliste

```
00:00.0  Host bridge:               Intel Gemini Lake Host Bridge (rev 03)
00:00.1  Signal processing:         Intel DPTF Processor Participant (rev 03)
00:00.3  System peripheral:         Intel Gaussian Mixture Model (rev 03)
00:02.0  VGA:                       Intel GeminiLake UHD Graphics 600 (rev 03)
00:0e.0  Audio:                     Intel HDA (rev 03)
00:0f.0  Communication controller:  Intel TEE Interface (rev 03)
00:12.0  SATA controller:           Intel SATA Controller (rev 03)
00:13.0  PCI bridge:                Intel Gemini Lake PCIe Root Port (rev f3)
00:13.2  PCI bridge:                Intel Gemini Lake PCIe Root Port (rev f3)
00:13.3  PCI bridge:                Intel Gemini Lake PCIe Root Port (rev f3)
00:14.0  PCI bridge:                Intel Gemini Lake PCIe Root Port (rev f3)
00:14.1  PCI bridge:                Intel Gemini Lake PCIe Root Port (rev f3)
00:15.0  USB controller:            Intel USB 3.0 xHCI (rev 03)
00:16.x  Signal processing (I2C 0-3)
00:17.x  Signal processing (I2C 4-7)
00:19.x  Signal processing (SPI 0-2)
00:1f.0  ISA bridge:                Intel LPC Controller (rev 03)
00:1f.1  SMBus:                     Intel SMBus (rev 03)
02:00.0  Ethernet:                  Realtek RTL8111/8168 GbE (rev 0c)
```
