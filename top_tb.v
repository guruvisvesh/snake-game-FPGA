`timescale 1ns / 1ps

module top_tb;

    reg clk;
    reg [3:0] sw;
    reg [3:0] btn;
    
    wire [3:0] vga_r;
    wire [3:0] vga_g;
    wire [3:0] vga_b;
    wire hsync;
    wire vsync;
    
    wire [6:0] ssd_seg;
    wire ssd_sel;

    top uut (
        .clk(clk),
        .sw(sw),
        .btn(btn),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .hsync(hsync),
        .vsync(vsync),
        .ssd_seg(ssd_seg),
        .ssd_sel(ssd_sel)
    );

    // 125 MHz clock generation
    initial begin
        clk = 0;
        forever #4 clk = ~clk;
    end

    initial begin
        // Initialize Inputs
        sw = 4'b0001; // Assert reset
        btn = 4'b0000;

        // Wait 100 ns for global reset
        #100;
        sw = 4'b0000; // Release reset

        // Wait a bit, then press a button to start the game
        #500000; 
        
        // Note: Full game simulation takes millions of cycles because of the 10Hz game tick.
        // In a real testbench, you would speed up the game clock divider for simulation.
        
        $display("Simulation initialized. Game clock is very slow, so use Vivado GUI to force internal states if needed.");
        $finish;
    end

endmodule
