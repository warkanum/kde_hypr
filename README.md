# kde_hyper — Hyprland-style shortcuts for KDE Plasma 6 (Wayland)

    ./active.sh -n     # dry run (prints every change, touches nothing)
    ./active.sh        # apply live (backup -> backup/<timestamp>/)

| File | Purpose |
|---|---|
| `active.sh` | Binding table (`b`/`l` lines) + apply. Edit TERM_CMD/BROWSER_CMD/FILES_CMD/DESKTOPS at top |
| `scripts/bind.py` | Sets keys live via kglobalaccel D-Bus, steals conflicting keys |
| `scripts/kwin/hyper-desktop/` | KWin script: Mod+Tab = previous desktop |

## Keys (Mod = Meta)
| Keys | Action |
|---|---|
| Mod+F / Mod+Shift+F | maximize toggle / fullscreen |
| Mod+Q / N / V | close / minimize / keep-above |
| Mod+H J K L | focus left/down/up/right |
| Mod+Shift+H J K L | tile left/bottom/top/right |
| Mod+Alt+Arrows | pack window to edge |
| Mod+Alt+M / R | keyboard move / resize |
| Mod+1..9 / Mod+Shift+1..9 | go to / send window to desktop |
| Mod+Tab | toggle previous desktop |
| Mod+Ctrl+Left/Right (+Shift) | prev/next desktop (move window) |
| Mod+, / Mod+. (+Shift) | prev/next screen (move window) |
| Mod+Return / D / E / B | terminal / krunner / files / browser |
| Mod+W / Mod+Shift+D | overview / show desktop |
| Mod+Alt+L / Mod+Shift+E | lock / logout |
| Mod+Shift+S, Print | region screenshot, Spectacle default |

Not done: Mod+Scroll desktop switching (KWin has no wheel binding for it).
Stolen defaults: task-manager Mod+1..9, Mod+V clipboard, Mod+B power profile, Mod+E Dolphin, Mod+. emoji, Mod+Alt+L layout switch, Mod+Alt+R screen record.
