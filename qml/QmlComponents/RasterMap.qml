// qml/QmlComponents/RasterMap.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    //property string imageSource: "file:///C:/Users/Jaswanth/Desktop/gps_qt_server/satellite_bangalore.png"
    property string imageSource: ""
    property var gpsList: []

    // Geo bounds - must match the satellite image
    //property real mapMinLat: 12.892001120137328
    //property real mapMaxLat: 12.928005596724839
    //property real mapMinLon: 77.57168074040256
    //property real mapMaxLon: 77.60837691975884
    property real mapMinLat: 0
    property real mapMaxLat: 0
    property real mapMinLon: 0
    property real mapMaxLon: 0
    // Zoom settings
    property real minZoom: 0.5
    property real maxZoom: 10.0
    property real zoomStep: 0.1
   
    // Current zoom level
    property real currentZoom: 1.0

    // Coordinate conversion functions
    function toMapX(lon) {
        return (lon - mapMinLon) / (mapMaxLon - mapMinLon) * mapContent.width
    }

    function toMapY(lat) {
        return (mapMaxLat - lat) / (mapMaxLat - mapMinLat) * mapContent.height
    }

    // Zoom functions
    function zoomIn() {
        setZoom(currentZoom * (1 + zoomStep))
    }
   
    function zoomOut() {
        setZoom(currentZoom * (1 - zoomStep))
    }
   
    function setZoom(newZoom) {
        var oldZoom = currentZoom
        currentZoom = Math.max(minZoom, Math.min(maxZoom, newZoom))
       
        // Calculate center point before zoom
        var centerX = flickable.contentX + flickable.width / 2
        var centerY = flickable.contentY + flickable.height / 2
       
        // Calculate new content position to maintain center
        var newCenterX = centerX * (currentZoom / oldZoom)
        var newCenterY = centerY * (currentZoom / oldZoom)
       
        // Set new content position
        flickable.contentX = newCenterX - flickable.width / 2
        flickable.contentY = newCenterY - flickable.height / 2
    }
   
    function resetZoom() {
        currentZoom = 1.0
        flickable.contentX = 0
        flickable.contentY = 0
    }

    // Main flickable container
    Flickable {
        id: flickable
        anchors.fill: parent
       
        // Content size based on zoom
        contentWidth: Math.max(image.sourceSize.width * currentZoom, width)
        contentHeight: Math.max(image.sourceSize.height * currentZoom, height)
       
        // Smooth scrolling
        flickDeceleration: 1500
        maximumFlickVelocity: 2500
       
        // Boundary behavior
        boundsBehavior: Flickable.StopAtBounds
       
        // Enable interactions
        interactive: true
        clip: true

        // Pinch-to-zoom area
        PinchArea {
            id: pinchArea
            anchors.fill: parent
           
            property real initialZoom: 1.0
            property point initialCenter
           
            onPinchStarted: {
                initialZoom = currentZoom
                initialCenter = Qt.point(flickable.contentX + pinch.center.x,
                                       flickable.contentY + pinch.center.y)
            }
           
            onPinchUpdated: {
                // Calculate new zoom
                var newZoom = initialZoom * pinch.scale
                newZoom = Math.max(minZoom, Math.min(maxZoom, newZoom))
               
                // Calculate zoom factor
                var zoomFactor = newZoom / currentZoom
                currentZoom = newZoom
               
                // Adjust content position to zoom around pinch center
                flickable.contentX = initialCenter.x * zoomFactor - pinch.center.x
                flickable.contentY = initialCenter.y * zoomFactor - pinch.center.y
            }
           
            onPinchFinished: {
                // Ensure content stays within bounds
                flickable.returnToBounds()
            }

            // Mouse area for wheel zoom and panning
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
               
                property point lastPan
                property bool isPanning: false
               
                // Mouse wheel zoom
                onWheel: {
                    var zoomPoint = Qt.point(wheel.x, wheel.y)
                    var oldZoom = currentZoom
                   
                    // Zoom in/out based on wheel direction
                    if (wheel.angleDelta.y > 0) {
                        setZoom(currentZoom * 1.15)
                    } else {
                        setZoom(currentZoom / 1.15)
                    }
                   
                    // Zoom around mouse cursor
                    var zoomFactor = currentZoom / oldZoom
                    var contentPoint = Qt.point(flickable.contentX + zoomPoint.x,
                                              flickable.contentY + zoomPoint.y)
                   
                    flickable.contentX = contentPoint.x * zoomFactor - zoomPoint.x
                    flickable.contentY = contentPoint.y * zoomFactor - zoomPoint.y
                   
                    // Ensure content stays within bounds
                    flickable.returnToBounds()
                }
               
                // Mouse panning (optional - flickable handles touch panning)
                onPressed: {
                    if (mouse.button === Qt.LeftButton) {
                        lastPan = Qt.point(mouse.x, mouse.y)
                        isPanning = true
                    }
                }
               
                onPositionChanged: {
                    if (isPanning && mouse.buttons & Qt.LeftButton) {
                        var dx = mouse.x - lastPan.x
                        var dy = mouse.y - lastPan.y
                       
                        flickable.contentX -= dx
                        flickable.contentY -= dy
                       
                        lastPan = Qt.point(mouse.x, mouse.y)
                    }
                }
               
                onReleased: {
                    if (mouse.button === Qt.LeftButton) {
                        isPanning = false
                        flickable.returnToBounds()
                    }
                }
            }
        }

        // Map content container
        Item {
            id: mapContent
            width: (image.status === Image.Ready ? image.sourceSize.width : 500) * currentZoom
            height: (image.status === Image.Ready ? image.sourceSize.height : 500) * currentZoom



        Rectangle {
            anchors.fill: parent
            color: "black"  // fallback background

            Image {
                id: image
                anchors.fill: parent
                source: root.imageSource.startsWith("file://") ? root.imageSource : "file://" + root.imageSource
                fillMode: Image.Stretch
                smooth: currentZoom < 2.0
                asynchronous: true
                cache: true

                Rectangle {
                    anchors.centerIn: parent
                    width: 100
                    height: 50
                    color: "white"
                    border.color: "gray"
                    radius: 5
                    visible: image.status === Image.Loading

                    Text {
                        anchors.centerIn: parent
                        text: "Loading..."
                        color: "gray"
                    }
                }
            }
        }


            // GPS points overlay
            Repeater {
                id: gpsRepeater
                model: root.gpsList
               
                delegate: Item {
                    id: gpsPoint
                   
                    // Position based on coordinates
                    x: root.toMapX(modelData.lon) * currentZoom
                    y: root.toMapY(modelData.lat) * currentZoom

                   
                    // GPS marker
                    Rectangle {
                        id: marker
                        width: Math.max(8, 12 / currentZoom) // Scale inversely with zoom
                        height: width
                        radius: width / 2
                       
                        // Center the marker on the coordinate
                        anchors.centerIn: parent
                       
                        // Use color from GPS data, with fallback to default colors
                        color: {
                            // Primary: Use color from class map if available
                            if (modelData.color && modelData.color !== "") {
                                return modelData.color
                            }
                            // Fallback: Use class_id based colors (legacy support)
                            else if (modelData.class_id) {
                                switch(modelData.class_id) {
                                    case "armed_vehicle": return "#3498db"
                                    case "person": return "#1abc9c"
                                    case "soldier": return "#e74c3c"
                                    case "vehicle": return "#9b59b6"
                                    default: return "#95a5a6" // Gray for unknown
                                }
                            }
                            // Final fallback: Default red
                            else {
                                return "#e74c3c"
                            }
                        }
                       
                        border.color: "white"
                        border.width: Math.max(1, 2 / currentZoom)
                       
                        // Add shadow for better visibility
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 2
                            height: parent.height + 2
                            radius: parent.radius + 1
                            color: "black"
                            opacity: 0.3
                            z: -1
                        }
                       
                        // Hover effect (optional)
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                           
                            onEntered: {
                                marker.scale = 1.2
                                // Show tooltip with class info
                                tooltip.visible = true
                            }
                           
                            onExited: {
                                marker.scale = 1.0
                                tooltip.visible = false
                            }
                           
                            // Show detailed info on click
                            onClicked: {
                                console.log("GPS Point Details:")
                                console.log("- Class:", modelData.class_id)
                                console.log("- Color:", modelData.color)
                                console.log("- Coordinates:", modelData.lat, modelData.lon)
                                console.log("- Timestamp:", modelData.timestamp)
                            }
                        }
                       
                        // Smooth scaling animation
                        Behavior on scale {
                            NumberAnimation { duration: 150 }
                        }
                    }
                   
                    // Tooltip for showing class information
                    Rectangle {
                        id: tooltip
                        visible: false
                        x: marker.x + marker.width + 5
                        y: marker.y - height/2
                        width: tooltipText.width + 10
                        height: tooltipText.height + 6
                        color: "black"
                        opacity: 0.8
                        radius: 3
                        z: 1000
                       
                        Text {
                            id: tooltipText
                            anchors.centerIn: parent
                            text: modelData.class_id || "Unknown"
                            color: "white"
                            font.pixelSize: Math.max(8, 10 / currentZoom)
                        }
                       
                        // Arrow pointing to marker
                        Rectangle {
                            width: 6
                            height: 6
                            x: -3
                            y: parent.height/2 - 3
                            rotation: 45
                            color: parent.color
                            opacity: parent.opacity
                        }
                    }
                }
            }
        }
    }

    // Zoom controls overlay
    Column {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 5
       
        Button {
            text: "+"
            width: 40
            height: 40
            onClicked: root.zoomIn()
        }
       
        Button {
            text: "−"
            width: 40
            height: 40
            onClicked: root.zoomOut()
        }
       
        Button {
            text: "⌂"
            width: 40
            height: 40
            onClicked: root.resetZoom()
        }
    }

    // Zoom level indicator
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 10
        width: zoomText.width + 20
        height: zoomText.height + 10
        color: "black"
        opacity: 0.7
        radius: 5
       
        Text {
            id: zoomText
            anchors.centerIn: parent
            text: "Zoom: " + (currentZoom * 100).toFixed(0) + "%"
            color: "white"
            font.pixelSize: 12
        }
    }
   
    // Legend for class colors (optional)
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        width: legendColumn.width + 20
        height: legendColumn.height + 20
        color: "black"
        opacity: 0.8
        radius: 5
        visible: root.gpsList.length > 0
       
        Column {
            id: legendColumn
            anchors.centerIn: parent
            spacing: 5
           
            Text {
                text: "Legend"
                color: "white"
                font.pixelSize: 10
                font.bold: true
            }
           
            // Generate legend based on unique classes in gpsList
            Repeater {
                model: {
                    var uniqueClasses = {}
                    for (var i = 0; i < root.gpsList.length; i++) {
                        var item = root.gpsList[i]
                        if (item.class_id && !uniqueClasses[item.class_id]) {
                            uniqueClasses[item.class_id] = item.color || "#95a5a6"
                        }
                    }
                   
                    var result = []
                    for (var className in uniqueClasses) {
                        result.push({
                            name: className,
                            color: uniqueClasses[className]
                        })
                    }
                    return result
                }
               
                delegate: Row {
                    spacing: 5
                   
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: modelData.color
                        border.color: "white"
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter
                    }
                   
                    Text {
                        text: modelData.name
                        color: "white"
                        font.pixelSize: 8
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}