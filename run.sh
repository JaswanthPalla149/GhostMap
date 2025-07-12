#!/bin/bash

MODE=$1
echo "🟡 [INFO] UAV System Build Launcher Starting..."
VIDEO_STREAM=$2
# === Validate mode ===
if [[ "$MODE" != "nc-y" && "$MODE" != "c-o" ]]; then
    echo "❌ [ERROR] Invalid mode. Usage: ./run.sh nc-y  OR  ./run.sh c-o"
    exit 1
fi

# === Validate video flag ===
if [[ "$VIDEO_STREAM" != "show" && "$VIDEO_STREAM" != "no-show" ]]; then
    echo "❌ [ERROR] Invalid video stream option. Usage: ./run.sh nc-y show  OR  ./run.sh c-o no-show"
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
SIM_SCRIPT="./sim.py"
FLAG_PATH="./gps_ready.flag"
echo "No" > "$FLAG_PATH"

# === Check Python is available ===
if ! command -v python &>/dev/null && ! command -v py &>/dev/null; then
    echo "❌ [ERROR] No Python interpreter found in PATH (python or py)"
    exit 1
fi
echo "✅ [OK] Python is available in PATH"

# === Check required files ===
[[ ! -f "$PYTHON_SCRIPT" ]] && { echo "❌ [ERROR] Main.py not found at: $PYTHON_SCRIPT"; exit 1; }
[[ ! -f "$SIM_SCRIPT" ]] && { echo "❌ [ERROR] sim.py not found at: $SIM_SCRIPT"; exit 1; }
[[ ! -f "$GPSVIEWER_EXE" ]] && { echo "❌ [ERROR] GPSViewer.exe not found at: $GPSVIEWER_EXE"; exit 1; }
echo "✅ [OK] All required files found"

# === Launch GPSViewer ===
echo "🚀 [LAUNCH] Starting GPSViewer.exe..."
start "" "$GPSVIEWER_EXE"

# === Wait for gps_ready.flag ===
echo "⏳ [WAIT] Waiting for gps_ready.flag = 'ready'..."
while true; do
    if [[ -f "$FLAG_PATH" ]] && grep -q "ready" "$FLAG_PATH"; then
        echo "✅ [OK] gps_ready.flag detected"
        break
    fi
    sleep 1
done

# === Convert MODE to input format ===
if [[ "$MODE" == "nc-y" ]]; then
    FORMAT_ARG="--input_format nc-yolo"
    echo "🟨 [MODE] NO-confidence YOLO mode (class cx cy w h)"
else
    FORMAT_ARG="--input_format conf-xyxy"
    echo "🟩 [MODE] CONFIDENCE XYXY mode (class conf x1 y1 x2 y2)"
fi

# === Set Video flag ===
if [[ "$VIDEO_STREAM" == "show" ]]; then
    VIDEO_ARG="--video_stream true"
    echo "📽️ [VIDEO] Displaying UAV video stream"
else
    VIDEO_ARG="--video_stream false"
    echo "❎ [VIDEO] UAV video stream disabled"
fi

# === Launch Main.py in background ===
echo "🚀 [LAUNCH] Starting Main.py..."
if command -v python &>/dev/null; then
    python "$PYTHON_SCRIPT" $FORMAT_ARG $VIDEO_ARG &
    MAIN_PID=$!
else
    py "$PYTHON_SCRIPT" $FORMAT_ARG $VIDEO_ARG &
    MAIN_PID=$!
fi

# === Delay to let Main.py start receiver socket ===
sleep 2

# === Launch sim.py in background ===
echo "🚀 [LAUNCH] Starting sim.py..."
if command -v python &>/dev/null; then
    python "$SIM_SCRIPT" &
    SIM_PID=$!
else
    py "$SIM_SCRIPT" &
    SIM_PID=$!
fi

# === Wait for Main.py to exit ===
wait $MAIN_PID
echo "✅ Main.py finished."

# === Kill sim.py if it's still running ===
kill $SIM_PID 2>/dev/null

echo "🎯 [DONE] UAV pipeline completed."