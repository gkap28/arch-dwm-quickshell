import QtQuick
import Quickshell
import Quickshell.Io

pragma ComponentBehavior: Bound

Item {
    id: root
    
    // Koordinaten für Karditsa, Griechenland
    property string location: "39.367024,21.923739"
    
    // Wetterdaten
    property string temperature: "--"
    property string condition: ""
    property string weatherIcon: "󰖐"
    property string humidity: ""
    property string windSpeed: ""
    property string feelsLike: ""
    property string description: ""
    property bool loading: false
    
    // Sichtbarkeit des Detail-Fensters
    property bool detailVisible: false
    
    // Timer für automatische Aktualisierung (alle 15 Minuten)
    Timer {
        interval: 900000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
    
    // Initial laden
    Component.onCompleted: {
        root.refresh()
    }
    
    function refresh() {
        if (root.loading) return
        root.loading = true
        
        const request = new XMLHttpRequest()
        const url = "https://wttr.in/" + root.location + "?format=j1"
        
        request.open("GET", url)
        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                root.loading = false
                
                if (request.status === 200) {
                    try {
                        const data = JSON.parse(request.responseText)
                        const current = data.current_condition[0]
                        
                        root.temperature = current.temp_C
                        root.condition = current.weatherDesc[0].value
                        root.humidity = current.humidity
                        root.windSpeed = current.windspeedKmph
                        root.feelsLike = current.FeelsLikeC
                        root.description = current.weatherDesc[0].value
                        
                        // Wetter-Icon basierend auf Bedingung
                        const desc = root.condition.toLowerCase()
                        if (desc.indexOf("sunny") >= 0 || desc.indexOf("clear") >= 0) {
                            root.weatherIcon = "󰖙"
                        } else if (desc.indexOf("cloud") >= 0) {
                            if (desc.indexOf("partly") >= 0) {
                                root.weatherIcon = "󰖕"
                            } else {
                                root.weatherIcon = "󰖐"
                            }
                        } else if (desc.indexOf("rain") >= 0 || desc.indexOf("drizzle") >= 0) {
                            root.weatherIcon = "󰖖"
                        } else if (desc.indexOf("snow") >= 0) {
                            root.weatherIcon = "󰼶"
                        } else if (desc.indexOf("thunder") >= 0) {
                            root.weatherIcon = "󰖓"
                        } else if (desc.indexOf("fog") >= 0 || desc.indexOf("mist") >= 0) {
                            root.weatherIcon = "󰖑"
                        } else {
                            root.weatherIcon = "󰖐"
                        }
                        
                        console.log("Wetter aktualisiert:", root.temperature + "°C", root.condition)
                    } catch (e) {
                        console.error("Fehler beim Parsen der Wetterdaten:", e)
                    }
                } else {
                    console.error("Wetter-API Fehler:", request.status)
                }
            }
        }
        
        request.onerror = function() {
            root.loading = false
            console.error("Netzwerkfehler beim Laden der Wetterdaten")
        }
        
        request.send()
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
