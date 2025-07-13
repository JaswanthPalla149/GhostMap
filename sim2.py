import socket
import json
import time
import os

# === Setup ===
folder_path = "test"
IMAGE_WIDTH = 640
IMAGE_HEIGHT = 640

frame_files = sorted(
    [f for f in os.listdir(folder_path) if f.endswith(".txt")],
    key=lambda x: int(''.join(filter(str.isdigit, x)))
)

client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client.connect(("127.0.0.1", 9999))
print("📡 Connected to receiver")

for txt_file in frame_files:
    frame_index = txt_file.replace(".txt", "")
    txt_path = os.path.join(folder_path, txt_file)

    detections = []
    with open(txt_path, 'r') as f:
        for line in f:
            tokens = line.strip().split()
            if len(tokens) != 5:
                continue
            class_id = int(tokens[0])
            cx, cy, w, h = map(float, tokens[1:])
            detections.append({
                "class_id": class_id,
                "conf": 1.0,
                "bbox": [cx, cy, w, h]
            })

    header = {
        "meta": {
            "latitude": 12.91,
            "longitude": 77.59,
            "altitude": 100.0,
            "pitch": 0.0,
            "yaw": 0.0,
            "fov_h_deg": 90.0,
            "image_width": IMAGE_WIDTH,
            "image_height": IMAGE_HEIGHT
        },
        "detections": detections,
        "image_size": 0  # No image
    }

    header_json = json.dumps(header, separators=(',', ':'))
    header_bytes = header_json.encode('utf-8')
    if len(header_bytes) > 1024:
        raise ValueError("Header too long to fit in 1024 bytes")

    header_bytes_padded = header_bytes.ljust(1024, b' ')
    client.sendall(header_bytes_padded)

    print(f"✅ Packet (no image) sent for: {frame_index}")
    time.sleep(0.190)

client.close()
print("📴 Disconnected.")
