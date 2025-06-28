cmake_minimum_required(VERSION 3.16)
project(GPSViewer)

# 1. Find Qt6 components
find_package(Qt6 REQUIRED COMPONENTS Core Quick)

# 2. Set AUTOMOC globally (critical)
set(CMAKE_AUTOMOC ON)

# 3. Create executable FIRST
add_executable(GPSViewer main.cpp TcpServer.cpp TcpServer.h)

# 4. Add QML module with minimal configuration
qt_add_qml_module(GPSViewer
    URI GPSViewer
    VERSION 1.0
    RESOURCE_PREFIX "/qml"  # 💡 this maps to qrc:/qml/
    OUTPUT_DIRECTORY "${QT_QML_OUTPUT_DIRECTORY}/GPSViewer"
    QML_FILES
        qml/Main.qml
)

# 5. Link dependencies
target_link_libraries(GPSViewer PRIVATE Qt6::Core Qt6::Quick)
