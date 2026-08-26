import Quickshell
import Quickshell.Io

Scope {
    id: root

    property int currentWorkspace: 0
    property var monitorWorkspaceRows: []
    property var workspaceNames: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
    property var occupiedWorkspaces: []
    property var fullscreenMonitorIndexes: []
    property var runningApps: []
    property string activeWindowTitle: "Desktop"
    property string activeWindowClass: "application-x-executable"
    property string statusText: ""
    property var statusSegments: []
    property bool batteryAvailable: false
    property int batteryPercent: 0
    property string batteryStatus: ""

    function parseState(text) {
        const lines = text.trim().split("\n");

        for (const line of lines) {
            const separator = line.indexOf("=");

            if (separator < 0) {
                continue;
            }

            const key = line.slice(0, separator);
            const value = line.slice(separator + 1);

            if (key === "current") {
                const parsed = parseInt(value, 10);

                root.currentWorkspace = isNaN(parsed) ? 0 : parsed;
            } else if (key === "monitor_desktops") {
                const fields = value.length > 0 ? value.split(",") : [];
                const rows = [];

                for (let index = 0; index + 4 < fields.length; index += 5) {
                    rows.push({
                        "x": parseInt(fields[index], 10),
                        "y": parseInt(fields[index + 1], 10),
                        "width": parseInt(fields[index + 2], 10),
                        "height": parseInt(fields[index + 3], 10),
                        "desktop": parseInt(fields[index + 4], 10)
                    });
                }
                root.monitorWorkspaceRows = rows;
            } else if (key === "names") {
                root.workspaceNames = value.length > 0 ? value.split("|") : [];
            } else if (key === "occupied") {
                root.occupiedWorkspaces = value.length > 0 ? value.split("|").map(function(workspace) {
                    return parseInt(workspace, 10);
                }) : [];
            } else if (key === "fullscreen_monitors") {
                root.fullscreenMonitorIndexes = value.length > 0 ? value.split("|").map(function(monitor) {
                    return parseInt(monitor, 10);
                }) : [];
            } else if (key === "apps") {
                root.runningApps = value.length > 0 ? value.split("|").map(function(app) {
                    const separator = app.indexOf(":");
                    return { "windowId": app.slice(0, separator), "appClass": app.slice(separator + 1) };
                }) : [];
            } else if (key === "title") {
                root.activeWindowTitle = value.length > 0 ? value : "Desktop";
            } else if (key === "class") {
                root.activeWindowClass = value.length > 0 ? value : "application-x-executable";
            } else if (key === "status") {
                root.statusText = value;
                root.updateStatusSegments();
            }
        }
    }

    function workspaceOccupied(index) {
        return root.occupiedWorkspaces.indexOf(index) !== -1;
    }

    function screenIndex(screen) {
        if (!screen) {
            return 0;
        }

        // HDMI-A-0 ist immer Monitor 0 / Primary.
        if (screen.name === "HDMI-A-0") {
            return 0;
        }

        // DisplayPort-2 ist immer Monitor 1 / Secondary.
        if (screen.name === "DisplayPort-2") {
            return 1;
        }

        return 0;
    }

    function workspaceIndexes(screen) {
        // Jeder Monitor hat alle 9 Workspaces (1-9)
        const indexes = [];
        for (let index = 0; index < 9 && index < root.workspaceNames.length; index++) {
            indexes.push(index);
        }
        return indexes;
    }

    function currentWorkspaceForScreen(screen) {
        const logicalIndex = root.screenIndex(screen);
        const indexes = root.workspaceIndexes(screen);
        const reported = logicalIndex < root.monitorWorkspaceRows.length
            ? root.monitorWorkspaceRows[logicalIndex].desktop : root.currentWorkspace;

        return indexes.indexOf(reported) !== -1
            ? reported : (indexes.length > 0 ? indexes[0] : -1);
    }

    function switchWorkspaceForScreen(screen, index) {
        if (root.workspaceIndexes(screen).indexOf(index) === -1) {
            return;
        }

        root.switchWorkspace(index);
    }

    function updateStatusSegments() {
        const text = root.statusText.trim();

        root.batteryAvailable = false;
        root.batteryPercent = 0;
        root.batteryStatus = "";

        if (text.length === 0 || text.indexOf("dwm-titus:") === 0) {
            root.statusSegments = [];
            return;
        }

        root.statusSegments = text.split(/\s+\|\s+| {2,}/).filter(function(segment) {
            const trimmed = segment.trim();

            if (trimmed.indexOf("BAT ") === 0) {
                const battery = trimmed.match(/^BAT\s+([0-9]+)%\s*(.*)$/);

                if (battery) {
                    root.batteryAvailable = true;
                    root.batteryPercent = Math.max(0, Math.min(100, parseInt(battery[1], 10)));
                    root.batteryStatus = battery[2].trim();
                }

                return false;
            }

            return trimmed.length > 0 && trimmed !== "AC"
                && trimmed.indexOf("NET ") !== 0 && trimmed.indexOf("VOL ") !== 0;
        });
    }

    function switchWorkspace(index) {
        switchWorkspaceProcess.command = ["dwm-quickshell-state", "switch", index.toString()];
        switchWorkspaceProcess.running = true;
    }

    function focusWindow(windowId) {
        focusWindowProcess.command = ["dwm-quickshell-state", "focus", windowId];
        focusWindowProcess.running = true;
    }

    Process {
        command: ["dwm-quickshell-state", "watch"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n\n"
            onRead: function(data) {
                root.parseState(data);
            }
        }
    }

    Process {
        id: switchWorkspaceProcess

        command: ["dwm-quickshell-state", "switch", root.currentWorkspace.toString()]
        running: false
    }

    Process {
        id: focusWindowProcess

        command: ["dwm-quickshell-state", "focus", "0"]
        running: false
    }
}
