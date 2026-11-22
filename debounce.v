`timescale 1ns / 1ps

module debounce (
    input clk,      // 125 MHz system clock
    input btn_in,   // Bouncy button input
    output reg btn_out // Debounced button output
);

    reg [21:0] count;
    reg state;

    always @(posedge clk) begin
        if (btn_in != state) begin
            count <= count + 1;
            // 22'h3FFFFF is approx 4.19 million. 
            // At 125 MHz, 4.19M cycles is ~33.5 ms, which is perfect for debouncing.
            if (count == 22'h3FFFFF) begin 
                state <= btn_in;
                count <= 0;
            end
        end else begin
            count <= 0;
        end
    end

    always @(posedge clk) begin
        btn_out <= state;
    end

endmodule
