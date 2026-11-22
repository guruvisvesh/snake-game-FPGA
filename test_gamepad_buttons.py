"""
EvoFox Controller Button Tester
================================
Run this script to inspect your EvoFox controller button IDs in real-time.
"""
import sys
import time

try:
    import pygame
except ImportError:
    print("Please install pygame: pip install pygame")
    sys.exit(1)

pygame.init()
pygame.joystick.init()

if pygame.joystick.get_count() == 0:
    print("No controller found. Connect EvoFox Gamepad and try again.")
    sys.exit(0)

js = pygame.joystick.Joystick(0)
js.init()

print(f"Connected to: {js.get_name()}")
print(f"Num Buttons: {js.get_numbuttons()}")
print(f"Num Hats (D-Pad): {js.get_numhats()}")
print("Press buttons on your controller to see their IDs (Ctrl+C to quit)...")

try:
    prev_buttons = [0] * js.get_numbuttons()
    while True:
        pygame.event.pump()
        for i in range(js.get_numbuttons()):
            val = js.get_button(i)
            if val and not prev_buttons[i]:
                print(f"--> Button [{i}] PRESSED")
            prev_buttons[i] = val
        time.sleep(0.05)
except KeyboardInterrupt:
    print("\nDone.")
    pygame.quit()
