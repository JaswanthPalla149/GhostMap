// main.qml
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

Window {
    visible: true
    width: 640
    height: 480
    title: qsTr("GPS Viewer")

    Rectangle {
        width: parent.width
        height: parent.height
        color: "black"

        Text {
            anchors.centerIn: parent
            text: "Waiting for GPS data..."
            color: "white"
        }
    }
}