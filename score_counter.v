`timescale 1ns / 1ps

module score_counter (
    input clk,
    input rst,
    input clear,        // synchronous clear (e.g. game restart)
    input increment,    // pulse to increment score
    output reg [11:0] bcd_score // 3 digits: {Hundreds[3:0], Tens[3:0], Ones[3:0]}
);

    reg [3:0] ones, tens, hundreds;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ones <= 0;
            tens <= 0;
            hundreds <= 0;
        end else if (clear) begin
            ones <= 0;
            tens <= 0;
            hundreds <= 0;
        end else if (increment) begin
            if (ones == 4'd9) begin
                ones <= 0;
                if (tens == 4'd9) begin
                    tens <= 0;
                    if (hundreds == 4'd9) begin
                        hundreds <= 0; // wrap around
                    end else begin
                        hundreds <= hundreds + 1;
                    end
                end else begin
                    tens <= tens + 1;
                end
            end else begin
                ones <= ones + 1;
            end
        end
    end

    always @(*) begin
        bcd_score = {hundreds, tens, ones};
    end

endmodule
