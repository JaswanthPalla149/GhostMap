//SetupDialog.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1

Popup {
    id: setupDialog
    modal: true
    focus: true
    width: 400
    height: 550
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property real lat: 0
    property real lon: 0
    property int radius: 2000
    property url imagePath: ""

    signal accepted(real lat, real lon, int radius, url imagePath)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Label {
            text: "🗺️ Map Setup"
            font.pixelSize: 20
            Layout.alignment: Qt.AlignHCenter
        }

        TextField {
            placeholderText: "Enter Latitude"
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            onTextChanged: {
                const value = parseFloat(text)
                if (!isNaN(value)) {
                    setupDialog.lat = value
                    console.log("Latitude input:", text, "Parsed:", value)
                } else {
                    console.warn("Invalid latitude input:", text)
                }
            }
        }

        TextField {
            placeholderText: "Enter Longitude"
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            onTextChanged: {
                const value = parseFloat(text)
                if (!isNaN(value)) {
                    setupDialog.lon = value
                    console.log("Longitude input:", text, "Parsed:", value)
                } else {
                    console.warn("Invalid longitude input:", text)
                }
            }
        }

        TextField {
            placeholderText: "Radius in meters"
            text: "2000"
            inputMethodHints: Qt.ImhDigitsOnly
            onTextChanged: {
                const value = parseInt(text)
                if (!isNaN(value)) {
                    setupDialog.radius = value
                    console.log("Radius input:", text, "Parsed:", value)
                } else {
                    console.warn("Invalid radius input:", text)
                }
            }
        }

        TextField {
            id: manualPath
            placeholderText: "Enter image path manually (e.g. /home/pi/map.jpg)"
            text: setupDialog.imagePath
            onTextChanged: {
                setupDialog.imagePath = text
                console.log("Manual image path set to:", text)
            }
        }

        Button {
            text: "Choose Satellite Image (if supported)"
            onClicked: {
                console.log("Opening file dialog...")
                try {
                    fileDialog.open()
                } catch (e) {
                    console.warn("FileDialog not supported:", e)
                }
            }
        }

        Label {
            text: setupDialog.imagePath !== "" ? "Selected: " + setupDialog.imagePath : "No image selected"
            wrapMode: Text.Wrap
            color: "#bbbbbb"
        }

        FileDialog {
            id: fileDialog
            title: "Select Satellite Image"
            folder: StandardPaths.pictures
            nameFilters: ["Images (*.png *.jpg *.jpeg)"]
            onAccepted: {
                var selectedFile = fileDialog.file
                if (selectedFile && selectedFile !== "") {
                    setupDialog.imagePath = selectedFile
                    manualPath.text = selectedFile
                    console.log("Image path set via dialog:", selectedFile)
                } else {
                    console.warn("No valid file selected.")
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10

            Button {
                text: "Cancel"
                onClicked: {
                    setupDialog.close()
                    Qt.quit()
                }
            }

            Button {
                text: "OK"
                onClicked: {
                    console.log("Accepting with:", lat, lon, radius, imagePath)
                    setupDialog.close()
                    accepted(lat, lon, radius, imagePath)
                }
            }
        }
    }
}