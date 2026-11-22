`timescale 1ns / 1ps

module tmds_encoder (
    input clk,
    input [7:0] VD,  // Video Data (8-bit color channel)
    input [1:0] CD,  // Control Data (HSYNC/VSYNC)
    input VDE,       // Video Data Enable
    output reg [9:0] TMDS
);

    wire [3:0] Nb1s = VD[0] + VD[1] + VD[2] + VD[3] + VD[4] + VD[5] + VD[6] + VD[7];
    wire XNOR = (Nb1s > 4) || (Nb1s == 4 && VD[0] == 0);

    wire [8:0] q_m;
    assign q_m[0] = VD[0];
    assign q_m[1] = q_m[0] ^ VD[1] ^ XNOR;
    assign q_m[2] = q_m[1] ^ VD[2] ^ XNOR;
    assign q_m[3] = q_m[2] ^ VD[3] ^ XNOR;
    assign q_m[4] = q_m[3] ^ VD[4] ^ XNOR;
    assign q_m[5] = q_m[4] ^ VD[5] ^ XNOR;
    assign q_m[6] = q_m[5] ^ VD[6] ^ XNOR;
    assign q_m[7] = q_m[6] ^ VD[7] ^ XNOR;
    assign q_m[8] = ~XNOR;

    reg [3:0] disparity = 0;
    wire [3:0] q_m_Nb1s = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
    wire [3:0] q_m_Nb0s = 8 - q_m_Nb1s;

    always @(posedge clk) begin
        if (!VDE) begin
            case (CD)
                2'b00: TMDS <= 10'b1101010100;
                2'b01: TMDS <= 10'b0010101011;
                2'b10: TMDS <= 10'b0101010100;
                2'b11: TMDS <= 10'b1010101011;
            endcase
            disparity <= 0;
        end else begin
            if (disparity == 0 || q_m_Nb1s == 4) begin
                TMDS[9] <= ~q_m[8];
                TMDS[8] <= q_m[8];
                TMDS[7:0] <= q_m[8] ? q_m[7:0] : ~q_m[7:0];
                if (q_m[8])
                    disparity <= disparity + q_m_Nb1s - q_m_Nb0s;
                else
                    disparity <= disparity + q_m_Nb0s - q_m_Nb1s;
            end else begin
                if ((!disparity[3] && q_m_Nb1s > 4) || (disparity[3] && q_m_Nb1s < 4)) begin
                    TMDS[9] <= 1;
                    TMDS[8] <= q_m[8];
                    TMDS[7:0] <= ~q_m[7:0];
                    disparity <= disparity + q_m_Nb0s - q_m_Nb1s + (q_m[8] ? 2 : 0);
                end else begin
                    TMDS[9] <= 0;
                    TMDS[8] <= q_m[8];
                    TMDS[7:0] <= q_m[7:0];
                    disparity <= disparity + q_m_Nb1s - q_m_Nb0s - (q_m[8] ? 0 : 2);
                end
            end
        end
    end
endmodule
