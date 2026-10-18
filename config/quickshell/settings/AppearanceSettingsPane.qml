import QtQuick
import QtQuick.Layouts
import qs.core

pragma ComponentBehavior: Bound

Flickable {
    id: root

    required property var settingsModel
    contentWidth: width
    contentHeight: contentColumn.implicitHeight
    clip: true

    ColumnLayout {
        id: contentColumn
        width: root.width
        spacing: Theme.sectionSpacing

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.settingsModel.appearanceMessage || "Themes und Fensterrahmen"
                color: root.settingsModel.appearanceState === "failure" ? Theme.danger : Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
            }
            ShellButton {
                label: "Refresh"
                enabled: root.settingsModel.appearanceState !== "loading"
                onActivated: root.settingsModel.refreshAppearance()
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Theme"
            color: Theme.textStrong
            font.family: Theme.fontFamily
            font.bold: true
            font.pixelSize: Theme.bodyFontSize
        }

        Flow {
            Layout.fillWidth: true
            spacing: Theme.tightSpacing

            Repeater {
                model: root.settingsModel.appearanceThemes

                delegate: Rectangle {
                    id: themeButton
                    required property var modelData

                    readonly property bool isActive: modelData.active

                    width: Math.max(themeLabel.implicitWidth + 24, 100)
                    height: 34
                    color: isActive ? Theme.accent : Theme.surface
                    border.color: isActive ? Theme.accent : Theme.border
                    radius: Theme.radius

                    Text {
                        id: themeLabel
                        anchors.centerIn: parent
                        text: themeButton.modelData.name
                        color: Theme.textStrong
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.smallFontSize
                        font.bold: themeButton.isActive
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !themeButton.isActive
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.settingsModel.setTheme(themeButton.modelData.name)
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.settingsModel.appearanceThemes.length === 0
            text: root.settingsModel.appearanceState === "loading"
                ? "Discovering themes..."
                : "No themes found"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        Text {
            Layout.fillWidth: true
            text: "Fensterrahmen (borderpx)"
            color: Theme.textStrong
            font.family: Theme.fontFamily
            font.bold: true
            font.pixelSize: Theme.bodyFontSize
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.tightSpacing

            Repeater {
                model: [0, 1, 2, 3]

                delegate: Rectangle {
                    id: borderButton
                    required property int modelData

                    readonly property bool isActive: root.settingsModel.appearanceBorderpx === modelData

                    width: 60
                    height: 34
                    color: isActive ? Theme.accent : Theme.surface
                    border.color: isActive ? Theme.accent : Theme.border
                    radius: Theme.radius

                    Text {
                        anchors.centerIn: parent
                        text: borderButton.modelData === 0 ? "aus" : borderButton.modelData.toString()
                        color: Theme.textStrong
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.smallFontSize
                        font.bold: borderButton.isActive
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !borderButton.isActive
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.settingsModel.setBorderpx(borderButton.modelData)
                    }
                }
            }
        }
    }
}
