# Alpine Linux netboot-Dateien für den hybridclient.
# Kein Cross-Compile, kein QEMU — nur fetchurl vom Alpine CDN.
{ pkgs, ... }:
{
  vmlinuz = pkgs.fetchurl {
    url  = "https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/netboot/vmlinuz-lts";
    hash = "sha256-nJ7TUQ9htjByXDdpKUS4APGFU+znh/XdX68vI6epgns=";
  };
  initramfs = pkgs.fetchurl {
    url  = "https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/netboot/initramfs-lts";
    hash = "sha256-V0bP3FqEsnvYUfgjEez3B/XLc+pQRQeJx1jfqSqZLMU=";
  };
  modloop = pkgs.fetchurl {
    url  = "https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/netboot/modloop-lts";
    hash = "sha256-AqcT2br9M2rMI8bLm9dIwV0GT8Rmj57jq2fDdW1IEos=";
  };
}
