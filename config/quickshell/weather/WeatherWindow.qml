import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.core

pragma ComponentBehavior: Bound

PopupWindow {
    id: root
    
    required property var weatherModel
    required property var panelWindow
    
    color: Theme.barBackground
    width: 320
    height: 380
    
    visible: root.weatherModel.detailVisible
    
    onVisibleChanged: {
        if (visible && root.panelWindow) {
            // Position unter dem Panel, rechts ausgerichtet
            x = root.panelWindow.x + root.panelWindow.width - width - Theme.panelEdgeMargin
            y = root.panelWindow.y + root.panelWindow.height + 4
        }
    }
    
    Rectangle {
        anchors.fill: parent
        radius: Theme.pillRadius
        color: Theme.barBackground
        border.color: Theme.border
        border.width: Theme.pillBorderWidth
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.popupPadding
            spacing: Theme.popupSpacing
            
            // Header
            UiText {
                text: "Wetter in Karditsa"
                font.pixelSize: Theme.titleFontSize
                font.bold: true
                color: Theme.textStrong
            }
            
            // Aktuelle Temperatur und Icon
            RowLayout {
                spacing: Theme.spacingXl
                
                IconText {
                    text: root.weatherModel.weatherIcon
                    font.pixelSize: 48
                    color: Theme.accent
                }
                
                ColumnLayout {
                    spacing: Theme.spacingXs
                    
                    UiText {
                        text: root.weatherModel.temperature + "°C"
                        font.pixelSize: 32
                        font.bold: true
                        color: Theme.textStrong
                    }
                    
                    UiText {
                        text: root.weatherModel.description
                        font.pixelSize: Theme.bodyFontSize
                        color: Theme.text
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
                
                UiText {
                    text: "Gefühlt:"
                    color: Theme.textMuted
                    font.pixelSize: Theme.bodyFontSize
                }
                
                UiText {
                    text: root.weatherModel.feelsLike + "°C"
                    color: Theme.textStrong
                    font.pixelSize: Theme.bodyFontSize
                    font.bold: true
                }
                
                UiText {
                    text: "Luftfeuchtigkeit:"
                    color: Theme.textMuted
                    font.pixelSize: Theme.bodyFontSize
                }
                
                UiText {
                    text: root.weatherModel.humidity + "%"
                    color: Theme.textStrong
                    font.pixelSize: Theme.bodyFontSize
                    font.bold: true
                }
                
                UiText {
                    text: "Wind:"
                    color: Theme.textMuted
                    font.pixelSize: Theme.bodyFontSize
                }
                
                UiText {
                    text: root.weatherModel.windSpeed + " km/h"
                    color: Theme.textStrong
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
            
            // Aktualisieren Button - korrekte Implementierung mit Rectangle
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.controlHeight
                radius: Theme.controlRadius
                color: refreshMouse.containsMouse ? Theme.controlHoverFill : Theme.controlNormalFill
                border.color: refreshMouse.containsMouse ? Theme.controlHoverBorder : Theme.controlNormalBorder
                border.width: Theme.controlBorderWidth
                
                Text {
                    anchors.centerIn: parent
                    text: "Aktualisieren"
                    color: refreshMouse.containsMouse ? Theme.controlHoverText : Theme.controlNormalText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBodySmallSize
                    font.bold: true
                }
                
                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.weatherModel.refresh()
                    }
                }
            }
            
            // Letzte Aktualisierung
            UiText {
                Layout.alignment: Qt.AlignHCenter
                text: "Aktualisiert: " + Qt.formatDateTime(new Date(), "HH:mm")
                color: Theme.textMuted
                font.pixelSize: Theme.tinyFontSize
            }
        }
    }
}
