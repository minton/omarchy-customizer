#!/bin/bash

CONFIG_FILE="/home/minton/.config/waybar/config.jsonc"
TEMP_FILE=$(mktemp)

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed. Please install jq."
  exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: $CONFIG_FILE not found"
  exit 1
fi

# New clock configuration as a JSON string
NEW_CLOCK_CONFIG='{
    "format": "{:%A %h %d %I:%M W%V}",
    "tooltip": true,
    "tooltip-format": "<tt><small>{calendar}</small></tt>",
    "calendar": {
        "mode": "month",
        "mode-mon-col": 3,
        "weeks-pos": "right",
        "on-scroll": 1,
        "on-click-right": "mode",
        "format": {
            "months": "<span color='\''#ffead3'\''><b>{}</b></span>",
            "days": "<span color='\''#ecc6d9'\''><b>{}</b></span>",
            "weeks": "<span color='\''#99ffdd'\''><b>W{}</b></span>",
            "weekdays": "<span color='\''#ffcc66'\''><b>{}</b></span>",
            "today": "<span color='\''#ff6699'\''><b><u>{}</u></b></span>"
        }
    },
    "on-click-right": "omarchy-cmd-tzupdate"
}'

# Function to strip comments from JSONC
strip_comments() {
  # Remove single-line comments (//) and multi-line comments (/* */)
  sed -E 's|//.*$||g' "$1" | sed -E '/\/\*/,/\*\//d'
}

# Process the config file
strip_comments "$CONFIG_FILE" >"$TEMP_FILE"

# Replace the entire clock config with the new one
if ! jq --argjson new_clock "$NEW_CLOCK_CONFIG" '.clock = $new_clock' "$TEMP_FILE" >"$TEMP_FILE.json"; then
  echo "Error: Failed to replace clock configuration"
  rm -f "$TEMP_FILE"
  exit 1
fi

# Move the updated config back to the original file
mv "$TEMP_FILE.json" "$CONFIG_FILE"
rm -f "$TEMP_FILE"

# Restart Waybar: kill existing process (if any) and start a new one
pkill -x waybar
sleep 1 # Brief pause to ensure the process terminates
if ! waybar &>/dev/null & then
  echo "Error: Failed to start Waybar. Check the configuration file for errors."
  exit 1
fi
echo "Successfully replaced clock configuration in $CONFIG_FILE and restarted Waybar"
