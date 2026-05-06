#!/bin/sh

echo "--- 1. SSH-Cleanup für TC 151 ---"
sed -i '/172.20.90.151/d' ~/.ssh/known_hosts

echo -e "\n--- 2. Status-Check TC 151 (Was sieht Cage/FreeRDP?) ---"
ssh root@172.20.90.151 "journalctl -u cage -n 20 --no-pager"

echo -e "\n--- 3. Status-Check Container 051 (Benutzer-Validation) ---"
sudo nixos-container run ct90051 -- getent passwd student10013

echo -e "\n--- 4. Mount-Check (Liegt das Home-Verzeichnis korrekt?) ---"
sudo nixos-container run ct90051 -- ls -land /home/student10013

echo -e "\n--- 5. XRDP Error-Log (Warum startet XFCE nicht?) ---"
sudo nixos-container run ct90051 -- tail -n 50 /var/log/xrdp-sesman.log

echo -e "\n--- 6. X-Session Errors (Der Klassiker für schwarze Bildschirme) ---"
sudo nixos-container run ct90051 -- cat /home/student10013/.xsession-errors 2>/dev/null || echo "Keine .xsession-errors gefunden."
