import pyautogui
import time

print("Move your mouse to the desired position. Press Ctrl+C to stop.")

try:
    while True:
        x, y = pyautogui.position()  # Get current mouse position
        print(f"Position: x={x}, y={y}", end='\r')  # Overwrite the same line
        time.sleep(0.1)  # Update every 0.1 seconds
except KeyboardInterrupt:
    print("\nPosition tracking stopped.")
