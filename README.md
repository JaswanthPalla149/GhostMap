# GhostMap
A modular UAV-based detection and visualization system that processes aerial image frames, projects detected objects to GPS coordinates, and displays them on a real-time satellite map GUI.

This framework integrates:
- YOLO-based detection outputs
- UAV telemetry metadata (pitch, yaw, FOV, etc.)
- Geospatial projection logic
- A real-time Qt/QML GUI over TCP

## 📂 Project Structure

**Main.py**  
- Processes incoming aerial data  
- Uses pybind to call `PDTG.cpp` for geospatial projection  
- Sends the results to TCP server at `localhost:12345`  

**main.cpp**  
- Initializes QML GUI and TCP Server  
- Loads GUI components (`Main.qml`, `RasterMap.qml`)  
- `TcpServer.cpp`, `Main.qml` handle map rendering and projection overlay  

**CMakeLists.txt / build**  
- Modular build using CMake  
- All QML components are added as Qt6 plugins  
- Should be built using `msys2/mingw64` or native Linux toolchains  

## 🔄 Data Transmission Format (API Endpoint)

GhostMap framework receives incoming data over **TCP** for real-time processing and geospatial projection.

### ✅ TCP Input Configuration

| Property        | Value                    |
|----------------|--------------------------|
| **Protocol**    | TCP                      |
| **Destination IP** | `127.0.0.1` (localhost) |
| **Port**        | `9999`                   |
| **Data Sent**   | 1024-byte padded JSON header + optional JPEG image |

---

### 📦 Header JSON Format

```json
{
  "meta": {
    "latitude": 12.91,
    "longitude": 77.59,
    "altitude": 100.0,
    "pitch": 0.0,
    "yaw": 0.0,
    "fov_h_deg": 90.0,
    "image_width": 640,
    "image_height": 640
  },
  "detections": [
    {
      "class_id": 0,
      "conf": 1.0,
      "bbox": [0.5, 0.5, 0.2, 0.2]
    }
  ],
  "image_size": 12345
}
```

## ⚙️ Setup Instructions

### 🛠️ 1.🧰 Common Requirementss
    CMake (build system)
    
    Git (version control)
    
    Python 3.x with pip
    
    System package manager (pacman for Windows/MSYS2, apt for Linux)

### 🪟 Windows: MSYS2 (MINGW64)
#### Installaion
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
### 🐧 Linux: Native GCC Toolchain/ 🍓 Raspberry Pi (ARM64)
#### Installaion
```
# Update package manager
sudo apt update

# Install build essentials
sudo apt install build-essential cmake make

# Install Qt6 development packages

sudo apt update
sudo apt install \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-tools-dev \
    qt6-tools-dev-tools

sudo apt install \
    qml6-module-qtquick \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qtquick-window \
    qml6-module-qtquick-templates \
    qml6-module-qt-labs-platform \
    qml6-module-qtqml-workerscript

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
> Make sure to have your own classmap.txt file which can tell this framework to configure the classnames and colors to be displayed according to the  Class_labels of the model run. 
> Make sure you change the .pyd/.so file to your requirements and setup. 
  ```
  python setup.py build_ext --inplace
  ```
### 🪟 Windows: MSYS2 (MINGW64)
  Run this in mingw-w64 environment in the repo folder
  ```
  mkdir build && cd build
  cmake .. -G "MinGW Makefiles"
  mingw32-make
  ```
  If you want to run in VSCODE:
  > You can either:
  ```
  In configure the kit to :  "GCC x.x.x C:/msys64/mingw64/bin/gcc.exe"
  ```
  > Or:
  Have a **CMakePresets.json** file
### 🐧 Linux: Native GCC Toolchain : 
```
# Using CMake presets (recommended)
cmake --preset linux-release
cmake --build --preset linux-release

# Or for debug build
cmake --preset linux-debug
cmake --build --preset linux-debug
```
> You can do manually also
```
mkdir build && cd build
cmake ..
make -j$(nproc)
```

### 🍓 Raspberry Pi (ARM64)
> If you want to do it Manually:
>Better to run Manually :Because Raspberry Pi’s environment doesn’t always have QML paths correctly registered in Qt’s runtime environment, unlike Windows/MSYS2
```
cmake .. -DMAKE_PREFIX_PATH=/usr/lib/aarch64-linux-gnu/cmake
make -j$(nproc)
QML_IMPORT_PATH=/usr/lib/aarch64-linux-gnu/qt6/qml QT_QPA_PLATFORM=xcb ./GPSViewer_App
```
>If you want to do it with our CMakePresets.json:
```
cmake --preset pi-release
cmake --build --preset pi-release
QML_IMPORT_PATH=/usr/lib/aarch64-linux-gnu/qt6/qml QT_QPA_PLATFORM=xcb ./GPSViewer_App
```
 If you want to run in VSCODE:
  > You can either:
  ```
  In configure the kit to :  "GCC x.x.x → /usr/bin/gcc"
  ```
  > Or:
  Have a **CMakePresets.json** file 

## Finally to run:
You can run this from bash(VScode)/Msys2 Mingw64/ terminal
```
./run.sh  nc-y show
./run.sh nc-y no-show
./run.sh c-o show
./run.sh c-o no-show
```
> [nc-y->no confidence yolo, c-o->confidence others]
>[show->you get the vedio stream even , no-show->you wont get the vedio stream]
>Edge-Devices


## Setting satellite image:
> * We will use the image to be dsiplayed on the RasterMap, this is the processed Satellite image with the coordinates of the centre of the image can be setup by you. 
>* Not necessary to have a satellite image, you can render these projections on empty map also.
> * Make sure when you set the centre of the RasterMap, you set it according to real GPS coordinates of the Satellite image 
> * Make sure whenever you get the satellite image, you will get a circular tile with 2000m radius.
