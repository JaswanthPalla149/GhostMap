import socket

try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect(('localhost', 12345))
    print("Connected successfully!")
    
    sock.close()
    print("Connection closed successfully!")
except Exception as e:
    print(f"Connection failed: {e}")