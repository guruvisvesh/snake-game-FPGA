# ModelSim Compilation Script for Snake Game FPGA
# Usage: In ModelSim, go to File -> New -> Source -> Do, or run: do compile_modelsim.do

# Create a new library if it doesn't exist
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# Compile all Verilog design files (in dependency order)
echo "Compiling design files..."

# Simulation primitives (must be first)
vlog "sim_primitives.v"

# Basic modules
vlog "../Verilog/lfsr.v"
vlog "../Verilog/tmds_encoder.v"

# Clock and input
vlog "../Verilog/clock_generator.v"
vlog "../Verilog/input_controller.v"

# Game logic
vlog "../Verilog/game_fsm.v"
vlog "../Verilog/snake_controller.v"
vlog "../Verilog/snake_memory.v"
vlog "../Verilog/food_generator.v"
vlog "../Verilog/collision_detector.v"

# Display
vlog "../Verilog/vga_controller.v"
vlog "../Verilog/pixel_renderer.v"
vlog "../Verilog/score_counter.v"
vlog "../Verilog/pmod_ssd_driver.v"
vlog "../Verilog/hdmi_tx.v"

# Top level
vlog "../Verilog/top.v"

# Compile testbench
echo "Compiling testbench..."
vlog "tb_image_gen.v"

# Run simulation
echo "Starting simulation..."
vsim -novopt work.tb_image_gen

# Add signals to waveform (optional)
add wave -position insertpoint  \
    sim:/tb_image_gen/clk \
    sim:/tb_image_gen/sw \
    sim:/tb_image_gen/btn \
    sim:/tb_image_gen/uut/game_state \
    sim:/tb_image_gen/uut/head_x \
    sim:/tb_image_gen/uut/head_y \
    sim:/tb_image_gen/uut/length \
    sim:/tb_image_gen/uut/direction

# Run the simulation with timeout
run 25ms

echo "Simulation complete. Check transcript for test results."
echo "Note: Image generation disabled due to hierarchical access issues in ModelSim."
echo "For logic verification, both tb_image_gen.v and tb_simple_game.v work identically."