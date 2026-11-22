`timescale 1ns / 1ps

module lfsr (
    input clk,
    input rst,
    output reg [15:0] rnd
);

    wire feedback;
    // Polynomial for 16-bit LFSR: x^16 + x^14 + x^13 + x^11 + 1
    // Taps at 16, 14, 13, 11 (0-indexed: 15, 13, 12, 10)
    assign feedback = rnd[15] ^ rnd[13] ^ rnd[12] ^ rnd[10];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rnd <= 16'hACE1; // Non-zero seed
        end else begin
            rnd <= {rnd[14:0], feedback};
        end
    end

endmodule
