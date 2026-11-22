`timescale 1ns / 1ps

module tb_vga;

    reg clk_25M;
    reg rst;
    
    wire hsync;
    wire vsync;
    wire [9:0] x;
    wire [9:0] y;
    wire video_on;

    vga_controller uut (
        .clk_25M(clk_25M),
        .rst(rst),
        .hsync(hsync),
        .vsync(vsync),
        .x(x),
        .y(y),
        .video_on(video_on)
    );

    // 25 MHz clock
    initial begin
        clk_25M = 0;
        forever #20 clk_25M = ~clk_25M;
    end

    initial begin
        // Initialize
        rst = 1;
        #100;
        rst = 0;
        
        // Wait for a few lines to be drawn
        #50000;
        $finish;
    end

endmodule
