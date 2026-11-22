`timescale 1ns / 1ps

module hdmi_tx (
    input clk_pixel,   // 25 MHz
    input clk_serial,  // 250 MHz
    input rst,
    
    input [7:0] red,
    input [7:0] green,
    input [7:0] blue,
    input hsync,
    input vsync,
    input vde,
    
    output hdmi_tx_clk_p,
    output hdmi_tx_clk_n,
    output [2:0] hdmi_tx_d_p,
    output [2:0] hdmi_tx_d_n
);

    wire [9:0] tmds_red, tmds_green, tmds_blue;
    
    // TMDS Encoders
    // Blue channel carries HSYNC and VSYNC
    tmds_encoder enc_b (.clk(clk_pixel), .VD(blue),  .CD({vsync, hsync}), .VDE(vde), .TMDS(tmds_blue));
    tmds_encoder enc_g (.clk(clk_pixel), .VD(green), .CD(2'b00),          .VDE(vde), .TMDS(tmds_green));
    tmds_encoder enc_r (.clk(clk_pixel), .VD(red),   .CD(2'b00),          .VDE(vde), .TMDS(tmds_red));
    
    // ----------------------------------------------------
    // SDR 10:1 Serializer (250 MHz)
    // ----------------------------------------------------
    reg [3:0] bit_cnt = 0;
    always @(posedge clk_serial) begin
        if (bit_cnt == 9) bit_cnt <= 0;
        else bit_cnt <= bit_cnt + 1;
    end
    
    reg [9:0] shift_r, shift_g, shift_b;
    always @(posedge clk_serial) begin
        if (bit_cnt == 9) begin
            shift_r <= tmds_red;
            shift_g <= tmds_green;
            shift_b <= tmds_blue;
        end else begin
            // TMDS sends LSB first
            shift_r <= {1'b0, shift_r[9:1]};
            shift_g <= {1'b0, shift_g[9:1]};
            shift_b <= {1'b0, shift_b[9:1]};
        end
    end
    
    // Clock channel sends a constant 1111100000 pattern
    // (Sending LSB first means it transmits 00000 followed by 11111)
    reg [9:0] shift_clk;
    always @(posedge clk_serial) begin
        if (bit_cnt == 9) shift_clk <= 10'b1111100000;
        else shift_clk <= {1'b0, shift_clk[9:1]};
    end
    
    // ----------------------------------------------------
    // Differential Buffers (OBUFDS)
    // ----------------------------------------------------
    OBUFDS obuf_r   (.I(shift_r[0]),   .O(hdmi_tx_d_p[2]), .OB(hdmi_tx_d_n[2]));
    OBUFDS obuf_g   (.I(shift_g[0]),   .O(hdmi_tx_d_p[1]), .OB(hdmi_tx_d_n[1]));
    OBUFDS obuf_b   (.I(shift_b[0]),   .O(hdmi_tx_d_p[0]), .OB(hdmi_tx_d_n[0]));
    OBUFDS obuf_clk (.I(shift_clk[0]), .O(hdmi_tx_clk_p),  .OB(hdmi_tx_clk_n));

endmodule
