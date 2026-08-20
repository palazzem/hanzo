// Managed by Hanzo. Do not edit manually.
//
// Plasma Scripting API layout defining a custom panel: top edge, dodge-
// windows auto-hide, height 42, Application Dashboard launcher with a
// custom icon, centered task manager with a fixed pinned-apps list, system
// tray, and a bold monospace digital clock with week numbers shown. No
// pager, no show-desktop widget.
//
// Removes any existing panel(s) first, so this is safe to run on a fresh
// default panel or to re-run idempotently on top of itself.

var existing = panels();
for (var i = 0; i < existing.length; i++) {
    existing[i].remove();
}

var panel = new Panel;
panel.screen = 0;
panel.location = "top";
panel.floating = true;
panel.hiding = "dodgewindows";
panel.height = 42;

var launcher = panel.addWidget("org.kde.plasma.kickerdash");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("useCustomButtonImage", true);
launcher.writeConfig("customButtonImage", "kapman");

panel.addWidget("org.kde.plasma.panelspacer");

var taskManager = panel.addWidget("org.kde.plasma.icontasks");
taskManager.currentConfigGroup = ["General"];
taskManager.writeConfig(
    "launchers",
    "applications:org.kde.dolphin.desktop,preferred://browser," +
    "applications:com.mitchellh.ghostty.desktop," +
    "applications:spotify-launcher.desktop," +
    "applications:signal.desktop," +
    "applications:systemsettings.desktop"
);

panel.addWidget("org.kde.plasma.panelspacer");

panel.addWidget("org.kde.plasma.systemtray");

var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("autoFontAndSize", false);
clock.writeConfig("boldText", true);
clock.writeConfig("firstDayOfWeek", 1);
clock.writeConfig("fontFamily", "DejaVu Sans Mono");
clock.writeConfig("fontSize", 8);
clock.writeConfig("fontStyleName", "Bold");
clock.writeConfig("fontWeight", 700);
clock.writeConfig("showWeekNumbers", true);

// Not added: org.kde.plasma.pager (redundant with the Meta+1..N desktop
// shortcuts), org.kde.plasma.showdesktop.
