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
            text: "Wallpaper (pro Monitor)"
            color: Theme.textStrong
            font.family: Theme.fontFamily
            font.bold: true
            font.pixelSize: Theme.bodyFontSize
        }

        Text {
            Layout.fillWidth: true
            text: root.settingsModel.wallpaperMessage
            color: root.settingsModel.wallpaperState === "failure" ? Theme.danger : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.smallFontSize
        }

        Repeater {
            model: root.settingsModel.wallpaperMonitors

            delegate: Rectangle {
                id: monitorCard
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: monitorCol.implicitHeight + 20
                color: Theme.bg
                border.color: Theme.border
                radius: Theme.radius

                ColumnLayout {
                    id: monitorCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: Theme.tightSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Monitor " + (monitorCard.modelData.index + 1) + ": " + monitorCard.modelData.name
                            color: Theme.textStrong
                            font.family: Theme.fontFamily
                            font.bold: true
                        }
                        Text {
                            text: monitorCard.modelData.basename || "(kein Bild)"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.smallFontSize
                            elide: Text.ElideRight
                            Layout.maximumWidth: 300
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Theme.tightSpacing

                        Repeater {
                            model: root.settingsModel.wallpaperCandidates

                            delegate: Rectangle {
                                id: wpButton
                                required property var modelData

                                readonly property bool isActive: modelData.basename === monitorCard.modelData.basename

                                width: Math.max(wpLabel.implicitWidth + 20, 120)
                                height: 30
                                color: isActive ? Theme.accent : Theme.surface
                                border.color: isActive ? Theme.accent : Theme.border
                                radius: Theme.radius

                                Text {
                                    id: wpLabel
                                    anchors.centerIn: parent
                                    text: wpButton.modelData.basename
                                    color: Theme.textStrong
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.tinyFontSize
                                    font.bold: wpButton.isActive
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !wpButton.isActive
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.settingsModel.setWallpaper(monitorCard.modelData.index, wpButton.modelData.path)
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.tightSpacing

            Text {
                text: "Fit-Modus:"
                color: Theme.text
                font.family: Theme.fontFamily
            }

            Repeater {
                model: ["scale", "fill", "fit", "center", "tile", "max"]

                delegate: Rectangle {
                    id: fitButton
                    required property string modelData

                    readonly property bool isActive: root.settingsModel.wallpaperFit === modelData

                    width: 70
                    height: 30
                    color: isActive ? Theme.accent : Theme.surface
                    border.color: isActive ? Theme.accent : Theme.border
                    radius: Theme.radius

                    Text {
                        anchors.centerIn: parent
                        text: fitButton.modelData
                        color: Theme.textStrong
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.tinyFontSize
                        font.bold: fitButton.isActive
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !fitButton.isActive
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.settingsModel.setWallpaperFit(fitButton.modelData)
                    }
                }
            }

            Item { Layout.fillWidth: true }

            ShellButton {
                label: "Zufällig"
                onActivated: root.settingsModel.randomizeWallpaper()
            }
            ShellButton {
                label: "Reset"
                onActivated: root.settingsModel.resetWallpaper()
            }
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
