# GhostMap
A modular UAV-based detection and visualization system that processes aerial image frames, projects detected objects to GPS coordinates, and displays them on a real-time satellite map GUI.

This framework integrates:
- YOLO-based detection outputs
- UAV telemetry metadata (pitch, yaw, FOV, etc.)
- Geospatial projection logic
- A real-time Qt/QML GUI over TCP

## 📂 Project Structure

Main.py
- To process the data from frames, calls the PDTG.cpp using pybind. Sends this data to TCP server at localhost: 12345
- To setup any different processing algorithm change PDTG.cpp and run setup.py

main.cpp
- starts Qml Gui, Qml engine, Tcp server, Required components Main.qml/RasterMap.qml
- TcpServer.cpp/TcpServer.h/Main.qml-> All will be initialised by main.cpp
- Loading the processed satellite tile is done by RasterMap.qml

CMakeLists.txt and build files
- CMake written for this architecture adding QmlComponents as plugin
- should be run in msys mingw64 terminal 

## ⚙️ Setup Instructions

### 🛠️ 1.🧰 Common Requirementss
    CMake (build system)
    
    Git (version control)
    
    Python 3.x with pip
    
    System package manager (pacman for Windows/MSYS2, apt for Linux)

### 🪟 Windows: MSYS2 (MINGW64)
- ✅ **MSYS2 (MINGW64 shell)**  
  Install [MSYS2](https://www.msys2.org) and launch the **MINGW64 terminal**.
  Verify you're in the correct environment: $ echo $MSYSTEM
 **Output should be: MINGW64**

- ✅ **Qt 6 (Quick + QML modules)**  
  Install via MSYS2:

  ```
  pacman -Syu
  pacman -S mingw-w64-x86_64-qt6-base mingw-w64-x86_64-qt6-declarative mingw-w64-x86_64-cmake
  ```

- ✅ **Python**
    Install from [Python-org](https://www.python.org)
    ```
    pacman -S \
    mingw-w64-x86_64-gcc \
    mingw-w64-x86_64-cmake \
    mingw-w64-x86_64-make \
    mingw-w64-x86_64-python \
    mingw-w64-x86_64-python-pip
    
    pacman -S \
    mingw-w64-x86_64-python-pybind11 \
    mingw-w64-x86_64-python-setuptools \
    mingw-w64-x86_64-opencv
    ```
    **Verify Installation**
    ```
    which gcc        # Should output: /mingw64/bin/gcc
    which python     # Should output: /mingw64/bin/python
    which cmake      # Should output: /mingw64/bin/cmake
    pacman -Q | grep qt6  # All packages should start with mingw-w64-x86_64-qt6-
    ```
### 🐧 Linux: Native GCC Toolchain
#### Installaion
```
# Update package manager
sudo apt update

# Install build essentials
sudo apt install build-essential cmake make

# Install Qt6 development packages
sudo apt install \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-tools-dev \
    qt6-tools-dev-tools

# Install Python development packages
sudo apt install python3-dev python3-pip

# Install Python packages via apt (preferred)
sudo apt install \
    python3-pybind11 \
    python3-setuptools \
    python3-opencv
```

  **verify Installation**
  ```
    which gcc         # Should output: /usr/bin/gcc
    which python3     # Should output: /usr/bin/python3
    which cmake       # Should output: /usr/bin/cmake
    pkg-config --modversion Qt6Core  # Should output Qt6 version number
```

## 🛠️ Build
 ### After cloning Repo
If you have pulled the repo for the first time/ want to rebuild the .pyd/.so file:
> Make sure to have your own classmap.txt file which can tell this framework to configure the classnames and colors to be displayed. 
  ```
  python setup.py build_ext --inplace
  ```
### 🪟 Windows: MSYS2 (MINGW64)
  Run this in mingw-w64 environment in the repo folder
  ```
  mkdir build
  cd build
  cmake .. -G "MinGW Makefiles"
  mingw32-make
  ```
  If you want to run in VSCODE:
  > You can either:
  ```
  In configure the kit to :  "GCC x.x.x C:/msys64/mingw64/bin/gcc.exe"
  ```
  > Or:
  Have a **CMakePresets.json** file like:
  **Windows**
  ```
  {
  "version": 3,
  "cmakeMinimumRequired": {
    "major": 3,
    "minor": 16
  },
  "configurePresets": [
    {
      "name": "mingw64",
      "displayName": "MSYS2 MinGW64",
      "generator": "MinGW Makefiles",
      "binaryDir": "${sourceDir}/build",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_C_COMPILER": "C:/msys64/mingw64/bin/gcc.exe",
        "CMAKE_CXX_COMPILER": "C:/msys64/mingw64/bin/g++.exe",
        "CMAKE_PREFIX_PATH": "C:/msys64/mingw64"
      },
      "environment": {
        "PATH": "C:/msys64/mingw64/bin;C:/msys64/usr/bin;C:/Windows/System32;C:/Windows",
        "QT_PLUGIN_PATH": "C:/msys64/mingw64/lib/qt6/plugins"
      }
    }
  ]
}
```
### 🐧 Linux: Native GCC Toolchain

```
mkdir build && cd build
cmake ..
make -j$(nproc)
```
 If you want to run in VSCODE:
  > You can either:
  ```
  In configure the kit to :  "GCC x.x.x C:/msys64/mingw64/bin/gcc.exe"
  ```
  > Or:
  Have a **CMakePresets.json** file like:
  **Linux**
  ```
  {
  "version": 3,
  "cmakeMinimumRequired": {
    "major": 3,
    "minor": 16
  },
  "configurePresets": [
    {
      "name": "linux-gcc",
      "displayName": "Linux GCC",
      "generator": "Unix Makefiles",
      "binaryDir": "${sourceDir}/build",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_C_COMPILER": "/usr/bin/gcc",
        "CMAKE_CXX_COMPILER": "/usr/bin/g++",
        "CMAKE_PREFIX_PATH": "/usr/lib/x86_64-linux-gnu/cmake"
      },
      "environment": {
        "PATH": "/usr/bin:/bin:/usr/local/bin",
        "QT_PLUGIN_PATH": "/usr/lib/x86_64-linux-gnu/qt6/plugins"
      }
    }
  ]
}
```
  

Finally to run:
You can run this from bash(VScode)/Msys2 Mingw64/ terminal
```
./run.sh
```