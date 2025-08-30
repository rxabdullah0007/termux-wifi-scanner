#!/data/data/com.termux/files/usr/bin/bash
# Wi-Fi Scanner Tool for Termux
# Author: Rx Abdullah

echo "🔍 Scanning Wi-Fi networks... (একটু সময় লাগতে পারে)"

# Wi-Fi scan result
SCAN_RESULT=$(termux-wifi-scaninfo 2>&1)

# Check JSON validity
if ! echo "$SCAN_RESULT" | jq empty >/dev/null 2>&1; then
    echo "❌ Error: termux-wifi-scaninfo valid JSON ফেরত দেয় নাই।"
    echo "Output ছিলো:"
    echo "$SCAN_RESULT"
    exit 1
fi

# Header
printf "%-30s %-20s %-7s %-8s %-10s %-10s %s\n" "SSID" "BSSID" "RSSI" "Channel" "Freq(MHz)" "Security" "Range"
printf "%s\n" "---------------------------------------------------------------------------------------------------------"

# Process JSON
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
    if [ -z "$rssi_val" ]; then rng="Unknown"
    elif [ "$rssi_val" -ge -50 ]; then rng="Very Close (0-10m)"
    elif [ "$rssi_val" -ge -60 ]; then rng="Close (10-20m)"
    elif [ "$rssi_val" -ge -70 ]; then rng="Moderate (20-40m)"
    elif [ "$rssi_val" -ge -80 ]; then rng="Far (40-80m)"
    else rng="Very Far (>80m)"
    fi

    # Print formatted row
    printf "%-30s %-20s %-7s %-8s %-10s %-10s %s\n" "$ssid" "$bssid" "$rssi" "$channel" "$freq" "$sec" "$rng"

done
