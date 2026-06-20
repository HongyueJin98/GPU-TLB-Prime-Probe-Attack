#!/usr/bin/python3

import socket
import time 
import pyautogui
import os
import sys
import subprocess
import signal

server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#server ip and port
host = '130.127.106.32'  
port = 12344  
server_socket.bind((host, port))
server_socket.listen(1)  
connection, address = server_socket.accept()

screenWidth, screenHeight = pyautogui.size()
while True:
  # Wait for the client to send a signal (website name) 
  name = connection.recv(1024)  # Receive data (max 1024 bytes)
  name = name.decode('utf-8')  # Decode received bytes into a string
  print(name)  # Print the received website name

  # Open a new tab in the browser using the 'Ctrl + T' hotkey
  pyautogui.hotkey('ctrl', 't')
  time.sleep(1)  # Wait 1 second to ensure the tab opens

  # Open the homepage "about:blank"
  pyautogui.click(x=113, y=54)  # Click on the browser's address bar
  time.sleep(1)  # Wait for the browser to respond

  # Click the search bar and type the website name
  pyautogui.moveTo(x=300, y=53)  # Move cursor to the search bar
  pyautogui.click(x=300, y=54)  # Click on the search bar
  time.sleep(1)  # Wait before typing
  pyautogui.write(name)  # Type the received website name

  # Wait for a signal when the kernel is ready
  name = connection.recv(1024)
  name = name.decode('utf-8')

  time.sleep(0.2)  # Short delay before proceeding
  pyautogui.press('enter')  # Press 'Enter' to visit the website

  # Move the mouse to a fixed location to avoid interference
  pyautogui.moveTo(x=1500, y=12)

  # Wait for a signal indicating that the Prime-Probe process has ended
  name = connection.recv(1024)

  # Close the browser tab by clicking the close button
  pyautogui.click(x=548, y=13)

connection.close()
server_socket.close()
os.kill(a_out.pid, signal.SIGTERM)

