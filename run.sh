#!/bin/bash

MODE=$1
echo "🟡 [INFO] UAV System Build Launcher Starting..."

# === Validate mode ===
if [[ "$MODE" != "nc-y" && "$MODE" != "c-o" ]]; then
    echo "❌ [ERROR] Invalid mode. Usage: ./run.sh nc-y  OR  ./run.sh c-o"
    exit 1
fi

cd "$(dirname "$0")" || {
    echo "❌ [ERROR] Failed to change to script directory"
    exit 1
}
echo "✅ [OK] Current directory: $(pwd)"

# === Set absolute paths ===
GPSVIEWER_EXE="./build/GPSViewer_App.exe"
PYTHON_SCRIPT="./Main.py"
FLAG_PATH="./gps_ready.flag"

# === Check Python is available ===
if ! command -v python &>/dev/null && ! command -v py &>/dev/null; then
    echo "❌ [ERROR] No Python interpreter found in PATH (python or py)"
    exit 1
fi
echo "✅ [OK] Python is available in PATH"

# === Check Main.py exists ===
if [[ ! -f "$PYTHON_SCRIPT" ]]; then
    echo "❌ [ERROR] Main.py not found at: $PYTHON_SCRIPT"
    exit 1
fi
echo "✅ [OK] Main.py found"

# === Check GPSViewer ===
if [[ ! -f "$GPSVIEWER_EXE" ]]; then
    echo "❌ [ERROR] GPSViewer.exe not found at: $GPSVIEWER_EXE"
    exit 1
fi
echo "✅ [OK] GPSViewer.exe found"



# === Launch GPSViewer ===
echo "🚀 [LAUNCH] Starting GPSViewer.exe..."
start "" "$GPSVIEWER_EXE"

# === Wait until gps_ready.flag contains "ready" ===
echo "⏳ [WAIT] Waiting for GPSViewer to write 'ready' into gps_ready.flag..."
while true; do
    if [[ -f "$FLAG_PATH" ]] && grep -q "ready" "$FLAG_PATH"; then
        echo "✅ [OK] gps_ready.flag detected with 'ready'"
        break
    fi
    sleep 1
done

# === Convert mode to format ===
if [[ "$MODE" == "nc-y" ]]; then
    FORMAT_ARG="--input_format nc-yolo"
    echo "🟨 [MODE] NO-confidence YOLO mode (class cx cy w h)"
else
    FORMAT_ARG="--input_format conf-xyxy"
    echo "🟩 [MODE] CONFIDENCE XYXY mode (class conf x1 y1 x2 y2)"
fi

# === Launch Main.py with default python ===
echo "🚀 [LAUNCH] Starting Main.py..."
if command -v python &>/dev/null; then
    python "$PYTHON_SCRIPT" $FORMAT_ARG
else
    py "$PYTHON_SCRIPT" $FORMAT_ARG
fi

echo "🎯 [DONE] UAV pipeline completed."
