import socket
import time

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.connect(('localhost', 8888))

time.sleep(60)