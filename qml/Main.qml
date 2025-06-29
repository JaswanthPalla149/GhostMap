import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Window {
    visible: true
    width: 640
    height: 480
    title: qsTr("GPS Viewer")

    Rectangle {
        anchors.fill: parent
        color: "#121212"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Text {
                text: "📡 Live GPS Coordinates"
                color: "white"
                font.pixelSize: 22
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }

            // ✅ Show ListView only when data exists
            ListView {
                id: gpsListView
                visible: tcpServer.gpsList.length > 0
                model: tcpServer.gpsList
                spacing: 8
                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true

                delegate: Rectangle {
                    width: parent.width
                    height: 60
                    color: "#1e1e1e"
                    radius: 8
                    border.color: "#444"
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        Text {
                            text: "🚗 " + modelData.class_id
                            color: "lightblue"
                            font.pixelSize: 16
                        }

                        Text {
                            text: "📍 Lat: " + modelData.lat + ", Lon: " + modelData.lon
                            color: "#ddd"
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            // ✅ Show this message only when no data
            Text {
                visible: tcpServer.gpsList.length === 0
                text: "Waiting for GPS data..."
                color: "#888"
                font.pixelSize: 16
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
