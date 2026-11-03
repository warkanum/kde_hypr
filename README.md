# kde_hypr — Hyprland-style shortcuts for KDE Plasma 6 (Wayland)

    ./active.sh -n              dry run
    ./active.sh                 apply (backup -> backup/<ts>/)
    ./active.sh --check         drift + keys taken from other actions
    ./active.sh --restore       undo (default keys, launchers, kwin script, mouse, autostart)
    ./active.sh --autostart on|off
    ./active.sh --reload        apply without backup (also Mod+Shift+R)

| File | Purpose |
|---|---|
| `config.env` | apps, DESKTOPS, MOD_KEY, scratchpad command |
| `bindings.conf` | all keys: `bind\|comp\|action\|keys[\|set\|add]`, `launch\|id\|Name\|cmd\|keys` |
| `scripts/bind.py` | live apply/check/restore via kglobalaccel D-Bus |
| `scripts/kwin/hyper-desktop/` | KWin script: Mod+Tab prev desktop, scratchpad window |
| `scripts/scratchpad.sh` | Mod+S dropdown terminal |

`set` replaces Meta keys but keeps Alt+F4, Ctrl+F1.. ; `add` appends (media keys, lock, logout).

## Keys (Mod = Meta)
| Keys | Action |
|---|---|
| Mod+F / Shift+F | maximize toggle / fullscreen |
| Mod+Q N V | close / minimize / keep-above |
| Mod+H J K L | focus |
| Mod+Shift+H J K L | tile halves |
| Mod+Ctrl+Y U B N | tile quarters |
| Mod+G / Mod+T | grid view / tile editor |
| Mod+Alt+Arrows, M, R | pack to edge, kb move, kb resize |
| Mod+LMB / RMB drag | move / resize |
| Mod+Wheel | prev/next desktop |
| Mod+1..9 (+Shift) | desktop (send window) |
| Mod+Tab | toggle previous desktop |
| Mod+Shift+Tab / Mod+Alt+Tab | cycle desktops back / forward |
| Mod+Ctrl+Arrows (+Shift) | prev/next desktop (move window) |
| Mod+, . (+Shift) | prev/next screen (move window) |
| Mod+Return D E B | terminal / krunner / files / browser |
| Mod+S | scratchpad terminal |
| Mod+W, Mod+Ctrl+Tab, Mod+Shift+D | overview, all windows, show desktop |
| Mod+Alt+L, Mod+Shift+E | lock, logout |
| Mod+Shift+S, Print | region screenshot, Spectacle |
| Mod+Shift+V, Mod+Ctrl+E | clipboard history, emoji |
| Mod+F1-F4 | mute, vol-, vol+, mic mute |
| Mod+F7-F9 | prev, play/pause, next |
| Mod+F10 / F11 | brightness -/+ |
| Mod+Shift+R | reload this config |

No colour picker (kcolorchooser not installed).
