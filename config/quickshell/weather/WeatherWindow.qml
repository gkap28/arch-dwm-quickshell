import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

pragma ComponentBehavior: Bound

ClickAwayPopup {
    id: root

    required property var weatherModel
    required property var panelWindow

    readonly property int cardWidth: 320
    readonly property int cardHeight: 380
    readonly property int edgeMargin: Theme.rowSpacing

    visible: panelWindow !== null && panelWindow.screen !== null
        && weatherModel.detailVisible
    grabFocus: true
    targetWindow: panelWindow
    popupWidth: cardWidth
    popupHeight: cardHeight
    popupX: panelWindow ? Math.max(edgeMargin, panelWindow.width - cardWidth - edgeMargin) : edgeMargin
    popupY: Theme.panelHeight
    onDismissed: weatherModel.close()

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(function() {
                content.forceActiveFocus();
            });
        }
    }

    ShellSurface {
        id: content

        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.weatherModel.close();
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.popupPadding
            spacing: Theme.popupSpacing

            // Header
            Text {
                Layout.fillWidth: true
                text: "Wetter in Karditsa"
                color: Theme.textStrong
                font.family: Theme.fontFamily
                font.pixelSize: Theme.titleFontSize
                font.bold: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            // Aktuelle Temperatur und Icon
            RowLayout {
                spacing: Theme.spacingXl

                Text {
                    text: root.weatherModel.weatherIcon
                    color: Theme.accent
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 48
                }

                ColumnLayout {
                    spacing: Theme.spacingXs

                    Text {
                        text: root.weatherModel.temperature + "°C"
                        color: Theme.textStrong
                        font.family: Theme.fontFamily
                        font.pixelSize: 32
                        font.bold: true
                    }

                    Text {
                        text: root.weatherModel.description
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodyFontSize
                    }
                }
            }

            // Trennlinie
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.border
            }

            // Details
            GridLayout {
                columns: 2
                rowSpacing: Theme.rowSpacing
                columnSpacing: Theme.spacingXl

                Text {
                    text: "Gefühlt:"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodyFontSize
                }

                Text {
                    text: root.weatherModel.feelsLike + "°C"
                    color: Theme.textStrong
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodyFontSize
                    font.bold: true
                }

                Text {
                    text: "Luftfeuchtigkeit:"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodyFontSize
                }

                Text {
                    text: root.weatherModel.humidity + "%"
                    color: Theme.textStrong
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodyFontSize
                    font.bold: true
                }

                Text {
                    text: "Wind:"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodyFontSize
                }

                Text {
                    text: root.weatherModel.windSpeed + " km/h"
                    color: Theme.textStrong
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodyFontSize
                    font.bold: true
                }
            }

            // Trennlinie
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.border
            }

            // Aktualisieren Button
            ShellButton {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeight
                label: "Aktualisieren"
                onActivated: root.weatherModel.refresh()
            }

            // Letzte Aktualisierung
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Aktualisiert: " + Qt.formatDateTime(new Date(), "HH:mm")
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.tinyFontSize
            }
        }
    }
}
