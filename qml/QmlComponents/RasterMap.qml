// qml/QmlComponents/RasterMap.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    property string imageSource: "file:///C:/Users/Jaswanth/Desktop/gps_qt_server/satellite_bangalore.png"
    property var gpsList: []
    
    // Map bounds - MUST match your GeoTIFF!
    property real mapMinLat: 12.892001120137328
    property real mapMaxLat: 12.928005596724839
    property real mapMinLon: 77.57168074040256
    property real mapMaxLon: 77.60837691975884
    
    function toMapX(lon) {
        return (lon - mapMinLon) / (mapMaxLon - mapMinLon) * image.paintedWidth
    }
    
    function toMapY(lat) {
        return (mapMaxLat - lat) / (mapMaxLat - mapMinLat) * image.paintedHeight
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: imageContainer.width
        contentHeight: imageContainer.height
        clip: true
        
        property real zoom: 1.0
        
        PinchArea {
            width: Math.max(flick.contentWidth, flick.width)
            height: Math.max(flick.contentHeight, flick.height)
            
            onPinchUpdated: {
                flick.zoom = Math.max(0.5, Math.min(5, flick.zoom * pinch.scale))
            }
        }

        Item {
            id: imageContainer
            width: image.paintedWidth * flick.zoom
            height: image.paintedHeight * flick.zoom

            Component.onCompleted: console.log("imageSource =", root.imageSource)
            Image {
                id: image
                source: root.imageSource
                fillMode: Image.PreserveAspectFit
                width: sourceSize.width
                height: sourceSize.height
                transform: Scale {
                    xScale: flick.zoom
                    yScale: flick.zoom
                }
            }
            
            // GPS Markers
            Repeater {
                model: root.gpsList
                delegate: Rectangle {
                    width: 15
                    height: 15
                    radius: 7.5
                    color: modelData.class_id.includes("vehicle") ? "blue" : "red"
                    border.color: "white"
                    border.width: 2
                    x: root.toMapX(modelData.lon) * flick.zoom - width/2
                    y: root.toMapY(modelData.lat) * flick.zoom - height/2
                    
                    // Tooltip with coordinates
                    ToolTip.text: `${modelData.class_id}\nLat: ${modelData.lat.toFixed(6)}\nLon: ${modelData.lon.toFixed(6)}`
                    ToolTip.visible: ma.containsMouse
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }
        }
    }
}
