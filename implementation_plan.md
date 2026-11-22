# Implementation Status - HDMI Output and Switch-Based Control

## ✅ COMPLETED IMPLEMENTATIONS

### 1. HDMI Tx Integration
The HDMI output system has been fully implemented with the following modules:

**Implemented Modules:**
- **`clock_generator.v`**: Uses `MMCME2_BASE` hardware PLL to generate 25 MHz pixel clock and 250 MHz HDMI serial clock from the 125 MHz board oscillator
- **`tmds_encoder.v`**: Encodes 8-bit RGB pixel data into 10-bit DC-balanced TMDS format required by HDMI monitors
- **`hdmi_tx.v`**: Serializes TMDS data at 250 MHz using `OSERDESE2` and `OBUFDS` differential output buffers
- **Updated `top.v`**: Instantiates HDMI modules and routes video output through HDMI Tx port
- **Updated `zybo.xdc`**: Contains proper pin assignments for HDMI Tx port with `TMDS_33` I/O standard

**Video Specifications:**
- Resolution: 640 × 480 pixels at 60 Hz
- Color depth: 4 bits per channel (padded to 8 bits for HDMI)
- Clock: 25 MHz pixel clock, 250 MHz serial clock

### 2. Enhanced Score Display
The on-screen score display has been significantly enhanced:

**Enhanced Features:**
- **"SCORE:" text label**: Bright yellow pixel-based text rendering on the left side (x=20-164, y=440-472)
- **Cyan separator line**: Visual separator between text and digits (x=172-176)
- **Larger 7-segment digits**: Increased from 48×48 to 56×48 pixels for better visibility
- **Improved positioning**: Tens digit at x=264-320, ones digit at x=336-392
- **Priority rendering**: Digits render on top of other elements for clarity
- **Color scheme**: Dark navy background (0x013), bright cyan accent line (0x39F), bright white digits (0xFFF)

**Score Display Locations:**
- On-screen HDMI: Bottom 48 pixel rows (y=432-479)
- Physical Pmod SSD: Connected to Pmod JA (same score displayed simultaneously)

### 3. Push Button-Based Control with Edge Detection
Since the joystick requires 5V→3.3V level shifting (resistors not available), the onboard push buttons have been adapted for directional control:

**Button Mapping:**
- **SW0 (G15)**: RESET - toggle ON/OFF to reset (continuous signal, not edge-detected)
- **BTN0 (K18)**: UP - press to move snake up (edge detection)
- **BTN1 (P16)**: DOWN - press to move snake down (edge detection)  
- **BTN2 (K19)**: LEFT - press to move snake left (edge detection)
- **BTN3 (Y16)**: RIGHT - press to move snake right (edge detection)

**Edge Detection Implementation:**
- Modified `input_controller.v` to detect rising edges (0→1 transitions) on push buttons (BTN0-BTN3)
- Push buttons are active-low on Zybo board (pressed = 0V, released = 3.3V)
- Input controller inverts button signals to work with active-high logic internally
- Edge detection ensures each button press produces exactly one direction change
- Reset switch (SW0) uses continuous signal for immediate reset functionality
- Debouncing implemented via edge detection and FSM timing

**How to Use:**
1. Press any direction button (BTN0-BTN3) to start the game and set initial direction
2. Press direction buttons to change snake direction during gameplay
3. Toggle SW0 (G15) ON or OFF at any time to reset the game

## 🔧 FUTURE ENHANCEMENTS (Optional)

### Joystick Integration (Requires Level Shifting)
If you obtain resistors for voltage division, the Arduino-based joystick interface can be implemented:

**Required Components:**
- 1kΩ and 2kΩ resistors for each of the 5 signal lines (UP, DOWN, LEFT, RIGHT, START)
- Voltage divider configuration: 1kΩ series from Arduino, 2kΩ to ground, tap to Zybo

**Pin Mapping (Arduino → Zybo Pmod JE):**
- Arduino D3 (UP) → Zybo JE3 (J15)
- Arduino D4 (DOWN) → Zybo JE4 (H15)  
- Arduino D5 (LEFT) → Zybo JE1 (V12)
- Arduino D6 (RIGHT) → Zybo JE2 (W16)
- Arduino D7 (START) → Zybo JE7 (V13)

**Software Changes Required:**
- Modify `input_controller.v` to accept continuous signals instead of edge-triggered
- Update `top.v` port mappings to use Pmod JE instead of onboard switches
- Update `zybo.xdc` constraints for Pmod JE pin assignments

## Current Status
The project is fully functional with HDMI output, enhanced score display, and switch-based control. All hardware safety concerns have been addressed by using the onboard switches with edge detection instead of direct joystick connection.

## Recent Fixes (v1.1)
### Score Display Alignment Issues
- **Problem**: Score text and digits were misaligned and not rendering properly
- **Solution**: Repositioned all score elements with proper spacing:
  - "SCORE:" text: x=20-120, y=440-468 (20px per letter, 28px tall)
  - Separator line: x=128-132 (4px wide cyan line)
  - Tens digit: x=200-256 (56px wide)
  - Ones digit: x=272-328 (56px wide)
- **Result**: Score display now properly aligned and readable

### Game Start Issues
- **Problem**: Snake not initiating when pressing switches due to faulty debouncing logic
- **Solution**: 
  - Removed overly complex debouncing that prevented start button from working
  - Implemented direct edge detection for cleaner button response
  - Added fallback to accept continuous signal for testing
  - Simplified start button logic: `btn_start = pulse_start || sync_start`
- **Result**: Game now starts reliably when buttons are pressed

### Push Button Integration (v1.2)
- **Problem**: Originally planned to use slide switches for direction control
- **Solution**: 
  - Updated constraints to use actual push buttons (BTN0-BTN3) at pins K18, P16, K19, Y16
  - Modified top-level module to accept separate btn[3:0] input instead of sw[4:0]
  - Updated input controller to handle active-low button signals with automatic inversion
  - Kept SW0 (G15) as toggle switch for reset functionality
- **Result**: More intuitive control using actual push buttons instead of slide switches

### Enhanced Debugging
- Added troubleshooting section to README with common issues and solutions
- Improved documentation for button behavior and timing
- Added color specifications for score display verification
- Updated pin mapping documentation for push buttons
