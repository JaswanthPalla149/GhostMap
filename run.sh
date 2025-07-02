#!/bin/bash

echo "🟡 [INFO] UAV System Build Launcher Starting..."
cd "$(dirname "$0")" || {
    echo "❌ [ERROR] Failed to change to Desktop directory"
    exit 1
}
echo "✅ [OK] Current directory: $(pwd)"

# === Set absolute paths ===
GPSVIEWER_EXE="./build/GPSViewer.exe"
PYTHON_SCRIPT="./Main.py"
PYTHON_INTERPRETER="/c/Users/Jaswanth/AppData/Local/Programs/Python/Python312/python.exe"

# === Check Python exists ===
if [[ ! -f "$PYTHON_INTERPRETER" ]]; then
    echo "❌ [ERROR] Python interpreter not found at: $PYTHON_INTERPRETER"
    exit 1
fi
echo "✅ [OK] Python interpreter found"

# === Check Python script exists ===
if [[ ! -f "$PYTHON_SCRIPT" ]]; then
    echo "❌ [ERROR] Main.py not found at: $PYTHON_SCRIPT"
    exit 1
fi
echo "✅ [OK] Main.py found"

# === Check GPSViewer.exe exists ===
if [[ ! -f "$GPSVIEWER_EXE" ]]; then
    echo "❌ [ERROR] GPSViewer.exe not found at: $GPSVIEWER_EXE"
    exit 1
fi
echo "✅ [OK] GPSViewer.exe found"

# === Launch GPSViewer ===
echo "🚀 [LAUNCH] Starting GPSViewer.exe..."
start "" "$GPSVIEWER_EXE"

# === Wait for server startup ===
sleep 2

# === Launch Main.py using Windows native Python ===
echo "🚀 [LAUNCH] Starting Main.py..."
"$PYTHON_INTERPRETER" "$PYTHON_SCRIPT"

echo "🎯 [DONE] GPSViewer and Main.py have been launched successfully."
