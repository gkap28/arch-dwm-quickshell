import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    required property string label
    required property bool selected
    required property bool occupied
    signal clicked()

    Layout.preferredWidth: Theme.workspaceButtonSize
    Layout.preferredHeight: Theme.workspaceButtonSize
    radius: Theme.smallRadius
    color: Theme.transparent
    border.color: selected ? Theme.accent : Theme.transparent
    border.width: selected ? Theme.pillBorderWidth : 0

    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.selected ? Theme.accent : (root.occupied ? Theme.text : Theme.textMuted)
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelFontSize
        font.bold: root.selected
        verticalAlignment: Text.AlignVCenter
    }

    // Belegt-Indikator (nur für nicht-ausgewählte Workspaces)
    Rectangle {
        visible: root.occupied && !root.selected
        width: 6
        height: 6
        radius: 1
        color: Theme.accent
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0
    }

    MouseArea {
        id: workspaceMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
