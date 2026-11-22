`timescale 1ns / 1ps

// ============================================================================
// Basys 3 On-board 4-Digit 7-Segment Display Driver
// Multiplexes BCD score onto 4-digit display (Active-LOW anodes & cathodes)
// ============================================================================

module basys3_ssd_driver (
    input clk,            // 100 MHz Basys 3 system clock
    input rst,            // Active high reset
    input [11:0] bcd,     // {Hundreds[3:0], Tens[3:0], Ones[3:0]}
    
    output reg [6:0] seg, // Segment cathodes {g,f,e,d,c,b,a} (Active LOW)
    output reg [3:0] an   // Digit anodes {an3, an2, an1, an0} (Active LOW)
);

    // Refresh Counter for 1 kHz Multiplexing (~250 Hz per digit)
    // 100 MHz / 100,000 = 1,000 Hz
    reg [16:0] mux_cnt = 0;
    reg [1:0]  digit_select = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mux_cnt      <= 0;
            digit_select <= 0;
        end else begin
            if (mux_cnt == 17'd99999) begin
                mux_cnt      <= 0;
                digit_select <= digit_select + 1'b1;
            end else begin
                mux_cnt <= mux_cnt + 1'b1;
            end
        end
    end

    // Select active BCD digit & activate anode
    reg [3:0] current_digit;

    always @(*) begin
        case (digit_select)
            2'b00: begin // Digit 0 (Rightmost - Ones)
                an = 4'b1110;
                current_digit = bcd[3:0];
            end
            2'b01: begin // Digit 1 (Tens)
                an = 4'b1101;
                current_digit = bcd[7:4];
            end
            2'b10: begin // Digit 2 (Hundreds)
                an = 4'b1011;
                current_digit = bcd[11:8];
            end
            2'b11: begin // Digit 3 (Thousands - Off / 0)
                an = 4'b0111;
                current_digit = 4'd0;
            end
        endcase
    end

    // BCD to Active-LOW 7-segment decoder
    // seg[6]=g, seg[5]=f, seg[4]=e, seg[3]=d, seg[2]=c, seg[1]=b, seg[0]=a
    always @(*) begin
        case (current_digit)
            //                    gfedcba (0 = segment ON, 1 = OFF)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0100010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0100000;
            default: seg = 7'b1111111;
        endcase
    end

endmodule
