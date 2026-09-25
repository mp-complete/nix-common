"""Tiny TCP forwarder. Runs on Windows; bridges 0.0.0.0:LISTEN -> 127.0.0.1:TARGET.

Used to expose Edge's CDP endpoint (which only binds to 127.0.0.1 due to
Chromium's DNS-rebinding mitigation) to WSL Playwright clients.

Stdlib only. Spawned by bootstrap.sh via powershell.exe Start-Process.
"""
import socket
import sys
import threading

LISTEN_HOST = "0.0.0.0"
LISTEN_PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 9223
TARGET_HOST = "127.0.0.1"
TARGET_PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 9222


def pipe(src, dst):
    try:
        while True:
            data = src.recv(65536)
            if not data:
                break
            dst.sendall(data)
    except OSError:
        pass
    finally:
        try:
            dst.shutdown(socket.SHUT_WR)
        except OSError:
            pass


def handle(client):
    try:
        server = socket.create_connection((TARGET_HOST, TARGET_PORT))
    except OSError as e:
        print(f"Failed to connect to {TARGET_HOST}:{TARGET_PORT}: {e}", flush=True)
        client.close()
        return
    threading.Thread(target=pipe, args=(client, server), daemon=True).start()
    threading.Thread(target=pipe, args=(server, client), daemon=True).start()


def main():
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind((LISTEN_HOST, LISTEN_PORT))
    listener.listen(64)
    print(f"Forwarding {LISTEN_HOST}:{LISTEN_PORT} -> {TARGET_HOST}:{TARGET_PORT}", flush=True)
    while True:
        client, _ = listener.accept()
        threading.Thread(target=handle, args=(client,), daemon=True).start()


if __name__ == "__main__":
    main()
