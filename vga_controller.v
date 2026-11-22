`timescale 1ns / 1ps

module vga_controller(
    input clk_25M,      // 25 MHz pixel clock
    input rst,          // Active high reset
    output reg hsync,   // Horizontal sync
    output reg vsync,   // Vertical sync
    output reg [9:0] x, // Current X coordinate
    output reg [9:0] y, // Current Y coordinate
    output video_on     // High when in active display area
);

    // Standard 640x480@60Hz timing parameters
    parameter H_DISPLAY = 640;
    parameter H_FRONT   = 16;
    parameter H_SYNC    = 96;
    parameter H_BACK    = 48;
    parameter H_TOTAL   = 800;

    parameter V_DISPLAY = 480;
    parameter V_FRONT   = 10;
    parameter V_SYNC    = 2;
    parameter V_BACK    = 33;
    parameter V_TOTAL   = 525;

    reg [9:0] h_cnt;
    reg [9:0] v_cnt;

    // Horizontal and Vertical Counters
    always @(posedge clk_25M or posedge rst) begin
        if (rst) begin
            h_cnt <= 0;
            v_cnt <= 0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 0;
                if (v_cnt == V_TOTAL - 1) begin
                    v_cnt <= 0;
                end else begin
                    v_cnt <= v_cnt + 1;
                end
            end else begin
                h_cnt <= h_cnt + 1;
            end
        end
    end

    // Sync Signals (Active Low for 640x480)
    always @(posedge clk_25M or posedge rst) begin
        if (rst) begin
            hsync <= 0;
            vsync <= 0;
        end else begin
            hsync <= ~(h_cnt >= (H_DISPLAY + H_FRONT) && h_cnt < (H_DISPLAY + H_FRONT + H_SYNC));
            vsync <= ~(v_cnt >= (V_DISPLAY + V_FRONT) && v_cnt < (V_DISPLAY + V_FRONT + V_SYNC));
        end
    end

    // Coordinates mapping
    always @(posedge clk_25M or posedge rst) begin
        if (rst) begin
            x <= 0;
            y <= 0;
        end else begin
            x <= (h_cnt < H_DISPLAY) ? h_cnt : 10'd0;
            y <= (v_cnt < V_DISPLAY) ? v_cnt : 10'd0;
        end
    end

    // Active Display Indicator
    assign video_on = (h_cnt < H_DISPLAY) && (v_cnt < V_DISPLAY);

endmodule
