import os
import json
import cv2
import projector
import socket
import time
import argparse
from datetime import datetime

# === Parse arguments ===
parser = argparse.ArgumentParser()
parser.add_argument('--input_format', choices=['nc-yolo', 'conf-xyxy'], required=True,
                    help='Input format: nc-yolo (class cx cy w h) or conf-xyxy (class conf x1 y1 x2 y2)')
args = parser.parse_args()

flag_path = "gps_ready.flag"
print("⏳ Waiting for GPSViewer to set lat, long, and image...")

while not os.path.exists(flag_path):
    time.sleep(0.5)

print("✅ Setup complete. Proceeding...")

# === Load Metadata ===
script_dir = os.path.dirname(os.path.abspath(__file__))
config_path = os.path.join(script_dir, "classmap.txt")
projector.loadClassMap(config_path)

meta_path = os.path.join(script_dir, 'meta.json')
with open(meta_path, 'r') as f:
    meta_data = json.load(f)

meta = projector.UAVMeta()
meta.lat = meta_data['latitude']
meta.lon = meta_data['longitude']
meta.alt = meta_data['altitude']
meta.pitch_deg = meta_data['pitch']
meta.yaw_deg = meta_data['yaw']
meta.fov_deg = meta_data['fov_h_deg']
meta.img_w = meta_data['image_width']
meta.img_h = meta_data['image_height']

# === Frame Files ===
folder_path = os.path.join(script_dir, "test")
frame_files = sorted([f for f in os.listdir(folder_path) if f.startswith("frame") and f.endswith(".txt")],
                     key=lambda x: int(x.replace("frame", "").replace(".txt", "")))

# === TCP Client Setup ===
tcp_ip = "127.0.0.1"
tcp_port = 12345

def connect_to_server():
    while True:
        try:
            client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            client.connect((tcp_ip, tcp_port))
            print(f"Connected to TCP server at {tcp_ip}:{tcp_port}")
            return client
        except Exception as e:
            print("Failed to connect to TCP server, retrying in 2 seconds...", e)
            time.sleep(2)

client = connect_to_server()

# Optional: Resize OpenCV window
cv2.namedWindow("UAV Stream", cv2.WINDOW_NORMAL)
cv2.resizeWindow("UAV Stream", 640, 640)
cv2.moveWindow("UAV Stream", 600, 100)

# === Main Loop ===
for txt_file in frame_files:
    frame_index = txt_file.replace(".txt", "")
    image_path = os.path.join(folder_path, f"{frame_index}.jpg")
    txt_path = os.path.join(folder_path, txt_file)

    if not os.path.exists(image_path):
        print(f"Image not found for {frame_index}, skipping...")
        continue

    # === Load Detections Based on Input Format ===
    detections = []
    with open(txt_path, 'r') as f:
        for line in f:
            tokens = line.strip().split()
            if args.input_format == 'nc-yolo':
                if len(tokens) != 5:
                    continue
                class_id = int(tokens[0])
                cx, cy, w, h = map(float, tokens[1:])
            elif args.input_format == 'conf-xyxy':
                if len(tokens) != 6:
                    continue
                class_id = int(tokens[0])
                x1, y1, x2, y2 = map(float, tokens[2:])
                cx = (x1 + x2) / 2
                cy = (y1 + y2) / 2
                w = x2 - x1
                h = y2 - y1
            else:
                continue

            d = projector.Detection()
            d.class_id = class_id
            d.x, d.y, d.w, d.h = cx, cy, w, h
            detections.append(d)

    # === Project to GPS ===
    gps_coords = projector.projectDetectionsToGPS(detections, meta)

    # === Prepare JSON for TCP ===
    json_data = [{
        "class_id": g.class_id,
        "color": g.color,
        "lat": g.lat,
        "lon": g.lon,
        "timestamp": datetime.now().isoformat()
    } for g in gps_coords]

    print(f"\n== GPS for {frame_index} ==")
    for item in json_data:
        print(f"{item['class_id']}: {item['lat']:.6f}, {item['lon']:.6f}")

    # === Send over TCP ===
    try:
        message = json.dumps(json_data, separators=(',', ':'))
        client.sendall(message.encode('utf-8'))
        print(f"Sent {len(json_data)} objects to server")
    except Exception as e:
        print("Connection error, reconnecting...", e)
        client.close()
        client = connect_to_server()
        continue

    # === Visualize Frame ===
    frame = cv2.imread(image_path)
    if frame is not None:
        for g, d in zip(gps_coords, detections):
            abs_cx = d.x * meta.img_w
            abs_cy = d.y * meta.img_h
            abs_w = d.w * meta.img_w
            abs_h = d.h * meta.img_h

            x = int(abs_cx - abs_w / 2)
            y = int(abs_cy - abs_h / 2)
            w = int(abs_w)
            h = int(abs_h)

            # Convert hex color to BGR
            hex_color = g.color.lstrip("#")
            color_bgr = tuple(int(hex_color[i:i+2], 16) for i in (4, 2, 0))

            # Draw box and label
            cv2.rectangle(frame, (x, y), (x + w, y + h), color_bgr, 2)
            cv2.putText(frame, str(g.class_id), (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color_bgr, 1)

        cv2.imshow("UAV Stream", frame)
        key = cv2.waitKey(500)
        if key == 27:  # ESC
            break

client.close()
cv2.destroyAllWindows()
