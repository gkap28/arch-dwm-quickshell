import QtQuick
import qs.core

Item {
    id: root

    property var options: []
    property string value: ""
    property bool interactive: true
    signal selected(string newValue)

    implicitWidth: Math.max(buttonRect.implicitWidth, popupRect.implicitWidth)
    implicitHeight: buttonRect.height

    Rectangle {
        id: buttonRect
        anchors.left: parent.left
        anchors.top: parent.top
        height: 32
        width: Math.max(labelText.implicitWidth + 40, 120)
        color: Theme.surface
        border.color: root.interactive ? Theme.border : Theme.textMuted
        radius: Theme.radius

        Text {
            id: labelText
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.value || "—"
            color: root.interactive ? Theme.textStrong : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.smallFontSize
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "▼"
            color: root.interactive ? Theme.textMuted : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 9
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.interactive
            cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: popupRect.visible = !popupRect.visible
        }
    }

    Rectangle {
        id: popupRect
        visible: false
        anchors.left: parent.left
        anchors.top: buttonRect.bottom
        anchors.topMargin: 2
        width: Math.max(buttonRect.width, 160)
        height: Math.min(optionsList.contentHeight + 8, 240)
        color: Theme.surface
        border.color: Theme.accent
        radius: Theme.radius
        z: 100

        ListView {
            id: optionsList
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            model: root.options
            spacing: 2

            delegate: Rectangle {
                required property string modelData
                width: optionsList.width
                height: 28
                color: itemMouse.containsMouse ? Theme.surfaceHover : (modelData === root.value ? Theme.accent : "transparent")
                radius: Theme.radius

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData
                    color: modelData === root.value ? Theme.textStrong : Theme.textStrong
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.smallFontSize
                    font.bold: modelData === root.value
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        popupRect.visible = false;
                        root.selected(modelData);
                    }
                }
            }
        }
    }
}
