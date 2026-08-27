import QtQuick
import Quickshell
import Quickshell.Io

pragma ComponentBehavior: Bound

Item {
    id: root
    
    property var layouts: ["US", "DE", "GR"]
    property int currentLayout: 0
    property string currentLayoutName: "US"
    property bool detailVisible: false
    
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
    
    Component.onCompleted: {
        root.refresh()
    }
    
    Process {
        id: layoutProcess
        
        command: ["bash", "-c", "setxkbmap -query | grep layout | awk '{print $2}'"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim()
                const layouts = output.split(",")
                root.currentLayoutName = layouts[0].toUpperCase()
                root.currentLayout = root.layouts.indexOf(root.currentLayoutName)
                if (root.currentLayout < 0) root.currentLayout = 0
            }
        }
    }
    
    Process {
        id: switchProcess
        
        command: []
        running: false
        
        onRunningChanged: {
            if (!running) {
                Qt.callLater(root.refresh)
            }
        }
    }
    
    function refresh() {
        if (layoutProcess.running) return
        layoutProcess.running = true
    }
    
    function toggle() {
        const next = (root.currentLayout + 1) % root.layouts.length
        root.setLayout(next)
    }
    
    function setLayout(index) {
        if (index < 0 || index >= root.layouts.length) return
        
        const layout = root.layouts[index].toLowerCase()
        const cmd = "setxkbmap -layout us,de,gr -variant ,, -option grp:alt_shift_toggle && setxkbmap -layout " + layout
        switchProcess.command = ["bash", "-c", cmd]
        switchProcess.running = true
        
        root.currentLayout = index
        root.currentLayoutName = root.layouts[index]
    }
    
    function next() {
        root.toggle()
    }
    
    function previous() {
        const prev = (root.currentLayout - 1 + root.layouts.length) % root.layouts.length
        root.setLayout(prev)
    }
    
    function close() {
        detailVisible = false
    }
    
    function open() {
        detailVisible = true
    }
}
