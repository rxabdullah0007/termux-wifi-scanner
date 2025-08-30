#!/data/data/com.termux/files/usr/bin/bash
# Termux Wi-Fi Scanner with Frames
# Legal / Educational

echo "🔍 Scanning Wi-Fi networks... (wait a few seconds)"
SCAN_RESULT=$(termux-wifi-scaninfo 2>&1)

# Check JSON validity
if ! echo "$SCAN_RESULT" | jq empty >/dev/null 2>&1; then
    echo "❌ Error: termux-wifi-scaninfo valid JSON not returned."
    echo "$SCAN_RESULT"
    exit 1
fi

# Process each network
echo
echo "📡 Wi-Fi Networks Scan Results"
echo "=============================="

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

    # Print in a frame
    echo "┌───────────────────────────────────────────────────────────┐"
    printf "│ %-15s : %-30s │\n" "SSID" "$ssid"
    printf "│ %-15s : %-30s │\n" "BSSID" "$bssid"
    printf "│ %-15s : %-30s │\n" "RSSI" "$rssi dBm"
    printf "│ %-15s : %-30s │\n" "Channel" "$channel"
    printf "│ %-15s : %-30s │\n" "Frequency" "$freq MHz"
    printf "│ %-15s : %-30s │\n" "Security" "$sec"
    printf "│ %-15s : %-30s │\n" "Range" "$rng"
    printf "│ %-15s : %-30s │\n" "Password" "NULL"
    echo "└───────────────────────────────────────────────────────────┘"
    echo
done

echo "✅ Scan Completed. All passwords shown as NULL (legal & safe)"
