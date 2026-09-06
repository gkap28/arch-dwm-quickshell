import QtQuick
import Quickshell
import Quickshell.Io

pragma ComponentBehavior: Bound

Item {
    id: root

    property int updateCount: 0
    property var updateList: []
    property bool checking: false
    property bool updating: false
    property bool detailVisible: false

    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

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
                root.checking = false
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

    Process {
        id: updateInstallProcess

        command: ["sudo", "-n", "xbps-install", "-Su"]
        running: false

        onRunningChanged: {
            if (!running) {
                root.updating = false
                root.refresh()
            }
        }
    }

    function refresh() {
        if (root.checking) return
        root.checking = true
        updateProcess.running = true
    }

    function loadDetails() {
        detailProcess.command = ["bash", "-c", "xbps-install -nuM | head -20"]
        detailProcess.running = true
    }

    function installUpdates() {
        if (root.updating) return
        root.updating = true
        root.detailVisible = true
        updateInstallProcess.running = true
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
