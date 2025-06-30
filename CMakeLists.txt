cmake_minimum_required(VERSION 3.16)
project(GPSViewer)

# Find Qt6 components
find_package(Qt6 REQUIRED COMPONENTS Core Quick Qml)

# Set AUTOMOC globally
set(CMAKE_AUTOMOC ON)

# Create the main executable
qt_add_executable(GPSViewer main.cpp TcpServer.cpp)
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

# Add QML module for the main application
qt_add_qml_module(GPSViewer
    URI GPSViewer
    VERSION 1.0
    QML_FILES
        qml/Main.qml
    RESOURCE_PREFIX "/qml"
)

# Create the QML Components module as a separate target
qt_add_qml_module(QmlComponentsModule
    STATIC
    URI QmlComponents
    VERSION 1.0
    QML_FILES
        qml/QmlComponents/RasterMap.qml
    RESOURCE_PREFIX "/qml"
    #OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/QmlComponents
)

# Link dependencies - this is the key part!
target_link_libraries(GPSViewer PRIVATE Qt6::Core Qt6::Quick QmlComponentsModule)
