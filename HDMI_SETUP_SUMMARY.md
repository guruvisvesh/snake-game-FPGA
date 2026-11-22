# Snake Game FPGA - HDMI TX Setup Summary

## ✅ Changes Made for HDMI TX and Push Button Control

### 1. **top.v - Updated Module Ports**
**Changed from Arduino/Switch interface to Push Button interface:**

**Old Ports:**
- `input [3:0] sw` - 4 switches
- `input ard_up, ard_down, ard_left, ard_right, ard_start` - Arduino inputs
- `output [3:0] vga_r, vga_g, vga_b, hsync, vsync` - VGA outputs (unused)

**New Ports:**
- `input sw` - Single reset switch (G15)
- `input [3:0] btn` - 4 push buttons for direction control
  - `btn[0]` = UP (K18)
  - `btn[1]` = DOWN (P16)
  - `btn[2]` = LEFT (K19)
  - `btn[3]` = RIGHT (Y16)
- **Removed:** Arduino inputs and VGA outputs (not needed for HDMI)

### 2. **input_controller.v - Updated for Push Buttons**
**Changed from Arduino joystick to active-low push buttons:**

**Key Changes:**
- **Synchronizer:** Now synchronizes 4 push button inputs instead of 5 Arduino inputs
- **Active-Low Handling:** Zybo push buttons are active-low (pressed = 0), so signals are inverted
- **Edge Detection:** Added rising edge detection for each button to register direction changes
- **Start Detection:** Any button press generates a start pulse to begin the game
- **Simplified Logic:** Removed complex debouncing, using simple edge detection

**Direction Mapping:**
- Button press on `btn[0]` (K18) → UP
- Button press on `btn[1]` (P16) → DOWN
- Button press on `btn[2]` (K19) → LEFT
- Button press on `btn[3]` (Y16) → RIGHT

### 3. **zybo.xdc - Updated Constraints**
**Changed pin assignments to match new ports:**

**Old Constraints:**
- `sw[0]` to `sw[4]` - 5 switches
- No button constraints

**New Constraints:**
- `sw` - Single reset switch (G15)
- `btn[0]` - UP button (K18)
- `btn[1]` - DOWN button (P16)
- `btn[2]` - LEFT button (K19)
- `btn[3]` - RIGHT button (Y16)
- HDMI TX pins unchanged ✓
- Pmod SSD pins unchanged ✓

### 4. **pixel_renderer.v - Already Updated**
**Previously modified for new layout:**
- Game area: 640×432 pixels (40×27 grid, 16×16 cells)
- Score area: 640×48 pixels at bottom
- Small 8×8 font scaled to 16×16 for score text
- Proper separation between game and score areas
- Walls at correct boundaries (col 0, 39, row 0, 26)

## 🎯 HDMI TX Implementation (Unchanged - Already Working)

The HDMI TX implementation remains intact and working:

### **HDMI Output Chain:**
1. **pixel_renderer.v** → Generates 4-bit VGA colors (vga_r, vga_g, vga_b)
2. **hdmi_tx.v** → Converts VGA to HDMI TMDS signals
3. **tmds_encoder.v** → Encodes TMDS data
4. **Differential Outputs** → hdmi_tx_clk_p/n, hdmi_tx_d_p[2:0]/n

### **HDMI Specifications:**
- **Resolution:** 640×480 @ 60Hz
- **Pixel Clock:** 25 MHz
- **Serial Clock:** ~250 MHz (10× pixel clock)
- **Color Depth:** 12-bit (4 bits per channel, padded to 8-bit)
- **Video Standard:** HDMI 1.0 compatible

### **Score Display (via HDMI):**
- **Location:** Bottom 48 pixels (Y = 432 to 479)
- **Format:** "SCORE: XXX" (3 digits, 000-999)
- **Font:** 8×8 bitmap scaled to 16×16 pixels
- **Color:** White text on dark navy background
- **Alignment:** Horizontally and vertically centered
- **Separator:** Cyan line at Y = 432

## 📋 Files Required for Bitstream Generation

### **Verilog Source Files (15 modules):**
1. `top.v` - Top-level module ✓ (updated)
2. `clock_generator.v` - Clock generation (MMCM)
3. `input_controller.v` - Push button handling ✓ (updated)
4. `game_fsm.v` - Game state machine
5. `snake_controller.v` - Snake movement logic
6. `snake_memory.v` - Snake body storage (BRAM)
7. `food_generator.v` - Random food placement
8. `collision_detector.v` - Collision detection
9. `lfsr.v` - Pseudo-random number generator
10. `vga_controller.v` - VGA timing generator
11. `pixel_renderer.v` - Game rendering ✓ (updated for new layout)
12. `score_counter.v` - Score to BCD conversion
13. `pmod_ssd_driver.v` - 7-segment display driver
14. `hdmi_tx.v` - HDMI transmitter
15. `tmds_encoder.v` - TMDS encoder

### **Constraints File:**
- `zybo.xdc` - Pin constraints ✓ (updated)

### **Optional/Unused Files:**
- `debounce.v` - Not used in current implementation (can be removed)

## 🚀 How to Generate Bitstream in Vivado

### **Step 1: Create New Project**
```tcl
# In Vivado Tcl Console or GUI:
create_project snake_game ./snake_game -part xc7z010clg400-1
```

### **Step 2: Add Source Files**
```tcl
# Add all Verilog files:
add_files Verilog/*.v

# Add constraints:
add_files -fileset constrs_1 -norecurse constraints/zybo.xdc
```

### **Step 3: Set Top Module**
```tcl
set_property top top [current_fileset]
```

### **Step 4: Synthesize**
```tcl
# Or click "Run Synthesis" in GUI
launch_runs synth_1 -jobs 4
wait_on_run synth_1
```

### **Step 5: Implement**
```tcl
# Or click "Run Implementation" in GUI
launch_runs impl_1 -jobs 4
wait_on_run impl_1
```

### **Step 6: Generate Bitstream**
```tcl
# Or click "Generate Bitstream" in GUI
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
```

### **Step 7: Program Board**
```tcl
# Connect Zybo board via USB
# In Hardware Manager:
open_hw_target
set_property PROGRAM.FILE {./snake_game/snake_game.runs/impl_1/top.bit} [get_hw_devices xc7z010_0]
program_hw_devices [get_hw_devices xc7z010_0]
```

## 🎮 How to Use the Game

### **Hardware Setup:**
1. Connect HDMI monitor to Zybo HDMI port
2. Connect USB cable for programming
3. Connect Pmod SSD to Pmod JA (optional, shows score on 7-segment)

### **Controls:**
- **Reset:** Toggle SW0 (G15) ON or OFF
- **Start Game:** Press any direction button (BTN0-BTN3)
- **Change Direction:** Press direction buttons during gameplay
  - BTN0 (K18) → UP
  - BTN1 (P16) → DOWN
  - BTN2 (K19) → LEFT
  - BTN3 (Y16) → RIGHT

### **Expected Display:**
- **Game Area:** 640×432 pixels showing snake, food, walls
- **Score Area:** 48-pixel bottom bar showing "SCORE: XXX"
- **Colors:** Green snake, red food, gray walls, checkerboard background
- **Frame Rate:** ~60 Hz via HDMI

## ✅ Verification Checklist

Before generating bitstream, verify:

- [x] All Verilog files compile without errors
- [x] Constraints file matches top.v ports
- [x] HDMI TX modules are instantiated correctly
- [x] Clock generator uses MMCM (vendor primitive)
- [x] Push button inputs are synchronized
- [x] Score display logic is correct
- [x] Game boundaries match (40×27 grid)
- [x] No unused ports in top.v

## 🐛 Troubleshooting

### **If Score Doesn't Display:**
1. Check `pixel_renderer.v` score rendering logic
2. Verify `bcd_score` is correctly passed from `score_counter.v`
3. Check score area boundary (Y = 432 to 479)
4. Verify HDMI color mapping (4-bit to 8-bit padding)

### **If HDMI Output is Black:**
1. Check clock generation (25 MHz pixel clock)
2. Verify HDMI TX connections (hdmi_tx_clk_p/n, hdmi_tx_d_p/n)
3. Check video_on signal from vga_controller
4. Verify TMDS encoding is working

### **If Buttons Don't Work:**
1. Verify active-low signal inversion in input_controller
2. Check edge detection logic
3. Verify button pin assignments in constraints
4. Check synchronizer is working

## 📊 Resource Utilization (Estimated)

Based on Zybo Z7-10 (xc7z010clg400-1):

- **LUTs:** ~2000-3000
- **FFs:** ~1500-2500
- **BRAM:** ~2-4 blocks (for snake memory)
- **DSP:** 0 (no DSP slices used)
- **MMCM:** 1 (for clock generation)

## 🎉 Summary

All files are now ready for bitstream generation with:
- ✅ HDMI TX implementation (unchanged, already working)
- ✅ Push button control (BTN0-BTN3)
- ✅ Proper score display via HDMI
- ✅ Correct 40×27 game grid layout
- ✅ Clean separation of game and score areas
- ✅ Active-low button handling
- ✅ Synchronized inputs to prevent metastability

The design is fully compatible with Zybo Z7-10 and should work correctly when programmed to the board.
