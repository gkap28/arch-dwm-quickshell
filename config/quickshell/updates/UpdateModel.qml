import QtQuick
import Quickshell
import Quickshell.Io

pragma ComponentBehavior: Bound

Item {
    id: root
    
    property int updateCount: 0
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
        
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/check-updates.sh"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                root.checking = false
                const output = this.text.trim()
                root.updateCount = parseInt(output) || 0
                
                if (root.updateCount > 0) {
                    console.log("Updates verfügbar:", root.updateCount)
                }
            }
        }
        
        onRunningChanged: {
            if (!running) {
                root.checking = false
            }
        }
    }
    
    function refresh() {
        if (root.checking) return
        root.checking = true
        updateProcess.running = true
    }
    
    function toggle() {
        detailVisible = !detailVisible
    }
    
    function close() {
        detailVisible = false
    }
    
    function open() {
        detailVisible = true
    }
}
