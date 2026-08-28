import QtQuick
import Quickshell
import Quickshell.Io

pragma ComponentBehavior: Bound

Item {
    id: root

    property int updateCount: 0
    property var updateList: []
    property bool checking: false
    property bool detailVisible: false

    // Timer für automatische Aktualisierung (alle 30 Minuten)
    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    // Initial laden
    Component.onCompleted: {
        root.refresh()
    }

    Process {
        id: updateProcess

        command: ["/usr/local/bin/check-updates.sh"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim()
                root.updateCount = parseInt(output) || 0
                console.log("Update-Count:", root.updateCount)
            }
        }

        onRunningChanged: {
            if (!running) {
                root.checking = false
            }
        }
    }

    Process {
        id: detailProcess

        command: []
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim()
                if (output.length > 0) {
                    root.updateList = output.split("\n")
                } else {
                    root.updateList = ["System ist aktuell"]
                }
            }
        }
    }

    function refresh() {
        if (root.checking) return
        root.checking = true
        updateProcess.running = true
    }

    function loadDetails() {
        detailProcess.command = ["bash", "-c", "checkupdates 2>/dev/null | head -20; echo '--- AUR ---'; paru -Qua 2>/dev/null | head -10"]
        detailProcess.running = true
    }

    function toggle() {
        detailVisible = !detailVisible
        if (detailVisible) {
            root.loadDetails()
        }
    }

    function close() {
        detailVisible = false
    }

    function open() {
        detailVisible = true
        root.loadDetails()
    }
}
