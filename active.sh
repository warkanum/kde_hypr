#!/usr/bin/env bash
# Hyprland-style KDE (Plasma 6, Wayland) shortcuts.
#   active.sh               apply (backs up first)
#   active.sh -n            dry run
#   active.sh --check       drift + list of keys taken from other actions
#   active.sh --restore     undo: default keys back, launchers/script/autostart/mouse removed
#   active.sh --autostart on|off
#   active.sh --reload|--login   apply without backup (hotkey / session start)
set -euo pipefail
HERE=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
S=$HERE/scripts
APPS=~/.local/share/applications
AUTO=~/.config/autostart/kde-hypr.desktop
. "$HERE/config.env"

if [[ $KEYSTYLE == vim ]]; then LEFT=H DOWN=J UP=K RIGHT=L; else LEFT=Left DOWN=Down UP=Up RIGHT=Right; fi
MODE=apply; export DRY=0
case "${1:-}" in
  -n) DRY=1 ;;
  --check) MODE=check ;;
  --restore) MODE=restore ;;
  --autostart) MODE=autostart ;;
  --reload|--login) MODE=quick ;;
  "") ;;
  *) sed -n '2,8p' "$0"; exit 1 ;;
esac
run() { if ((DRY)); then echo "[dry] $*"; else "$@"; fi; }

# parse bindings.conf -> TSV for bind.py, plus launcher .desktop files
BINDS=$(mktemp); trap 'rm -f "$BINDS"' EXIT
while IFS='|' read -r kind a b c d e; do
  [[ -z $kind || $kind == \#* ]] && continue
  case $kind in
    bind)   c=${c//\$LEFT/$LEFT}; c=${c//\$DOWN/$DOWN}; c=${c//\$UP/$UP}; c=${c//\$RIGHT/$RIGHT}
            printf '%s\t%s\t%s\t%s\n' "$a" "$b" "$c" "${d:-set}" >> "$BINDS" ;;
    launch) cmd=${c//\$TERM_CMD/$TERM_CMD}; cmd=${cmd//\$BROWSER_CMD/$BROWSER_CMD}
            cmd=${cmd//\$FILES_CMD/$FILES_CMD}; cmd=${cmd//\$HERE/$HERE}
            printf 'hyper-%s.desktop\t_launch\t%s\tset\n' "$a" "$d" >> "$BINDS"
            if [[ $MODE != check && $MODE != restore && $MODE != autostart ]] && ((!DRY)); then
              printf '[Desktop Entry]\nType=Application\nName=%s\nExec=%s\nNoDisplay=true\nX-KDE-GlobalAccel-CommandShortcut=true\n' "$b" "$cmd" > "$APPS/hyper-$a.desktop"
            fi ;;
    *) echo "bad line in bindings.conf: $kind" >&2; exit 1 ;;
  esac
done < "$HERE/bindings.conf"

case $MODE in
check)
  python3 -I "$S/bind.py" check < "$BINDS"; exit ;;
autostart)
  if [[ ${2:-} == on ]]; then
    mkdir -p ~/.config/autostart
    printf '[Desktop Entry]\nType=Application\nName=kde_hypr shortcuts\nExec=%s/active.sh --login\nX-KDE-autostart-after=panel\n' "$HERE" > "$AUTO"
    echo "autostart on"
  elif [[ ${2:-} == off ]]; then rm -f "$AUTO"; echo "autostart off"
  else echo "usage: active.sh --autostart on|off"; exit 1; fi
  exit ;;
restore)
  python3 -I "$S/bind.py" restore
  rm -f "$APPS"/hyper-*.desktop "$AUTO"
  kwriteconfig6 --file kwinrc --group Plugins --key hyper-desktopEnabled false
  kpackagetool6 --type=KWin/Script --remove hyper-desktop 2>/dev/null || true
  for k in CommandAllKey CommandAll1 CommandAll3 CommandAllWheel; do
    kwriteconfig6 --file kwinrc --group MouseBindings --key $k --delete; done
  kwriteconfig6 --file kwinrc --group Windows --key FocusStealingPreventionLevel --delete
  qdbus6 org.kde.KWin /KWin reconfigure
  echo "restored (desktop count left as is)"; exit ;;
esac

[[ $MODE == quick && ${1:-} == --login ]] && sleep 5
if [[ $MODE == apply ]] && ((!DRY)); then
  B=$HERE/backup/$(date +%Y%m%d-%H%M%S); mkdir -p "$B"
  cp ~/.config/kglobalshortcutsrc ~/.config/kwinrc "$B"/; echo "backup: $B"
fi

# virtual desktops
cur=$(qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.count)
for ((n=cur; n<DESKTOPS; n++)); do run qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.createDesktop "$n" "Desktop $((n+1))"; done
run qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.rows 1
run kwriteconfig6 --file kwinrc --group Desktops --key Number "$DESKTOPS"
run kwriteconfig6 --file kwinrc --group Desktops --key Rows 1

# mouse: Mod+LMB move, Mod+RMB resize (wheel unbound); new windows always take focus
run kwriteconfig6 --file kwinrc --group MouseBindings --key CommandAllKey "$MOD_KEY"
run kwriteconfig6 --file kwinrc --group MouseBindings --key CommandAll1 Move
run kwriteconfig6 --file kwinrc --group MouseBindings --key CommandAll3 Resize
run kwriteconfig6 --file kwinrc --group MouseBindings --key CommandAllWheel --delete
run kwriteconfig6 --file kwinrc --group Windows --key FocusStealingPreventionLevel 0

# kwin script (prev-desktop toggle + scratchpad)
run kpackagetool6 --type=KWin/Script --upgrade "$S/kwin/hyper-desktop" >/dev/null 2>&1 || run kpackagetool6 --type=KWin/Script --install "$S/kwin/hyper-desktop"
run kwriteconfig6 --file kwinrc --group Plugins --key hyper-desktopEnabled true
run qdbus6 org.kde.KWin /KWin reconfigure
((DRY)) || sleep 1

python3 -I "$S/bind.py" apply < "$BINDS"
[[ ${1:-} == --reload ]] && notify-send -a kde_hypr "kde_hypr" "Shortcuts reloaded"
echo done
