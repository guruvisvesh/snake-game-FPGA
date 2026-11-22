# ModelSim Compilation Script for Simple Game Test
# Usage: In ModelSim, go to File -> New -> Source -> Do, or run: do compile_simple.do

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

# Compile simple testbench
echo "Compiling simple testbench..."
vlog "tb_simple_game.v"

# Run simulation
echo "Starting simulation..."
vsim -novopt work.tb_simple_game

# Add signals to waveform
add wave -position insertpoint  \
    sim:/tb_simple_game/clk \
    sim:/tb_simple_game/sw \
    sim:/tb_simple_game/btn \
    sim:/tb_simple_game/uut/game_state \
    sim:/tb_simple_game/uut/head_x \
    sim:/tb_simple_game/uut/head_y \
    sim:/tb_simple_game/uut/length \
    sim:/tb_simple_game/uut/direction \
    sim:/tb_simple_game/uut/bcd_score

# Run the simulation with timeout
run 20ms

echo "Simple game test complete. Check transcript for test results."