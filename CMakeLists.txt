cmake_minimum_required(VERSION 3.16)
project(GPSViewer)

# Enable AUTOMOC for Qt meta-object compilation
set(CMAKE_AUTOMOC ON)

# Use PYTHON_INTERPRETER environment variable if provided
if(DEFINED ENV{PYTHON_INTERPRETER})
    set(Python3_EXECUTABLE $ENV{PYTHON_INTERPRETER})
endif()

# Find Python 3.8+ interpreter
find_package(Python3 REQUIRED COMPONENTS Interpreter)
message(STATUS "✅ Found Python interpreter: ${Python3_EXECUTABLE}")

# Find Qt components
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

# Find pybind11
find_package(pybind11 REQUIRED)

# === Main Executable ===
qt_add_executable(GPSViewer
    main.cpp
    TcpServer.cpp
    ReadyFlagWriter.cpp
)

# === QML module for main UI ===
qt_add_qml_module(GPSViewer
    URI GPSViewer
    VERSION 1.0
    QML_FILES
        qml/Main.qml
    RESOURCE_PREFIX "/qml"
)

# === Shared QML Components (included directly, not as plugin) ===
qt_add_qml_module(QmlComponentsModule
    #STATIC
    URI QmlComponents
    VERSION 1.0
    QML_FILES
        qml/QmlComponents/RasterMap.qml
        qml/QmlComponents/SetupDialog.qml
    RESOURCE_PREFIX "/qml"
    OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/QmlComponents
)

# === Link dependencies ===
target_link_libraries(GPSViewer
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Quick
        Qt6::Qml
        QmlComponentsModule
)

# === Set output location and binary name ===
set_target_properties(GPSViewer PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    OUTPUT_NAME "GPSViewer_App"
)