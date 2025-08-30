#!/data/data/com.termux/files/usr/bin/bash
# Wi-Fi Scanner + Password test (Education purpose)
# Author: Rx Abdullah

# =============================
# ⚠️ Legal Notice:
# This tool is ONLY for your own Wi-Fi or lab network testing.
# Do NOT use on networks you don't own. 
# =============================

echo "🔍 Scanning Wi-Fi networks... (wait a few seconds)"
SCAN_RESULT=$(termux-wifi-scaninfo 2>&1)

# Check JSON
if ! echo "$SCAN_RESULT" | jq empty >/dev/null 2>&1; then
    echo "❌ Error: termux-wifi-scaninfo valid JSON not returned."
    echo "Output was:"
    echo "$SCAN_RESULT"
    exit 1
fi

# Print header
printf "%-30s %-20s %-7s %-8s %-10s %-10s %s\n" "SSID" "BSSID" "RSSI" "Channel" "Freq(MHz)" "Security" "Range"
printf "%s\n" "---------------------------------------------------------------------------------------------------------"

# Process Wi-Fi networks
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

# =============================
# 🔹 Optional: Test your own password
# Only works on your own Wi-Fi network (educational)
# =============================

echo
read -p "Enter your Wi-Fi SSID for testing: " TEST_SSID
read -sp "Enter password(s) to test (comma separated): " PASSWORDS
echo

IFS=',' read -ra PW_ARR <<< "$PASSWORDS"

for pw in "${PW_ARR[@]}"; do
    pw_trimmed=$(echo $pw | xargs)
    # Use Termux command to attempt connection (educational, your own Wi-Fi)
    termux-wifi-connectioninfo | grep -q "$TEST_SSID" && echo "✅ Already connected to $TEST_SSID" && break
    echo "🔑 Trying password '$pw_trimmed' for $TEST_SSID (educational test)..."
    # NOTE: This does NOT hack, only attempts to use Termux API (legal)
    termux-wifi-connect "$TEST_SSID" "$pw_trimmed" >/dev/null 2>&1
    if termux-wifi-connectioninfo | grep -q "$TEST_SSID"; then
        echo "🎉 Success! Password '$pw_trimmed' works for $TEST_SSID"
        break
    fi
done

echo
echo "✅ Scan & Educational password test completed."
