"""
EvoFox USB Gamepad to Zybo FPGA UART Controller Bridge
=====================================================
Reads digital button inputs from the EvoFox USB Gamepad on your PC
and transmits direction commands ('U', 'D', 'L', 'R') over UART to Zybo.

Features:
- Maps ONLY UP, DOWN, LEFT, RIGHT. Reset is kept strictly on Zybo board pin G15 (sw).
- Prints real-time debug info for button presses so you can verify button mappings.
"""

import sys
import time
import serial
import serial.tools.list_ports

try:
    import pygame
except ImportError:
    print("Error: pygame is not installed. Run: pip install pygame")
    sys.exit(1)


def list_com_ports():
    ports = serial.tools.list_ports.comports()
    return [port.device for port in ports]


def main():
    print("==================================================")
    print("  EvoFox Gamepad -> Zybo FPGA UART Controller Bridge")
    print("==================================================")

    pygame.init()
    pygame.joystick.init()

    joystick_count = pygame.joystick.get_count()
    if joystick_count == 0:
        print("\n[!] No controller detected!")
        print("    Please plug in your EvoFox USB Gamepad and rerun this script.")
        return

    controller = pygame.joystick.Joystick(0)
    controller.init()
    print(f"\n[+] Connected to Controller: {controller.get_name()}")
    num_buttons = controller.get_numbuttons()
    num_hats = controller.get_numhats()
    print(f"    Digital buttons: {num_buttons}, D-Pads (Hats): {num_hats}")

    # Select COM Port
    ports = list_com_ports()
    if not ports:
        print("\n[!] No COM ports detected. Plug in Zybo / USB-UART cable.")
        com_port = input("    Enter COM port manually (e.g. COM3): ").strip()
    else:
        print("\n[+] Available COM ports:")
        for idx, p in enumerate(ports):
            print(f"    [{idx + 1}] {p}")
        com_port = ports[0]
        user_choice = input(f"    Select COM port [1-{len(ports)}] (Default: {com_port}): ").strip()
        if user_choice.isdigit() and 1 <= int(user_choice) <= len(ports):
            com_port = ports[int(user_choice) - 1]

    baud_rate = 115200

    try:
        ser = serial.Serial(com_port, baud_rate, timeout=0.1)
        print(f"\n[+] Connected to {com_port} @ {baud_rate} Baud")
    except Exception as e:
        print(f"\n[!] Could not open serial port {com_port}: {e}")
        return

    print("\n--------------------------------------------------")
    print("  Press top-right buttons on your EvoFox Gamepad:")
    print("  TOP (Y / North)    --> Sends 'U' (UP)")
    print("  BOTTOM (A / South) --> Sends 'D' (DOWN)")
    print("  LEFT (X / West)    --> Sends 'L' (LEFT)")
    print("  RIGHT (B / East)   --> Sends 'R' (RIGHT)")
    print("  D-Pad is also supported.")
    print("  Reset remains on Zybo Board Switch SW (G15).")
    print("--------------------------------------------------\n")

    last_cmd = None
    prev_buttons = [0] * num_buttons

    try:
        while True:
            pygame.event.pump()

            cmd_to_send = None

            # Print raw button presses for diagnostics
            for i in range(num_buttons):
                val = controller.get_button(i)
                if val and not prev_buttons[i]:
                    print(f"    [Button Pressed] Index [{i}]")
                prev_buttons[i] = val

            # Check Top-Right face buttons
            # Standard mappings:
            # Button 3 or 0 = Top/Bottom, 2/1 = Left/Right
            # We map: Top -> 'U', Bottom -> 'D', Left -> 'L', Right -> 'R'
            
            # 1. Face Buttons Check
            if num_buttons >= 4:
                # Check Y (Top) / A (Bottom) / X (Left) / B (Right)
                if controller.get_button(3):      # Top button (Y)
                    cmd_to_send = 'U'
                elif controller.get_button(0):    # Bottom button (A)
                    cmd_to_send = 'D'
                elif controller.get_button(2):    # Left button (X)
                    cmd_to_send = 'L'
                elif controller.get_button(1):    # Right button (B)
                    cmd_to_send = 'R'

            # 2. D-Pad (Hat) Check
            if num_hats > 0 and not cmd_to_send:
                hat = controller.get_hat(0)
                if hat[1] == 1:
                    cmd_to_send = 'U'
                elif hat[1] == -1:
                    cmd_to_send = 'D'
                elif hat[0] == -1:
                    cmd_to_send = 'L'
                elif hat[0] == 1:
                    cmd_to_send = 'R'

            # 3. Transmit over UART
            if cmd_to_send and cmd_to_send != last_cmd:
                ser.write(cmd_to_send.encode('ascii'))
                print(f"[UART -> Zybo] Sent Command: '{cmd_to_send}'")
                last_cmd = cmd_to_send
            elif not cmd_to_send:
                last_cmd = None

            time.sleep(0.02)

    except KeyboardInterrupt:
        print("\nStopping bridge script...")
    finally:
        ser.close()
        pygame.quit()


if __name__ == '__main__':
    main()
