# ModelSim Simulation Guide for Snake Game FPGA

This guide explains how to use ModelSim for simulating the Snake Game FPGA project.

## Prerequisites
- ModelSim (or ModelSim-Altera) installed
- All Verilog source files in the `Verilog/` directory
- Testbench files in the `testbench/` directory
- **Simulation primitives file** (`sim_primitives.v`) for Xilinx-specific cells

## Available Testbenches

### 1. `tb_image_gen.v` - Game Logic Testbench (Originally for Image Generation)
**Purpose**: Tests game logic states and transitions
**Output**: Console messages showing test results
**Use Case**: Functional testing (image generation disabled due to ModelSim hierarchical access limitations)
**Note**: This testbench originally generated PPM images, but hierarchical signal access issues in ModelSim prevent reliable image capture. It now performs logic testing identical to tb_simple_game.v.

### 2. `tb_simple_game.v` - Simple Game Logic Testbench  
**Purpose**: Tests game logic without image generation
**Output**: Console messages showing test results
**Use Case**: Quick functional testing and debugging
**Note**: Recommended for routine testing - simpler and more reliable.

## Running Simulations

### Method 1: Using Provided Scripts (Recommended)

#### For Game Logic Testing (either testbench):
```bash
cd testbench
do compile_simple.do        # Recommended
# OR
do compile_modelsim.do      # Also works (same functionality)
```
**Expected time**: ~5-10 seconds with ultra-fast optimization

**Note**: Both testbenches now perform identical logic verification. Image generation has been disabled due to ModelSim hierarchical signal access limitations.

### Method 2: Manual Compilation in ModelSim GUI

1. **Launch ModelSim**
   ```bash
   vsim
   ```

2. **Create Working Library**
   - File → New → Library
   - Name: `work`
   - Click OK

3. **Compile Design Files** (in this order):
   ```tcl
   # First compile simulation primitives (must be first!)
   vlog sim_primitives.v
   
   # Then compile design files
   vlog ../Verilog/lfsr.v
   vlog ../Verilog/tmds_encoder.v
   vlog ../Verilog/clock_generator.v
   vlog ../Verilog/input_controller.v
   vlog ../Verilog/game_fsm.v
   vlog ../Verilog/snake_controller.v
   vlog ../Verilog/snake_memory.v
   vlog ../Verilog/food_generator.v
   vlog ../Verilog/collision_detector.v
   vlog ../Verilog/vga_controller.v
   vlog ../Verilog/pixel_renderer.v
   vlog ../Verilog/score_counter.v
   vlog ../Verilog/pmod_ssd_driver.v
   vlog ../Verilog/hdmi_tx.v
   vlog ../Verilog/top.v
   ```

4. **Compile Testbench**
   ```tcl
   vlog tb_image_gen.v
   # OR
   vlog tb_simple_game.v
   ```

5. **Start Simulation**
   ```tcl
   vsim work.tb_image_gen
   # OR
   vsim work.tb_simple_game
   ```

6. **Run Simulation**
   ```tcl
   run -all
   ```

## Viewing Generated Images

The `tb_image_gen.v` testbench generates PPM image files that can be viewed with:

1. **Image viewers**: IrfanView, GIMP, Photoshop (most support PPM format)
2. **Online converters**: Convert to PNG/JPG using online tools
3. **Python**: Use PIL/Pillow library to convert and view

### Python Example to View Images:
```python
from PIL import Image
import os

# Convert and display PPM files
for i in range(1, 5):
    filename = f"0{i}_*.ppm"
    if os.path.exists(filename):
        img = Image.open(filename)
        img.show()
```

## Troubleshooting

### Issue: "Hierarchical reference to signal not found"
**Cause**: Internal signal names or hierarchy may differ after synthesis
**Solution**: Use `tb_simple_game.v` instead, which doesn't rely on hierarchical signal access

### Issue: "Compilation errors"
**Cause**: Files not compiled in correct dependency order
**Solution**: Use the provided `.do` scripts which ensure correct compilation order

### Issue: "Instantiation of 'MMCME2_BASE' failed"
**Cause**: Xilinx-specific primitives not available in ModelSim
**Solution**: The provided `.do` scripts automatically compile `sim_primitives.v` which contains behavioral models for Xilinx primitives. Ensure this file is compiled first.

### Issue: "Simulation runs too slow"
**Cause**: Game clock speed too slow for simulation
**Solution**: The testbench automatically speeds up the game clock via `defparam`

### Issue: "PPM files not generated"
**Cause**: File write permissions or directory issues
**Solution**: Ensure ModelSim has write permissions to the testbench directory

## Expected Simulation Results

### tb_image_gen.v:
- **01_start.ppm**: Blue screen with initial game state
- **02_gameplay.ppm**: Snake, food, and score display visible
- **03_eat_food.ppm**: Snake after eating food (should be longer)
- **04_game_over.ppm**: Game over screen with collision

### tb_simple_game.v:
- Console output showing:
  - ✓ Game in START state
  - ✓ Game entered PLAYING state  
  - ✓ Snake initialized correctly
  - ✓ Direction changes working
  - ✓ Game returned to START state after reset

## Notes

- The testbench uses `defparam` to speed up simulation (game tick ~1000 cycles instead of 6.25M for ultra-fast testing)
- Active-low button signals are handled automatically (pressed = 0, released = 1)
- HDMI outputs are present but not used in simulation - internal VGA signals are extracted
- The simulation freezes the game clock during image capture to prevent tearing
- **Simulation primitives**: `sim_primitives.v` provides behavioral models for Xilinx-specific cells (MMCME2_BASE, BUFG, OBUFDS) to enable ModelSim simulation without Xilinx libraries
- **Clock generation**: The simulation model simplifies the MMCM clock generation for faster simulation while maintaining correct frequency ratios
- **Zybo/Vivado compatibility**: All design files remain fully compatible with Zybo Z7-10 hardware and Vivado synthesis. Only simulation primitives are added for ModelSim compatibility.

## Next Steps

After successful simulation:
1. Verify the generated images look correct
2. Check console output for any errors
3. If everything works, proceed to Vivado for synthesis and implementation
4. Program the FPGA board and test with actual hardware