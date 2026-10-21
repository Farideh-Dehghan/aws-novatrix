#!/bin/bash
# Uppgift 1 (v42) - Novatrix AB
# Installerar Apache och driftsätter webbsidan på Amazon Linux 2023

# Uppdatera systemet
sudo dnf update -y

# Installera webbservern Apache
sudo dnf install -y httpd

# Starta Apache och aktivera vid omstart
sudo systemctl enable --now httpd

# Kopiera webbsidan till Apaches webbkatalog
sudo cp index.html /var/www/html/index.html

# Verifiera att Apache körs
systemctl is-active httpd
