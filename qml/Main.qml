import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QmlComponents 1.0
Window {
    visible: true
    width: 1200
    height: 800
    title: qsTr("UAV Tracking System")

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

            // Map + List Container
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 20

                // Map View - Takes 70% width
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.width * 0.7
                    color: "#1a1a1a"
                    radius: 10
                    border.color: "#333"
                    border.width: 1

                    RasterMap {
                        id: mapDisplay
                        anchors.fill: parent
                        anchors.margins: 5
                        gpsList: tcpServer.gpsList
                        imageSource: "C:/Users/Jaswanth/Desktop/gps_qt_server/satellite_bangalore.png"
                    }
                }

                // GPS List View - Takes 30% width
                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.width * 0.3
                    spacing: 10

                    Text {
                        text: "Live Detections"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#1a1a1a"
                        radius: 10
                        border.color: "#333"
                        border.width: 1

                        // GPS List View
                        ListView {
                            id: gpsListView
                            anchors.fill: parent
                            anchors.margins: 5
                            model: tcpServer.gpsList
                            spacing: 8
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Rectangle {
                                width: parent.width
                                height: 60
                                color: modelData.class_id.includes("vehicle") ? "#1a3a5c" : "#3a1a1a"
                                radius: 6
                                border.color: "#444"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10

                                    Rectangle {
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: modelData.class_id.includes("vehicle") ? "blue" : "red"
                                        border.color: "white"
                                        border.width: 1
                                    }

                                    ColumnLayout {
                                        spacing: 4
                                        Text {
                                            text: modelData.class_id
                                            color: "white"
                                            font.pixelSize: 16
                                            font.bold: true
                                        }
                                        Text {
                                            text: "📍 Lat: " + modelData.lat.toFixed(6) + ", Lon: " + modelData.lon.toFixed(6)
                                            color: "#ddd"
                                            font.pixelSize: 12
                                        }
                                    }

                                    Text {
                                        text: "⌛ " + Qt.formatDateTime(new Date(), "hh:mm:ss")
                                        color: "#aaa"
                                        font.pixelSize: 12
                                    }
                                }
                            }

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AlwaysOn
                                width: 6
                            }
                        }

                        // Empty state
                        Text {
                            visible: tcpServer.gpsList.length === 0
                            anchors.centerIn: parent
                            text: "Waiting for GPS data..."
                            color: "#888"
                            font.pixelSize: 16
                        }
                    }

                    // Status Bar
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        color: "#1a1a1a"
                        radius: 8

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
        }
    }

    // Count objects by type
    property int soldierCount: {
        let count = 0;
        for (let i = 0; i < tcpServer.gpsList.length; i++) {
            if (tcpServer.gpsList[i].class_id.includes("soldier")) count++;
        }
        return count;
    }
    
    property int vehicleCount: {
        let count = 0;
        for (let i = 0; i < tcpServer.gpsList.length; i++) {
            if (tcpServer.gpsList[i].class_id.includes("vehicle")) count++;
        }
        return count;
    }
}
