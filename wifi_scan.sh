#!/data/data/com.termux/files/usr/bin/bash
# Termux Wi-Fi Scanner - Color-coded & Frame
# Legal / Educational
# Author: Rx Abdullah

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

echo -e "${CYAN}🔍 Scanning Wi-Fi networks... (wait a few seconds)${RESET}"
SCAN_RESULT=$(termux-wifi-scaninfo 2>&1)

# Check JSON
if ! echo "$SCAN_RESULT" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: termux-wifi-scaninfo valid JSON not returned.${RESET}"
    echo "$SCAN_RESULT"
    exit 1
fi

echo
echo -e "${CYAN}📡 Wi-Fi Networks Scan Results${RESET}"
echo "==================================="

# Process each network
echo "$SCAN_RESULT" | jq -r '.[] | [
    (.ssid // "<hidden>"),
    .bssid,
    (.rssi|tostring),
    (.frequency as $f |
       (if $f == null then "-" 
        elif ($f >= 5000) then ( (($f - 5000) / 5) | floor + 36 ) 
        else ( (($f - 2400) - 2407) / 5 | floor + 1 ) end)
    ),
    (.frequency|tostring),
    (.capabilities // "UNKNOWN")
] | @tsv' | while IFS=$'\t' read -r ssid bssid rssi channel freq caps; do

    # Security detection
    sec="OPEN"
    caps_up=$(echo "$caps" | tr '[:lower:]' '[:upper:]')
    if echo "$caps_up" | grep -q "WPA3"; then sec="WPA3"
    elif echo "$caps_up" | grep -q "WPA2"; then sec="WPA2"
    elif echo "$caps_up" | grep -q "WPA"; then sec="WPA"
    elif echo "$caps_up" | grep -q "WEP"; then sec="WEP"
    fi

    # Range estimate from RSSI
    rssi_val=$(echo "$rssi" | sed 's/[^0-9-]//g')
    if [ -z "$rssi_val" ]; then rng="Unknown"; color="$YELLOW"
    elif [ "$rssi_val" -ge -50 ]; then rng="Very Close (0-10m)"; color="$GREEN"
    elif [ "$rssi_val" -ge -60 ]; then rng="Close (10-20m)"; color="$GREEN"
    elif [ "$rssi_val" -ge -70 ]; then rng="Moderate (20-40m)"; color="$YELLOW"
    elif [ "$rssi_val" -ge -80 ]; then rng="Far (40-80m)"; color="$RED"
    else rng="Very Far (>80m)"; color="$RED"
    fi

    # Highlight hidden network
    if [ "$ssid" == "<hidden>" ]; then color="$CYAN"; fi

    # Print in frame
    echo -e "${color}┌───────────────────────────────────────────────┐${RESET}"
    printf "${color}│ %-15s : %-30s │${RESET}\n" "SSID" "$ssid"
    printf "${color}│ %-15s : %-30s │${RESET}\n" "BSSID" "$bssid"
    printf "${color}│ %-15s : %-30s │${RESET}\n" "RSSI" "$rssi dBm"
    printf "${color}│ %-15s : %-30s │${RESET}\n" "Channel" "$channel"
    printf "${color}│ %-15s : %-30s │${RESET}\n" "Frequency" "$freq MHz"
    printf "${color}│ %-15s : %-30s │${RESET}\n" "Security" "$sec"
    printf "${color}│ %-15s : %-30s │${RESET}\n" "Range" "$rng"
    printf "${color}│ %-15s : %-30s │${RESET}\n" "Password" "NULL"
    echo -e "${color}└───────────────────────────────────────────────┘${RESET}\n"

done

echo -e "${GREEN}✅ Scan Completed. All passwords shown as NULL (legal & safe)${RESET}"
