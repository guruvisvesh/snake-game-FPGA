# 🐍 Hardware Snake Game on Digilent Basys 3 FPGA

A complete, high-performance **Snake Game** implemented entirely in synthesizable Verilog HDL for the **Digilent Basys 3 (Xilinx Artix-7 XC7A35T)** FPGA board. 

The design features **real-time 640×480 @ 60Hz VGA graphics**, **direct USB keyboard control** via the onboard USB HID Host, **onboard 4-digit 7-segment score display**, and **on-screen bitmap score rendering**—all running deterministically in hardware with **zero CPU and zero software latency**.

---

## 📸 System Overview

```
                      ┌────────────────────────────────────────────────────────┐
                      │                 Digilent Basys 3 FPGA                  │
                      │                                                        │
   100 MHz OSC (W5) ─►│  clock_generator ──► 25 MHz Pixel Clock (VGA)          │
                      │                  ──► ~10 Hz Game Tick Clock            │
                      │                                                        │
   USB Keyboard (J2) ─►  ps2_keyboard    ──►                                   │
   (Pins C17, B17)    │                      combined_btn[3:0]                 │
   Buttons (T18..T17)─►  input_controller──► direction[1:0]                   │
   Switch SW0 (V17) ──►  (Edge Detector) ──► btn_start                        │
                      │                                                        │
                      │  game_fsm ─────────► init_snake / move_snake           │
                      │                  ──► generate_food / game_state        │
                      │                                                        │
                      │  snake_controller ──► snake_memory (Dual-Port BRAM)    │
                      │  food_generator   ──► 16-bit LFSR (Random Coordinate)  │
                      │  collision_detect ──► Look-ahead Wall & Self Collision │
                      │                                                        │
                      │  score_counter ────► 12-bit BCD Score                  │
                      │  basys3_ssd_driver─► 4-Digit 7-Segment Display (Onboard│
                      │                                                        │
                      │  vga_controller ───► HSYNC, VSYNC, Pixel (X, Y)        │
                      │  pixel_renderer ───► 12-Bit RGB (vgaRed, Green, Blue) ─┼──► VGA Monitor
                      └────────────────────────────────────────────────────────┘
```

---

## ✨ Features

- **100% Pure Hardware Architecture:** No Soft-core/ARM processor, no operating system, and no software overhead. All modules operate in parallel on every clock cycle.
- **Direct USB Keyboard Support:** Plug any standard wired USB keyboard directly into the Basys 3 USB-A socket (`J2`). The onboard PIC24 USB Host bridge provides PS/2 signals (`C17`, `B17`), fully decoded in hardware by `ps2_keyboard.v`.
- **Crystal Clear 640×480 @ 60Hz VGA Output:** Built-in VGA controller driving the native Basys 3 12-bit resistor ladder DAC (4096 colors).
- **Dual Score Display:**
  - **On-Screen Bitmap Banner:** 48-pixel tall lower banner featuring an 8×8 font scaled 2× displaying `"SCORE: XXX"`.
  - **Onboard Physical Display:** Real-time 4-digit BCD counter multiplexed on the Basys 3 7-segment display.
- **Pseudo-Random Food Spawning:** 16-bit Linear Feedback Shift Register (LFSR) coupled with block RAM occupancy checking to guarantee food never spawns on top of the snake body.
- **Smooth Collision Logic:** Single-cycle look-ahead collision detection prevents the snake from clipping walls or reversing 180° into its own body.
- **Multiple Redundant Control Options:** Play via USB Keyboard (WASD/Arrows), Basys 3 onboard push buttons, or via PC serial UART.

---

## 🎮 Controls & Pin Mappings

### 1. USB Keyboard Controls (Connector `J2`)
Plug any standard USB keyboard directly into the USB-A port on the Basys 3:
| Key | Action | Scan Code (Make) |
|---|---|---|
| **`W`** or **Up Arrow (`↑`)** | Move **UP** | `0x1D` / `0x75` |
| **`S`** or **Down Arrow (`↓`)** | Move **DOWN** | `0x1B` / `0x72` |
| **`A`** or **Left Arrow (`←`)** | Move **LEFT** | `0x1C` / `0x6B` |
| **`D`** or **Right Arrow (`→`)** | Move **RIGHT** | `0x23` / `0x74` |
| **`Spacebar`** or **`Enter`** | **Start Game / Reset** | `0x29` / `0x5A` |

### 2. Onboard Basys 3 Controls
| Pin | Board Control | Signal / Role |
|---|---|---|
| **`W5`** | 100 MHz Oscillator | System Master Clock |
| **`V17`** | Slide Switch 0 (`SW0`) | **Reset Switch** *(DOWN = Play, UP = Reset)* |
| **`T18`** | Push Button Up (`BTNU`) | Move **UP** |
| **`U17`** | Push Button Down (`BTND`) | Move **DOWN** |
| **`W19`** | Push Button Left (`BTNL`) | Move **LEFT** |
| **`T17`** | Push Button Right (`BTNR`) | Move **RIGHT** |

### 3. VGA HD-15 Pin Mappings
| Color Channel | Basys 3 Pins (4-bit DAC) |
|---|---|
| **Red (`vgaRed[3:0]`)** | `N19` (MSB), `J19`, `H19`, `G19` (LSB) |
| **Green (`vgaGreen[3:0]`)** | `D17` (MSB), `G17`, `H17`, `J17` (LSB) |
| **Blue (`vgaBlue[3:0]`)** | `J18` (MSB), `K18`, `L18`, `N18` (LSB) |
| **Sync Signals** | **HSYNC:** `P19`, **VSYNC:** `R19` |

### 4. 4-Digit 7-Segment Display Pin Mappings
| Signal | Pins |
|---|---|
| **Cathodes (`seg[6:0]`)** | `CA`: `W7`, `CB`: `W6`, `CC`: `U8`, `CD`: `V8`, `CE`: `U5`, `CF`: `V5`, `CG`: `U7` |
| **Anodes (`an[3:0]`)** | `AN0`: `U2`, `AN1`: `U4`, `AN2`: `V4`, `AN3`: `W4` |

---

## 📁 Repository Structure

```
Snake_Game_Basys3/
├── .gitignore                          # Ignores Vivado cache, runs, and log files
├── README.md                           # Master Project Documentation
├── project_1/
│   └── project_1.xpr                   # Vivado 2018.3+ Project File
└── Snake_Game_FPGA/
    ├── constraints/
    │   └── basys3.xdc                  # Master XDC Pin Constraints for Basys 3
    ├── Verilog/
    │   ├── top.v                       # Top-level hardware wrapper & interconnect
    │   ├── clock_generator.v           # MMCM 100MHz -> 25MHz + Game Clock Divider
    │   ├── ps2_keyboard.v              # USB/PS2 keyboard scancode shift & decoder
    │   ├── input_controller.v          # Button synchronizer & direction edge detector
    │   ├── game_fsm.v                  # 4-state Finite State Machine controller
    │   ├── snake_controller.v          # Head movement & coordinate update logic
    │   ├── snake_memory.v              # Dual-port BRAM coordinate & grid buffer
    │   ├── food_generator.v            # Collision-free food placement generator
    │   ├── lfsr.v                      # 16-bit pseudo-random sequence generator
    │   ├── collision_detector.v        # Look-ahead wall, self, and food detector
    │   ├── vga_controller.v            # Standard 640x480@60Hz timing generator
    │   ├── pixel_renderer.v            # Multi-layer game canvas & bitmap text renderer
    │   ├── score_counter.v             # 12-bit BCD (Hundreds/Tens/Ones) score counter
    │   ├── basys3_ssd_driver.v         # Multiplexed 4-digit 7-segment display driver
    │   └── uart_rx.v                   # 115200 baud UART receiver for PC controls
    └── testbench/
        ├── tb_game.v                   # FSM & gameplay verification testbench
        ├── tb_vga.v                    # VGA timing simulation testbench
        └── tb_collision.v              # Collision edge case testbench
```

---

## 🧠 Hardware Architecture Details

### 1. Memory Architecture (`snake_memory.v`)
To avoid rendering bottlenecks and memory contention:
- **Coordinate Buffer (2K × 12-bit circular RAM):** Stores the `(X, Y)` grid coordinates for up to 2048 snake body segments (`[11:6] = X`, `[5:0] = Y`).
- **Occupancy Grid RAM (2K × 1-bit dual-read BRAM):** Maintains a fast 1-bit map of the entire 40×30 grid. Reading `dout_grid = 1` immediately verifies snake presence in that cell, allowing instantaneous pixel rendering and collision detection without iterating through body arrays.

### 2. Graphics Rendering Engine (`pixel_renderer.v`)
- **Game Grid:** 40 columns × 27 rows (cells are 16×16 pixels each), spanning pixel rows 0 to 431.
- **Score Canvas:** Rows 432 to 479 (48 pixels high) formatted in dark navy with a bright cyan dividing rule.
- **Text Engine:** Embeds a synthesized 8×8 alphanumeric character ROM scaled 2× horizontally and vertically (16×16 px glyphs) to spell `"SCORE: "` followed by three BCD digit values in pure combinational logic.

### 3. Keyboard Controller (`ps2_keyboard.v`)
- Debounces and double-synchronizes the incoming `ps2_clk` and `ps2_data` lines against the 100 MHz clock to eliminate metastability.
- Shifts 11-bit serial PS/2 frames (1 start bit, 8 data bits LSB-first, 1 odd parity bit, 1 stop bit).
- Distinguishes **Make codes** (key down) from **Break codes** (`0xF0` key release) to generate single-cycle directional pulses.

---

## 🛠️ Build and Programming Instructions

### Requirements
- **Hardware:** Digilent Basys 3 FPGA Board, standard USB-A keyboard, VGA cable & 640×480 capable monitor, Micro-USB programming cable.
- **Software:** Xilinx Vivado (2018.3 or newer, including Vivado ML Standard/Lab Edition).

### Steps
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/Gurunikesh/Snake_Game_Basys3.git
   ```
2. **Open the Project in Vivado:**
   - Launch Vivado.
   - Click **Open Project** and navigate to:
     `Snake_Game_Basys3/project_1/project_1.xpr`
3. **Generate Bitstream:**
   - Click **Generate Bitstream** in the Flow Navigator (or press `Ctrl + F5`).
   - Synthesis and Implementation will complete with zero errors.
4. **Program the Basys 3 Board:**
   - Connect the Basys 3 board to your PC via the Micro-USB cable.
   - Set the power jumper `JP2` to **USB** and flip power switch `SW16` to **ON**.
   - Open **Hardware Manager** → Click **Auto Connect**.
   - Right-click `xc7a35t_0` → **Program Device** → Select the generated `.bit` file.
5. **Play:**
   - Plug your USB keyboard into the **USB-A socket (`J2`)**.
   - Ensure Slide Switch 0 (`V17`) is in the **DOWN** position.
   - Press **`Spacebar`** (or `W`) to start the game and guide your snake!

---

## 📜 License
This project is open-source and available under the **MIT License**. Feel free to use, modify, and build upon it for academic or personal hardware projects.
