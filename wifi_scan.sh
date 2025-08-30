#!/data/data/com.termux/files/usr/bin/bash
# wifi_scan.sh - Termux Wi-Fi Scanner Tool
# Author: Rx Abdullah

if ! command -v termux-wifi-scaninfo >/dev/null 2>&1; then
  echo "❌ termux-wifi-scaninfo পাওয়া যায়নি। প্রথমে 'pkg install termux-api' চালাও।"
  exit 1
fi

echo "🔍 Scanning Wi-Fi networks... (একটু সময় লাগতে পারে)"
SCAN_JSON=$(termux-wifi-scaninfo)

# Header
printf "%-30s %-20s %-7s %-8s %-10s %s\n" "SSID" "BSSID" "RSSI" "Channel" "Freq" "Security (Range)"
printf "%s\n" "---------------------------------------------------------------------------------------------------------"

echo "$SCAN_JSON" | jq -r '.[] | [
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
  # security detect
  sec="OPEN"
  caps_up=$(echo "$caps" | tr '[:lower:]' '[:upper:]')
  if echo "$caps_up" | grep -q "WPA3"; then sec="WPA3"
  elif echo "$caps_up" | grep -q "WPA2"; then sec="WPA2"
  elif echo "$caps_up" | grep -q "WPA"; then sec="WPA"
  elif echo "$caps_up" | grep -q "WEP"; then sec="WEP"
  fi

  # range estimate
  rssi_val=$(echo "$rssi" | sed 's/[^0-9-]//g')
  if [ -z "$rssi_val" ]; then rng="unknown"
  elif [ "$rssi_val" -ge -50 ]; then rng="Very close (0-10m)"
  elif [ "$rssi_val" -ge -60 ]; then rng="Close (10-20m)"
  elif [ "$rssi_val" -ge -70 ]; then rng="Moderate (20-40m)"
  elif [ "$rssi_val" -ge -80 ]; then rng="Far (40-80m)"
  else rng="Very far (>80m)"
  fi

  printf "%-30s %-20s %-7s %-8s %-10s %s (%s)\n" "$ssid" "$bssid" "$rssi" "$channel" "$freq" "$sec" "$rng"
done
