#!/usr/bin/env bash
# Generates the app_icon_* preview imagesets (Appearance settings, Welcome, Receive)
# from the 1024px sources in the AppIcon*.appiconset folders. An appiconset with a
# dark (luminosity) variant gets a dark variant in its preview imageset too.
# Run it after adding or changing an app icon, and commit the generated imagesets.
# A new icon also needs an entry in MAPPING below, in AppIconManager.allAppIcons
# and in App-Icons.xcconfig.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICONS_DIR="$ROOT/Unstoppable/Unstoppable/Resources/Assets.xcassets/AppIcon"

# appiconset name -> preview imageset name (without the .imageset suffix)
MAPPING=(
    "AppIcon:app_icon_main"
    "AppIconOrange:app_icon_orange"
    "AppIconMono:app_icon_mono"
    "AppIcon8ball:app_icon_8ball"
    "AppIconMonero:app_icon_monero"
    "AppIconZcash:app_icon_zcash"
    "AppIconPepe:app_icon_pepe"
    "AppIconDoge:app_icon_doge"
    "AppIconPunk:app_icon_punk"
    "AppIcon1874:app_icon_1874"
    "AppIconPlFlag:app_icon_pl_flag"
    "AppIconYS:app_icon_ys"
    "AppIconYesChad:app_icon_yes_chad"
    "AppIconGigaChad:app_icon_giga_chad"
)

SIZE_2X=120
SIZE_3X=180

# Prints the filename of the appiconset image for the given luminosity:
# "" for the default (any) appearance, "dark" for the dark one.
# Prints nothing when the appiconset has no image for it.
variant_filename() {
    local contents="$1"
    local luminosity="$2"
    local i=0

    while plutil -extract "images.$i" raw -o - "$contents" > /dev/null 2>&1; do
        local value filename
        value="$(plutil -extract "images.$i.appearances.0.value" raw -o - "$contents" 2>/dev/null || true)"
        filename="$(plutil -extract "images.$i.filename" raw -o - "$contents" 2>/dev/null || true)"

        if [[ "$value" == "$luminosity" && -n "$filename" ]]; then
            echo "$filename"
            return 0
        fi

        i=$((i + 1))
    done
}

write_contents_json() {
    local imageset="$1"
    local name="$2"
    local has_dark="$3"

    local dark_entries=""
    if [[ "$has_dark" == "1" ]]; then
        dark_entries=$(cat <<JSON
,
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "${name}-dark@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "${name}-dark@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
JSON
)
    fi

    cat > "$imageset/Contents.json" <<JSON
{
  "images" : [
    {
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "${name}@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "${name}@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }${dark_entries}
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON
}

resize() {
    local src="$1"
    local out_base="$2"

    sips -z "$SIZE_2X" "$SIZE_2X" "$src" --out "${out_base}@2x.png" > /dev/null
    sips -z "$SIZE_3X" "$SIZE_3X" "$src" --out "${out_base}@3x.png" > /dev/null
}

for entry in "${MAPPING[@]}"; do
    appiconset_name="${entry%%:*}"
    preview_name="${entry#*:}"
    appiconset="$ICONS_DIR/$appiconset_name.appiconset"
    imageset="$ICONS_DIR/$preview_name.imageset"

    if [[ ! -d "$appiconset" ]]; then
        echo "error: $appiconset does not exist" >&2
        exit 1
    fi

    contents="$appiconset/Contents.json"
    light_file="$(variant_filename "$contents" "")"
    dark_file="$(variant_filename "$contents" "dark")"

    if [[ -z "$light_file" || ! -f "$appiconset/$light_file" ]]; then
        echo "error: no default-appearance image in $contents" >&2
        exit 1
    fi
    if [[ -n "$dark_file" && ! -f "$appiconset/$dark_file" ]]; then
        echo "error: $appiconset/$dark_file is listed in Contents.json but missing" >&2
        exit 1
    fi

    mkdir -p "$imageset"
    find "$imageset" -maxdepth 1 -name '*.png' -delete

    resize "$appiconset/$light_file" "$imageset/$preview_name"
    if [[ -n "$dark_file" ]]; then
        resize "$appiconset/$dark_file" "$imageset/${preview_name}-dark"
        write_contents_json "$imageset" "$preview_name" 1
        echo "$appiconset_name -> $preview_name (light + dark)"
    else
        write_contents_json "$imageset" "$preview_name" 0
        echo "$appiconset_name -> $preview_name"
    fi
done
