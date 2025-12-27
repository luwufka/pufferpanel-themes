#! /bin/bash
set -euo pipefail

mkdir -p output
echo "🚧 > Building your themes..."

for dir in */; do
    # Skip unwanted folders
    [ "$dir" = ".github/" ] && continue
    [ "$dir" = "output/" ] && continue
    [ ! -d "$dir" ] && continue

    theme_name=$(basename "$dir")

    # Check required files exist
    if [[ -f "$dir/theme.json" && -f "$dir/theme.css" ]]; then
        if [[ -d "$dir/img" ]]; then
            tar -cf "output/${theme_name}.tar" -C "$dir" theme.css theme.json img/
        else
            tar -cf "output/${theme_name}.tar" -C "$dir" theme.css theme.json
        fi
        echo "✅ > Built $theme_name successfully."
    else
        echo "💨 > Skipping ($theme_name) as one or more required files are missing :/"
    fi
done

DEST="/var/www/pufferpanel/theme"
echo

# Q: Copy or not?
while true; do
  read -r -p "❓ > Copy built .tar files to (${DEST})? [Y/n] " ans
  ans="${ans:-Y}"
  case "$ans" in
    [Yy]*)
      # Creating folder
      if [[ ! -d "$DEST" ]]; then
        sudo mkdir -p "$DEST"
      fi

      shopt -s nullglob
      TARS=(output/*.tar)
      shopt -u nullglob

      if (( ${#TARS[@]} == 0 )); then
        echo "🤨 > No .tar files to copy :/"
        exit 0
      fi

      # Replace existing files
      sudo cp output/*.tar "$DEST/"
      echo "✅ > Copied to ($DEST)!"
      break
      ;;
    [Nn]*)
      echo "💨 > Skipping copy.."
      break
      ;;
    *)
      echo "Select 👉 [Y/n]: "
      ;;
  esac
done
