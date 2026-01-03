#!/usr/bin/env -S bash
set -euo pipefail


# -- Pretty output --
say()  { echo "$*"; }
info() { say "[🚧] $*"; }
ok()   { say "[✅] $*"; }
skip() { say "[💨] $*"; }
warn() { say "[🤨] $*"; }
ask()  { echo -n "[❓] $*"; }


# -- Values --
SOURCE_DIR="themes"
OUT_DIR="dist"
DEST="/var/www/pufferpanel/theme"


THEME=""        # if empty => build all themes
AUTO_COPY=0     # 1 => copy without prompt


usage() {
  cat <<EOF
Usage: $(basename "$0") [options]


Options:
  -t <name>   Build only one theme (folder name inside ${SOURCE_DIR}/).
  -y          Copy built .tar files to DEST without prompting.
  -d <path>   Destination folder for copying (default: ${DEST})
  -s <path>   Source themes folder (default: ${SOURCE_DIR})
  -h          Show this help.


Examples:
  ./build-themes.sh
  ./build-themes.sh -t dark
  ./build-themes.sh -y
  ./build-themes.sh -t dark -y -d /tmp/puffer-themes
EOF
}


while getopts ":t:yd:s:h" opt; do
  case "$opt" in
    t) THEME="$OPTARG" ;;
    y) AUTO_COPY=1 ;;
    d) DEST="$OPTARG" ;;
    s) SOURCE_DIR="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) warn "Unknown option: -$OPTARG"; usage; exit 2 ;;
    :)  warn "Option -$OPTARG requires an argument."; usage; exit 2 ;;
  esac
done


# -- Validate --
if [[ ! -d "$SOURCE_DIR" ]]; then
  warn "Themes folder not found: $SOURCE_DIR"
  exit 1
fi


mkdir -p "$OUT_DIR"
info "Building your themes..."


build_theme() {
  local dir="$1"
  local theme_name
  theme_name="$(basename "$dir")"


  # required files
  if [[ ! -f "$dir/theme.json" || ! -f "$dir/theme.css" ]]; then
    skip "Skipping ($theme_name) as one or more required files are missing :/"
    return 0
  fi


  # build tar
  if [[ -d "$dir/img" ]]; then
    tar -cf "${OUT_DIR}/${theme_name}.tar" -C "$dir" theme.css theme.json img/
  else
    tar -cf "${OUT_DIR}/${theme_name}.tar" -C "$dir" theme.css theme.json
  fi


  ok "Built $theme_name successfully."
}


# -- Build (one / all) --
if [[ -n "$THEME" ]]; then
  THEME_DIR="${SOURCE_DIR}/${THEME}"
  if [[ ! -d "$THEME_DIR" ]]; then
    warn "Theme not found: ${THEME_DIR}"
    exit 1
  fi
  build_theme "$THEME_DIR"
else
  shopt -s nullglob
  theme_dirs=("${SOURCE_DIR}"/*/)
  shopt -u nullglob


  if (( ${#theme_dirs[@]} == 0 )); then
    warn "No themes found in: ${SOURCE_DIR}"
    exit 1
  fi


  for dir in "${theme_dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    build_theme "$dir"
  done
fi


say ""


# -- Collect .tar's --
shopt -s nullglob
TARS=("${OUT_DIR}"/*.tar)
shopt -u nullglob


if (( ${#TARS[@]} == 0 )); then
  warn "No .tar files to copy :/"
  exit 0
fi


do_copy() {
  if [[ ! -d "$DEST" ]]; then
    sudo mkdir -p "$DEST"
  fi


  sudo cp -f "${OUT_DIR}"/*.tar "$DEST/"
  ok "Copied to ($DEST)!"
}


# -- Copy prompt / auto --
if (( AUTO_COPY == 1 )); then
  do_copy
else
  while true; do
    ask "Copy built .tar files to (${DEST})? [Y/n] "
    read -r ans
    ans="${ans:-Y}"


    case "$ans" in
      [Yy]*)
        do_copy
        break
        ;;
      [Nn]*)
        skip "Skipping copy.."
        break
        ;;
      *)
        say "Select 👉 [Y/n]"
        ;;
    esac
  done
fi
