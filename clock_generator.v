`timescale 1ns / 1ps

module clock_generator (
    input clk_100M,      // 100 MHz Basys 3 board clock (Pin W5)
    input rst,           // Active high reset
    output clk_25M,      // 25 MHz pixel clock for VGA / HDMI
    output clk_serial,   // 250 MHz serial clock (if HDMI used)
    output reg clk_game  // ~10 Hz game speed clock
);

    wire clkfb;
    wire clk_serial_unbuf;
    wire clk_pixel_unbuf;
    
    // Xilinx 7-Series MMCM for 100 MHz input clock
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT_F(10.0),  // 100 MHz * 10 = 1000 MHz VCO
        .CLKFBOUT_PHASE(0.0),
        .CLKIN1_PERIOD(10.0),    // 100 MHz input period (10ns)
        .CLKOUT0_DIVIDE_F(4.0),  // 1000 / 4 = 250 MHz (Serial Clock)
        .CLKOUT1_DIVIDE(40),     // 1000 / 40 = 25 MHz (Pixel Clock)
        .DIVCLK_DIVIDE(1)
    ) mmcm_inst (
        .CLKOUT0(clk_serial_unbuf),
        .CLKOUT1(clk_pixel_unbuf),
        .CLKFBOUT(clkfb),
        .CLKIN1(clk_100M),
        .PWRDWN(1'b0),
        .RST(rst),
        .CLKFBIN(clkfb)
    );
    
    BUFG buf_serial (.I(clk_serial_unbuf), .O(clk_serial));
    BUFG buf_pixel  (.I(clk_pixel_unbuf),  .O(clk_25M));

    // Divider for ~10 Hz Game Clock (from 100 MHz input)
    // 100,000,000 Hz / 10 Hz = 10,000,000 cycles. Toggle every 5,000,000.
    parameter GAME_DIV = 24'd4999999;
    
    reg [23:0] cnt_game;
    always @(posedge clk_100M or posedge rst) begin
        if (rst) begin
            cnt_game <= 0;
            clk_game <= 0;
        end else begin
            if (cnt_game == GAME_DIV) begin
                cnt_game <= 0;
                clk_game <= ~clk_game;
            end else begin
                cnt_game <= cnt_game + 1;
            end
        end
    end

endmodule
