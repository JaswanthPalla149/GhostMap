import os
import json
import cv2
import projector
import socket
import time
import argparse
import numpy as np
from datetime import datetime

# === Parse args ===
parser = argparse.ArgumentParser()
parser.add_argument('--input_format', choices=['nc-yolo', 'conf-xyxy'], required=True)
args = parser.parse_args()

# === Wait for gps_ready.flag ===
flag_path = "gps_ready.flag"
print("⏳ Waiting for GPSViewer to set lat, long, and image...")
while not os.path.exists(flag_path):
    time.sleep(0.5)
print("✅ Setup complete. Proceeding...")

# === Load classmap ===
script_dir = os.path.dirname(os.path.abspath(__file__))
config_path = os.path.join(script_dir, "classmap.txt")
projector.loadClassMap(config_path)

# === Connect to GhostMap TCP ===
tcp_ip = "127.0.0.1"
tcp_port = 12345
def connect_to_ghostmap():
    while True:
        try:
            client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            client.connect((tcp_ip, tcp_port))
            print(f"✅ Connected to GhostMap at {tcp_ip}:{tcp_port}")
            return client
        except Exception as e:
            print("Retrying GhostMap connection...", e)
            time.sleep(2)

ghostmap_client = connect_to_ghostmap()

# === TCP Server to receive from drone/sim ===
recv_server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
recv_server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
recv_server.bind(('0.0.0.0', 9999))
recv_server.listen(1)
recv_server.settimeout(1.0)  # 1 second timeout
print("🚦 Waiting for drone/sim on port 9999...")

# === Setup OpenCV window ===
cv2.namedWindow("UAV Stream", cv2.WINDOW_NORMAL)
cv2.resizeWindow("UAV Stream", 640, 640)
cv2.moveWindow("UAV Stream", 600, 100)

# === Helper to receive fixed bytes ===
def receive_all(sock, size):
    data = b''
    while len(data) < size:
        try:
            chunk = sock.recv(size - len(data))
        except socket.timeout:
            continue  # Allow GUI to remain responsive
        if not chunk:
            raise ConnectionError("Socket closed unexpectedly")
        data += chunk
    return data

packet_index = 0

try:
    while True:
        try:
            # Accept connection with timeout, so we can check GUI status
            try:
                conn, addr = recv_server.accept()
                conn.settimeout(1.0)  # Set timeout for client socket
                print(f"🛰️ Drone/sim connected from {addr}")
            except socket.timeout:
                # No connection, check window status
                if cv2.getWindowProperty("UAV Stream", cv2.WND_PROP_VISIBLE) < 1:
                    print("🛑 UAV window closed.")
                    break
                key = cv2.waitKey(50)
                if key == 27:
                    print("🛑 ESC pressed. Exiting.")
                    break
                continue

            while True:
                try:
                    # === Receive 1024-byte header ===
                    header_bytes = receive_all(conn, 1024)
                    header = json.loads(header_bytes.decode().strip())
                    img_size = header['image_size']
                    meta_data = header['meta']
                    detections_raw = header['detections']

                    # === Receive image ===
                    img_bytes = receive_all(conn, img_size)
                    frame = cv2.imdecode(np.frombuffer(img_bytes, np.uint8), cv2.IMREAD_COLOR)

                    # === Setup UAV meta ===
                    meta = projector.UAVMeta()
                    meta.lat = meta_data['latitude']
                    meta.lon = meta_data['longitude']
                    meta.alt = meta_data['altitude']
                    meta.pitch_deg = meta_data['pitch']
                    meta.yaw_deg = meta_data['yaw']
                    meta.fov_deg = meta_data['fov_h_deg']
                    meta.img_w = meta_data['image_width']
                    meta.img_h = meta_data['image_height']

                    # === Parse detections ===
                    detections = []
                    for d in detections_raw:
                        if args.input_format == 'nc-yolo':
                            cx, cy, w, h = d['bbox']
                        elif args.input_format == 'conf-xyxy':
                            x1, y1, x2, y2 = d['bbox']
                            cx = (x1 + x2) / 2
                            cy = (y1 + y2) / 2
                            w = x2 - x1
                            h = y2 - y1
                        else:
                            continue
                        det = projector.Detection()
                        det.class_id = d['class_id']
                        det.x = cx
                        det.y = cy
                        det.w = w
                        det.h = h
                        detections.append(det)

                    # === Project to GPS ===
                    gps_coords = projector.projectDetectionsToGPS(detections, meta)

                    # === Send to GhostMap ===
                    json_data = [{
                        "class_id": g.class_id,
                        "color": g.color,
                        "lat": g.lat,
                        "lon": g.lon,
                        "timestamp": datetime.now().isoformat()
                    } for g in gps_coords]

                    print(f"\n== GPS for Packet {packet_index} ==")
                    for item in json_data:
                        print(f"{item['class_id']}: {item['lat']:.6f}, {item['lon']:.6f}")

                    try:
                        message = json.dumps(json_data, separators=(',', ':'))
                        ghostmap_client.sendall(message.encode('utf-8'))
                        print(f"📤 Sent {len(json_data)} objects to GhostMap")
                    except Exception as e:
                        print("🔌 GhostMap reconnecting...", e)
                        ghostmap_client.close()
                        ghostmap_client = connect_to_ghostmap()

                    # === Draw detections on frame ===
                    for g, d in zip(gps_coords, detections):
                        abs_cx = d.x * meta.img_w
                        abs_cy = d.y * meta.img_h
                        abs_w = d.w * meta.img_w
                        abs_h = d.h * meta.img_h

                        x = int(abs_cx - abs_w / 2)
                        y = int(abs_cy - abs_h / 2)
                        w = int(abs_w)
                        h = int(abs_h)

                        hex_color = g.color.lstrip("#")
                        color_bgr = tuple(int(hex_color[i:i+2], 16) for i in (4, 2, 0))

                        cv2.rectangle(frame, (x, y), (x + w, y + h), color_bgr, 2)
                        cv2.putText(frame, str(g.class_id), (x, y - 10),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, color_bgr, 1)

                    cv2.imshow("UAV Stream", frame)
                    if cv2.getWindowProperty("UAV Stream", cv2.WND_PROP_VISIBLE) < 1:
                        print("🛑 UAV window closed.")
                        raise KeyboardInterrupt
                    key = cv2.waitKey(150)
                    if key == 27:
                        raise KeyboardInterrupt

                    packet_index += 1

                except (ConnectionError, ConnectionResetError) as e:
                    print(f"⚠️ Drone/sim disconnected: {e}")
                    conn.close()
                    break
                except socket.timeout:
                    # No data received, but keep GUI responsive
                    if cv2.getWindowProperty("UAV Stream", cv2.WND_PROP_VISIBLE) < 1:
                        print("🛑 UAV window closed.")
                        raise KeyboardInterrupt
                    key = cv2.waitKey(50)
                    if key == 27:
                        raise KeyboardInterrupt
                except KeyboardInterrupt:
                    # Propagate to outer loop for shutdown
                    raise

        except KeyboardInterrupt:
            print("🛑 Keyboard interrupt. Shutting down...")
            break
        except Exception as e:
            print(f"🔥 Unexpected error: {e}")
finally:
    recv_server.close()
    ghostmap_client.close()
    cv2.destroyAllWindows()
