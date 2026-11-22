import serial
import pyautogui
import time

# ==========================================
# CONFIGURATION
# ==========================================
# 1. Change this to match your Arduino's COM port! (e.g., 'COM3', 'COM4')
COM_PORT = 'COM8'  
BAUD_RATE = 115200

# 2. Map joystick outputs to keyboard keys
# You can change these to 'w', 'a', 's', 'd' or 'space' depending on the game!
key_map = {
    "UP": "up",
    "DOWN": "down",
    "LEFT": "left",
    "RIGHT": "right",
    "CLICK": "enter",
    "CENTER": None
}
# ==========================================

try:
    ser = serial.Serial(COM_PORT, BAUD_RATE, timeout=0.1)
    print(f"Successfully connected to Arduino on {COM_PORT}!")
    print("Move the joystick to play! Press Ctrl+C in this terminal to stop.")
except Exception as e:
    print(f"Error connecting to Arduino: {e}")
    print(f"Please check that {COM_PORT} is correct in the script.")
    exit()

current_key = None

while True:
    try:
        if ser.in_waiting > 0:
            # Read the string sent by Arduino
            line = ser.readline().decode('utf-8').strip()
            
            if line in key_map:
                desired_key = key_map[line]
                
                # If the joystick moved to a new direction (or centered)
                if current_key != desired_key:
                    
                    # Release the old key so your character stops moving
                    if current_key is not None:
                        pyautogui.keyUp(current_key)
                    
                    # Press and hold the new key
                    if desired_key is not None:
                        pyautogui.keyDown(desired_key)
                    
                    current_key = desired_key
                    
    except KeyboardInterrupt:
        print("\nStopping script...")
        # Cleanly release any key that might be stuck down when you exit
        if current_key is not None:
            pyautogui.keyUp(current_key)
        ser.close()
        break
