#!/bin/bash
# Questo script rimuove i file che causano problemi
# Eseguire con: bash remove_files.sh

# Elimina i file relativi alle mappe
rm -f "/c:/xampp/htdocs/prezzi_benzina/android/app/src/main/java/com/lorenzo/tankfuel/model/GasStation.kt"
rm -f "/c:/xampp/htdocs/prezzi_benzina/android/app/src/main/java/com/lorenzo/tankfuel/screen/MapScreen.kt"

# Rimuovi anche la directory model se è vuota
rmdir "/c:/xampp/htdocs/prezzi_benzina/android/app/src/main/java/com/lorenzo/tankfuel/model" 2>/dev/null

# Rimuovi anche la directory screen se è vuota
rmdir "/c:/xampp/htdocs/prezzi_benzina/android/app/src/main/java/com/lorenzo/tankfuel/screen" 2>/dev/null

echo "File problematici rimossi con successo."
