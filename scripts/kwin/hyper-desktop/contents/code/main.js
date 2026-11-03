// Hyprland-style helpers: previous-desktop toggle + dropdown scratchpad.
var cur = workspace.currentDesktop;
var last = null;

workspace.currentDesktopChanged.connect(function () {
    if (workspace.currentDesktop !== cur) {
        last = cur;
        cur = workspace.currentDesktop;
    }
});

registerShortcut("HyperTogglePrevDesktop", "Hyper: Toggle Previous Desktop", "Meta+Tab", function () {
    if (last && workspace.desktops.indexOf(last) !== -1) {
        workspace.currentDesktop = last;
    }
});

// ---- scratchpad: window with class hypr-scratch --------------------------
function isScratch(w) { return String(w.resourceClass).toLowerCase() === "hypr-scratch"; }

function place(w) {
    var a = workspace.clientArea(KWin.MaximizeArea, w);
    var width = Math.round(a.width * 0.8), height = Math.round(a.height * 0.45);
    w.frameGeometry = { x: a.x + Math.round((a.width - width) / 2), y: a.y, width: width, height: height };
    w.keepAbove = true;
    w.skipTaskbar = true;
    w.skipPager = true;
    w.skipSwitcher = true;
    w.onAllDesktops = true;
}

workspace.windowAdded.connect(function (w) {
    if (isScratch(w)) place(w);
    else if (w.windowClassChanged) w.windowClassChanged.connect(function () { if (isScratch(w)) place(w); });
});

registerShortcut("HyperScratchpadToggle", "Hyper: Toggle Scratchpad", "", function () {
    var list = workspace.windowList().filter(isScratch);
    if (!list.length) return;
    var w = list[0];
    if (w.minimized || workspace.activeWindow !== w) {
        w.minimized = false;
        workspace.activeWindow = w;
    } else {
        w.minimized = true;
    }
});
