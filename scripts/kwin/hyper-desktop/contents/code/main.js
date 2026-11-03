// Toggle to the previously active virtual desktop (Hyprland Mod+Tab style).
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
