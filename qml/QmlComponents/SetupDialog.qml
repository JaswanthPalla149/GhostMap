import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1

Popup {
    id: setupDialog
    modal: true
    focus: true
    width: 400
    height: 500
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
            text: "Map Setup"
            font.pixelSize: 20
            Layout.alignment: Qt.AlignHCenter
        }

        TextField {
            placeholderText: "Enter Latitude"
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            onTextChanged: {
                const value = parseFloat(text)
                console.log("Latitude input:", text, "Parsed:", value)
                if (!isNaN(value)) {
                    setupDialog.lat = value
                } else {
                    console.warn("Invalid latitude")
                }
            }
        }

        TextField {
            placeholderText: "Enter Longitude"
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            onTextChanged: {
                const value = parseFloat(text)
                console.log("Longitude input:", text, "Parsed:", value)
                if (!isNaN(value)) {
                    setupDialog.lon = value
                } else {
                    console.warn("Invalid longitude")
                }
            }
        }

        TextField {
            placeholderText: "Radius in meters"
            text: "2000"
            inputMethodHints: Qt.ImhDigitsOnly
            onTextChanged: {
                const value = parseInt(text)
                console.log("Radius input:", text, "Parsed:", value)
                if (!isNaN(value)) {
                    setupDialog.radius = value
                } else {
                    console.warn("Invalid radius")
                }
            }
        }

        Button {
            text: "Choose Satellite Image"
            onClicked: {
                console.log("Opening file dialog...")
                fileDialog.open()
            }
        }

        Label {
            text: imagePath !== "" ? "Selected: " + imagePath : "No image selected"
            wrapMode: Text.Wrap
            color: "#bbbbbb"
        }

        FileDialog {
            id: fileDialog
            title: "Select Satellite Image"
            folder: StandardPaths.pictures
            nameFilters: ["Images (*.png *.jpg *.jpeg)"]
            onAccepted: {
                // For Qt.labs.platform FileDialog, use 'file' property instead of 'fileUrl'
                var selectedFile = fileDialog.file
                console.log("FileDialog.file:", selectedFile)
                
                if (selectedFile && selectedFile !== "") {
                    setupDialog.imagePath = selectedFile
                    console.log("Image path set to:", selectedFile)
                } else {
                    console.warn("No valid file selected!")
                    setupDialog.imagePath = ""
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