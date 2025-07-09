import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QmlComponents 1.0

Window {
    visible: true
    width: 500
    height: 600
    x: 100
    y: 100
    title: qsTr("UAV Tracking System")

    Component.onCompleted: setupPrompt.open()

    SetupDialog {
        id: setupPrompt

        onAccepted: (lat, lon, radius, path) => {
            console.log("Received from SetupDialog:", "Lat:", lat, "Lon:", lon, "Radius:", radius, "Path:", path)
            if (isNaN(lat) || isNaN(lon) || isNaN(radius)) {
                console.error("Invalid input(s):", lat, lon, radius)
                return
            }
            const deltaLat = radius / 111320
            const deltaLon = radius / (111320 * Math.cos(lat * Math.PI / 180))
            console.log("This message will appear in the console.")
            mapDisplay.mapMinLat = lat - deltaLat
            mapDisplay.mapMaxLat = lat + deltaLat
            mapDisplay.mapMinLon = lon - deltaLon
            mapDisplay.mapMaxLon = lon + deltaLon
            console.log("Final geo bounds:")
            console.log("mapMinLat:", mapDisplay.mapMinLat)
            console.log("mapMaxLat:", mapDisplay.mapMaxLat)
            console.log("mapMinLon:", mapDisplay.mapMinLon)
            console.log("mapMaxLon:", mapDisplay.mapMaxLon)
            if (path && path !== "") {
                console.log("Setting imageSource to:", path)
                mapDisplay.imageSource = path.toString()
            } else {
                console.warn("No image selected. Skipping image update.")
            }
            FlagWriter.setReady()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#121212"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Header
            Text {
                text: "📡 Live UAV Tracking System"
                color: "white"
                font.pixelSize: 24
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
            }

            // Full-width Map View
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#1a1a1a"
                radius: 10
                border.color: "#333"
                border.width: 1

                RasterMap {
                    id: mapDisplay
                    anchors.fill: parent
                    anchors.margins: 5
                    gpsList: tcpServer.gpsList
                    imageSource: ""
                }
            }

            // Optional: Minimal Status
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: "#1a1a1a"
                radius: 8
                visible: tcpServer.gpsList.length > 0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 15

                    Text {
                        text: "Objects: " + tcpServer.gpsList.length
                        color: "white"
                        font.bold: true
                    }

                    Text {
                        text: "Soldiers: " + soldierCount
                        color: "red"
                        font.bold: true
                    }

                    Text {
                        text: "Vehicles: " + vehicleCount
                        color: "blue"
                        font.bold: true
                    }
                }
            }
        }
    }

    // Count logic
    property int soldierCount: {
        let count = 0
        for (let i = 0; i < tcpServer.gpsList.length; i++) {
            if (tcpServer.gpsList[i].class_id.includes("soldier")) count++
        }
        return count
    }

    property int vehicleCount: {
        let count = 0
        for (let i = 0; i < tcpServer.gpsList.length; i++) {
            if (tcpServer.gpsList[i].class_id.includes("vehicle")) count++
        }
        return count
    }
}
