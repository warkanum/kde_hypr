#!/usr/bin/env bash
# Hyprland-style KDE (Plasma 6, Wayland) shortcuts.  Usage: active.sh [-n]   (-n = dry run)
set -euo pipefail
HERE=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
S=$HERE/scripts
DRY=0; [[ ${1:-} == -n ]] && DRY=1
export DRY

# ---- config ---------------------------------------------------------------
TERM_CMD=kitty
BROWSER_CMD=firefox
FILES_CMD=dolphin
DESKTOPS=9
# ---------------------------------------------------------------------------

run() { if ((DRY)); then echo "[dry] $*"; else "$@"; fi; }

# backup
if ((!DRY)); then
  B=$HERE/backup/$(date +%Y%m%d-%H%M%S); mkdir -p "$B"
  cp ~/.config/kglobalshortcutsrc ~/.config/kwinrc "$B"/
  echo "backup: $B"
fi

BINDS=$(mktemp); trap 'rm -f "$BINDS"' EXIT
b() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "${4:-set}" >> "$BINDS"; }   # comp action keys [mode]
APPS=~/.local/share/applications
l() {  # id name exec keys  -> custom command shortcut
  local f=$APPS/hyper-$1.desktop
  if ((!DRY)); then
    printf '[Desktop Entry]\nType=Application\nName=%s\nExec=%s\nNoDisplay=true\nX-KDE-GlobalAccel-CommandShortcut=true\n' "$2" "$3" > "$f"
  fi
  b "hyper-$1.desktop" _launch "$4"
}

# ---- windows (1-9) ---------------------------------------------------------
b kwin "Window Fullscreen"            Meta+Shift+F
b kwin "Window Close"                 Meta+Q
b kwin "Window Maximize"              Meta+F
b kwin "Window Above Other Windows"   Meta+V
b kwin "Window Minimize"              Meta+N
b kwin "Switch Window Left"           Meta+H
b kwin "Switch Window Down"           Meta+J
b kwin "Switch Window Up"             Meta+K
b kwin "Switch Window Right"          Meta+L
b kwin "Window Quick Tile Left"       Meta+Shift+H
b kwin "Window Quick Tile Right"      Meta+Shift+L
b kwin "Window Quick Tile Top"        Meta+Shift+K
b kwin "Window Quick Tile Bottom"     Meta+Shift+J
b kwin "Window Pack Left"             Meta+Alt+Left
b kwin "Window Pack Right"            Meta+Alt+Right
b kwin "Window Pack Up"               Meta+Alt+Up
b kwin "Window Pack Down"             Meta+Alt+Down
b kwin "Window Move"                  Meta+Alt+M
b kwin "Window Resize"                Meta+Alt+R

# ---- desktops (10-14) ------------------------------------------------------
for i in $(seq 1 9); do
  b kwin "Switch to Desktop $i" "Meta+$i"
  b kwin "Window to Desktop $i" "Meta+Shift+$i"
done
b kwin HyperTogglePrevDesktop         Meta+Tab
b kwin "Switch One Desktop to the Left"        Meta+Ctrl+Left
b kwin "Switch One Desktop to the Right"       Meta+Ctrl+Right
b kwin "Window One Desktop to the Left"        Meta+Ctrl+Shift+Left
b kwin "Window One Desktop to the Right"       Meta+Ctrl+Shift+Right

# ---- screens (16-17) -------------------------------------------------------
b kwin "Switch to Previous Screen"    Meta+Comma
b kwin "Switch to Next Screen"        Meta+Period
b kwin "Window to Previous Screen"    Meta+Shift+Comma
b kwin "Window to Next Screen"        Meta+Shift+Period

# ---- launchers / misc (18-26) ---------------------------------------------
l term     "Hyper Terminal"   "$TERM_CMD"                                          Meta+Return
l runner   "Hyper KRunner"    "qdbus6 org.kde.krunner /App org.kde.krunner.App.toggleDisplay" Meta+D
l files    "Hyper Files"      "$FILES_CMD"                                         Meta+E
l browser  "Hyper Browser"    "$BROWSER_CMD"                                       Meta+B
l shot     "Hyper Screenshot" "spectacle -r"                                       Meta+Shift+S
b kwin "Overview"                     Meta+W
b kwin "Show Desktop"                 Meta+Shift+D
b ksmserver "Lock Session"            Meta+Alt+L add
b ksmserver "Log Out"                 Meta+Shift+E add
# Print stays on Spectacle's own default.

# ---- apply -----------------------------------------------------------------
# virtual desktops
cur=$(qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.count)
for ((n=cur; n<DESKTOPS; n++)); do run qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.createDesktop "$n" "Desktop $((n+1))"; done
run qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.rows 1
run kwriteconfig6 --file kwinrc --group Desktops --key Number "$DESKTOPS"
run kwriteconfig6 --file kwinrc --group Desktops --key Rows 1

# kwin script (previous-desktop toggle)
run kpackagetool6 --type=KWin/Script --upgrade "$S/kwin/hyper-desktop" 2>/dev/null || run kpackagetool6 --type=KWin/Script --install "$S/kwin/hyper-desktop"
run kwriteconfig6 --file kwinrc --group Plugins --key hyper-desktopEnabled true
run qdbus6 org.kde.KWin /KWin reconfigure
((DRY)) || sleep 1

python3 -I "$S/bind.py" < "$BINDS"
echo done
