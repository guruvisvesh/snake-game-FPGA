"""
play_gamepad.py - PC Controller Bridge for Zybo Z7 Snake Game (Method 1)
-----------------------------------------------------------------------
Reads EvoFox USB Gamepad (and Keyboard) and sends directional commands
over USB-UART serial to the Zybo Z7 board at 115200 baud.

Requirements:
    pip install pyserial pygame
"""

import sys
import time
import os

try:
    import serial
    import serial.tools.list_ports
except ImportError:
    print("[ERROR] 'pyserial' not found! Installing now...")
    os.system(f"{sys.executable} -m pip install pyserial")
    import serial
    import serial.tools.list_ports

try:
    import pygame
except ImportError:
    print("[ERROR] 'pygame' not found! Installing now...")
    os.system(f"{sys.executable} -m pip install pygame")
    import pygame


def find_zybo_port():
    """Detect Zybo COM port or let user choose."""
    ports = list(serial.tools.list_ports.comports())
    if not ports:
        print("[WARNING] No COM ports detected! Please connect the Zybo board via PROG UART micro-USB.")
        return None

    print("\n--- Available COM Ports ---")
    for i, p in enumerate(ports):
        desc = p.description or ""
        print(f"  [{i+1}] {p.device} - {desc}")

    # Auto-pick if only one port
    if len(ports) == 1:
        print(f"--> Auto-selected: {ports[0].device}")
        return ports[0].device

    # Check for FTDI / USB Serial port
    for p in ports:
        if "USB Serial" in p.description or "FTDI" in p.description:
            print(f"--> Detected Zybo port: {p.device}")
            return p.device

    # Otherwise ask user
    choice = input("\nEnter port number (e.g., 1): ").strip()
    try:
        idx = int(choice) - 1
        return ports[idx].device
    except Exception:
        return ports[0].device


def main():
    print("=" * 60)
    print("   Zybo Z7 Snake Game - EvoFox Controller Bridge")
    print("=" * 60)

    # 1. Connect Serial
    port_name = find_zybo_port()
    ser = None
    if port_name:
        try:
            ser = serial.Serial(port_name, 115200, timeout=0.1)
            print(f"[SUCCESS] Connected to Zybo on {port_name} at 115200 baud!\n")
        except Exception as e:
            print(f"[ERROR] Could not open {port_name}: {e}")
            print("Running in DEMO mode without serial output.\n")
    else:
        print("Running in DEMO mode without serial output.\n")

    # 2. Init Pygame
    pygame.init()
    pygame.joystick.init()

    # Create UI Window
    screen = pygame.display.set_mode((500, 360))
    pygame.display.set_caption("Zybo Snake Game - Controller Bridge")
    font = pygame.font.SysFont("Arial", 18)
    font_large = pygame.font.SysFont("Arial", 28, bold=True)
    clock = pygame.time.Clock()

    # Check Gamepad
    joystick = None
    if pygame.joystick.get_count() > 0:
        joystick = pygame.joystick.Joystick(0)
        joystick.init()
        print(f"[GAMEPAD DETECTED] {joystick.get_name()}")
    else:
        print("[INFO] No gamepad detected yet. You can also use Keyboard (W/A/S/D or Arrow keys)!")

    last_cmd = ""
    last_cmd_time = 0
    active_btn = None

    def send_cmd(cmd, label):
        nonlocal last_cmd, last_cmd_time, active_btn
        active_btn = label
        last_cmd = label
        last_cmd_time = time.time()
        print(f"[ACTION] --> {label} (Sent: '{cmd}')")
        if ser and ser.is_open:
            try:
                ser.write(cmd.encode("ascii"))
                ser.flush()
            except Exception as e:
                print(f"[SERIAL ERROR] {e}")

    running = True
    dpad_prev = (0, 0)
    axis_prev = (0, 0)

    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

            # Gamepad hotplug
            elif event.type == pygame.JOYDEVICEADDED:
                if joystick is None:
                    joystick = pygame.joystick.Joystick(event.device_index)
                    joystick.init()
                    print(f"[GAMEPAD CONNECTED] {joystick.get_name()}")

            elif event.type == pygame.JOYDEVICEREMOVED:
                print("[GAMEPAD DISCONNECTED]")
                joystick = None

            # ---------------------------------------------------------
            # Gamepad Buttons
            # Standard EvoFox / XInput Mapping:
            # Button 0: A (DOWN)
            # Button 1: B (RIGHT)
            # Button 2: X (LEFT)
            # Button 3: Y (UP)
            # Button 6/7: Select / Start (RESET / START)
            # ---------------------------------------------------------
            elif event.type == pygame.JOYBUTTONDOWN:
                b = event.button
                if b == 3:  # Y Button
                    send_cmd("U", "UP (Y Button)")
                elif b == 0:  # A Button
                    send_cmd("D", "DOWN (A Button)")
                elif b == 2:  # X Button
                    send_cmd("L", "LEFT (X Button)")
                elif b == 1:  # B Button
                    send_cmd("R", "RIGHT (B Button)")
                elif b in (6, 7, 8, 9, 10):  # Start / Select / Home
                    send_cmd("S", "START / RESET")

            # ---------------------------------------------------------
            # Gamepad D-Pad (Hat)
            # ---------------------------------------------------------
            elif event.type == pygame.JOYHATMOTION:
                hx, hy = event.value
                if hy == 1 and dpad_prev[1] != 1:
                    send_cmd("U", "UP (D-Pad)")
                elif hy == -1 and dpad_prev[1] != -1:
                    send_cmd("D", "DOWN (D-Pad)")
                elif hx == -1 and dpad_prev[0] != -1:
                    send_cmd("L", "LEFT (D-Pad)")
                elif hx == 1 and dpad_prev[0] != 1:
                    send_cmd("R", "RIGHT (D-Pad)")
                dpad_prev = (hx, hy)

            # ---------------------------------------------------------
            # Gamepad Left Analog Stick
            # ---------------------------------------------------------
            elif event.type == pygame.JOYAXISMOTION:
                if joystick:
                    ax = joystick.get_axis(0)  # X axis (-1 left, +1 right)
                    ay = joystick.get_axis(1)  # Y axis (-1 up, +1 down)
                    thresh = 0.65

                    curr_y = 1 if ay < -thresh else (-1 if ay > thresh else 0)
                    curr_x = 1 if ax > thresh else (-1 if ax < -thresh else 0)

                    if curr_y == 1 and axis_prev[1] != 1:
                        send_cmd("U", "UP (Analog Stick)")
                    elif curr_y == -1 and axis_prev[1] != -1:
                        send_cmd("D", "DOWN (Analog Stick)")
                    elif curr_x == -1 and axis_prev[0] != -1:
                        send_cmd("L", "LEFT (Analog Stick)")
                    elif curr_x == 1 and axis_prev[0] != 1:
                        send_cmd("R", "RIGHT (Analog Stick)")

                    axis_prev = (curr_x, curr_y)

            # ---------------------------------------------------------
            # Keyboard Controls (Fallback)
            # ---------------------------------------------------------
            elif event.type == pygame.KEYDOWN:
                if event.key in (pygame.K_UP, pygame.K_w):
                    send_cmd("U", "UP (Key: W/Up)")
                elif event.key in (pygame.K_DOWN, pygame.K_s):
                    send_cmd("D", "DOWN (Key: S/Down)")
                elif event.key in (pygame.K_LEFT, pygame.K_a):
                    send_cmd("L", "LEFT (Key: A/Left)")
                elif event.key in (pygame.K_RIGHT, pygame.K_d):
                    send_cmd("R", "RIGHT (Key: D/Right)")
                elif event.key in (pygame.K_SPACE, pygame.K_RETURN, pygame.K_r):
                    send_cmd("S", "START / RESET (Space)")

        # ---------------------------------------------------------
        # Draw UI
        # ---------------------------------------------------------
        screen.fill((20, 24, 34))

        # Title
        title_surf = font_large.render("Zybo Snake Game Controller", True, (0, 210, 255))
        screen.blit(title_surf, (20, 20))

        # Status text
        port_txt = f"Serial Port: {port_name or 'Disconnected'} (115200 baud)"
        screen.blit(font.render(port_txt, True, (0, 255, 128) if ser else (255, 100, 100)), (20, 70))

        gp_name = joystick.get_name() if joystick else "Not connected (Use Keyboard)"
        gp_color = (0, 255, 128) if joystick else (255, 180, 0)
        screen.blit(font.render(f"Gamepad: {gp_name}", True, gp_color), (20, 100))

        # Controls reference
        screen.blit(font.render("Controls:", True, (200, 200, 200)), (20, 140))
        screen.blit(font.render("  Y button / W / Up Arrow   -->  UP", True, (240, 240, 240)), (20, 165))
        screen.blit(font.render("  A button / S / Down Arrow -->  DOWN", True, (240, 240, 240)), (20, 190))
        screen.blit(font.render("  X button / A / Left Arrow -->  LEFT", True, (240, 240, 240)), (20, 215))
        screen.blit(font.render("  B button / D / Right Arrow-->  RIGHT", True, (240, 240, 240)), (20, 240))
        screen.blit(font.render("  Start / Spacebar          -->  RESET / START", True, (240, 240, 240)), (20, 265))

        # Last pressed badge
        if last_cmd and (time.time() - last_cmd_time < 0.5):
            badge = font_large.render(f"Pressed: {last_cmd}", True, (255, 255, 0))
            screen.blit(badge, (20, 310))

        pygame.display.flip()
        clock.tick(60)

    if ser and ser.is_open:
        ser.close()
    pygame.quit()


if __name__ == "__main__":
    main()
