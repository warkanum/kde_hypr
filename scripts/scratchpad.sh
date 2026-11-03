#!/usr/bin/env bash
# Toggle the dropdown scratchpad terminal (window handling lives in the KWin script).
. "$(dirname "$(readlink -f "$0")")/../config.env"
if pgrep -f "^([^ ]*/)?$SCRATCH_CMD" >/dev/null; then
  qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut HyperScratchpadToggle
else
  setsid $SCRATCH_CMD >/dev/null 2>&1 &
fi
