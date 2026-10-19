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

    property string selectedFont: ""
    property string selectedIcon: ""

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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        Text {
            Layout.fillWidth: true
            text: "Font / Text Size"
            color: Theme.textStrong
            font.family: Theme.fontFamily
            font.bold: true
            font.pixelSize: Theme.bodyFontSize
        }

        Text {
            Layout.fillWidth: true
            text: "Aktuell: " + (root.settingsModel.fontFamily || "(unbekannt)") + " / " + Math.round(root.settingsModel.fontScale * 100) + "%"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.smallFontSize
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.tightSpacing

            Text {
                text: "Text-Größe:"
                color: Theme.text
                font.family: Theme.fontFamily
            }

            Repeater {
                model: [0.80, 0.90, 1.00, 1.10, 1.25, 1.50]

                delegate: Rectangle {
                    id: scaleButton
                    required property real modelData

                    readonly property bool isActive: Math.abs(root.settingsModel.fontScale - scaleButton.modelData) < 0.01

                    width: 60
                    height: 30
                    color: isActive ? Theme.accent : Theme.surface
                    border.color: isActive ? Theme.accent : Theme.border
                    radius: Theme.radius

                    Text {
                        anchors.centerIn: parent
                        text: Math.round(scaleButton.modelData * 100) + "%"
                        color: Theme.textStrong
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.tinyFontSize
                        font.bold: scaleButton.isActive
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !scaleButton.isActive
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const family = root.settingsModel.fontFamily || "MesloLGS Nerd Font Mono";
                            root.settingsModel.applyFont(family, scaleButton.modelData);
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Font auswählen (Klick markiert, dann Apply Font drücken):"
            color: Theme.text
            font.family: Theme.fontFamily
        }

        Flow {
            Layout.fillWidth: true
            spacing: Theme.tightSpacing

            Repeater {
                model: root.settingsModel.fontCandidates

                delegate: Rectangle {
                    id: fontButton
                    required property var modelData

                    readonly property bool isActive: modelData.family === root.settingsModel.fontFamily
                    readonly property bool isSelected: modelData.family === root.selectedFont

                    width: Math.max(fontLabel.implicitWidth + 24, 140)
                    height: 36
                    color: isActive ? Theme.accent : (isSelected ? Theme.surfaceHover : Theme.surface)
                    border.color: isActive ? Theme.accent : (isSelected ? Theme.accentSecondary : Theme.border)
                    border.width: isSelected ? 2 : 1
                    radius: Theme.radius

                    Text {
                        id: fontLabel
                        anchors.centerIn: parent
                        text: fontButton.modelData.family
                        color: Theme.textStrong
                        font.family: fontButton.modelData.family
                        font.pixelSize: Theme.smallFontSize
                        font.bold: fontButton.isActive
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedFont = fontButton.modelData.family
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.tightSpacing

            ShellButton {
                label: "Apply Font"
                enabled: root.selectedFont.length > 0
                onActivated: {
                    root.settingsModel.applyFont(root.selectedFont, root.settingsModel.fontScale || 1.0);
                    root.selectedFont = "";
                }
            }

            ShellButton {
                label: "Follow System Font"
                onActivated: root.settingsModel.followSystemFont()
            }
            ShellButton {
                label: "Refresh"
                onActivated: root.settingsModel.refreshFont()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        Text {
            Layout.fillWidth: true
            text: "Icon-Theme (GTK)"
            color: Theme.textStrong
            font.family: Theme.fontFamily
            font.bold: true
            font.pixelSize: Theme.bodyFontSize
        }

        Text {
            Layout.fillWidth: true
            text: "Aktuell: " + (root.settingsModel.iconsCurrent || "(unbekannt)") + " / " + root.settingsModel.iconsMessage
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.smallFontSize
        }

        Flow {
            Layout.fillWidth: true
            spacing: Theme.tightSpacing

            Repeater {
                model: root.settingsModel.iconsThemes

                delegate: Rectangle {
                    id: iconButton
                    required property var modelData

                    readonly property bool isActive: modelData.active
                    readonly property bool isSelected: modelData.name === root.selectedIcon

                    width: Math.max(iconLabel.implicitWidth + 24, 140)
                    height: 34
                    color: isActive ? Theme.accent : (isSelected ? Theme.surfaceHover : Theme.surface)
                    border.color: isActive ? Theme.accent : (isSelected ? Theme.accentSecondary : Theme.border)
                    border.width: isSelected ? 2 : 1
                    radius: Theme.radius

                    Text {
                        id: iconLabel
                        anchors.centerIn: parent
                        text: iconButton.modelData.name
                        color: Theme.textStrong
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.smallFontSize
                        font.bold: iconButton.isActive
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !iconButton.isActive
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedIcon = iconButton.modelData.name;
                            root.settingsModel.setIconTheme(iconButton.modelData.name);
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            ShellButton {
                label: "Refresh"
                onActivated: root.settingsModel.refreshIcons()
            }
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
