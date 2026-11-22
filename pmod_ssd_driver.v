`timescale 1ns / 1ps

module pmod_ssd_driver (
    input clk,          // 125 MHz
    input rst,
    input [7:0] bcd,    // 2 digits: {Tens[3:0], Ones[3:0]} (Pmod SSD is 2 digits)
    
    // Outputs to Pmod SSD
    output reg [6:0] seg, // Segment data: {g,f,e,d,c,b,a}
    output reg sel        // Digit selection (0 = digit 1, 1 = digit 2)
);

    // Multiplexing clock divider
    // We want a refresh rate of ~1 kHz to 5 kHz to avoid flickering.
    // 125 MHz / 50,000 = 2,500 Hz (which means each digit refreshes at 1.25 kHz)
    reg [15:0] mux_cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mux_cnt <= 0;
            sel <= 0;
        end else begin
            if (mux_cnt == 16'd49999) begin
                mux_cnt <= 0;
                sel <= ~sel;
            end else begin
                mux_cnt <= mux_cnt + 1;
            end
        end
    end

    // Mux the data
    wire [3:0] current_bcd = sel ? bcd[7:4] : bcd[3:0];

    // BCD to 7-segment decoder
    // Pmod SSD has a common cathode configuration (1 turns segment ON, 0 turns it OFF)
    // Segments mapping: a=0, b=1, c=2, d=3, e=4, f=5, g=6
    always @(*) begin
        case (current_bcd)
            //                    gfedcba
            4'd0: seg = 7'b0111111;
            4'd1: seg = 7'b0000110;
            4'd2: seg = 7'b1011011;
            4'd3: seg = 7'b1001111;
            4'd4: seg = 7'b1100110;
            4'd5: seg = 7'b1101101;
            4'd6: seg = 7'b1111101;
            4'd7: seg = 7'b0000111;
            4'd8: seg = 7'b1111111;
            4'd9: seg = 7'b1101111;
            default: seg = 7'b0000000;
        endcase
    end

endmodule
