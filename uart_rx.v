`timescale 1ns / 1ps

// ============================================================================
// Module Name: uart_rx
// Description: Standard 8-N-1 UART Receiver module.
//              Converts serial UART bits received on rx_pin into byte output.
// Default Clock: 125 MHz (Zybo Z7 sys_clk)
// Default Baud Rate: 115200 bps
// CLKS_PER_BIT = 125,000,000 / 115,200 = 1085
// ============================================================================

module uart_rx #(
    parameter CLKS_PER_BIT = 1085
)(
    input        clk,          // System clock (125 MHz)
    input        rst,          // Active-high reset
    input        rx,           // Serial data input (UART RX line)
    output reg [7:0] rx_byte,  // Received 8-bit byte
    output reg   rx_valid      // 1-clock pulse when a byte is valid
);

    // States for State Machine
    localparam IDLE         = 3'b000;
    localparam RX_START_BIT = 3'b001; // wait for start bit mid-sample
    localparam RX_DATA_BITS = 3'b010;
    localparam RX_STOP_BIT  = 3'b011;
    localparam CLEANUP      = 3'b100;

    reg [2:0] state = IDLE;

    // Synchronize the asynchronous UART RX line to system clock (prevent metastability)
    reg rx_sync1;
    reg rx_sync2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    reg [15:0] clock_count = 0;
    reg [2:0]  bit_index   = 0;
    reg [7:0]  rx_data     = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            rx_valid    <= 1'b0;
            rx_byte     <= 8'h00;
            clock_count <= 0;
            bit_index   <= 0;
            rx_data     <= 8'h00;
        end else begin
            rx_valid <= 1'b0; // Default pulse low

            case (state)
                IDLE: begin
                    clock_count <= 0;
                    bit_index   <= 0;
                    // Detect Start Bit (Falling Edge: High to Low)
                    if (rx_sync2 == 1'b0) begin
                        state <= RX_START_BIT;
                    end
                end

                // Sample in the middle of the Start Bit to verify validity
                RX_START_BIT: begin
                    if (clock_count == ((CLKS_PER_BIT - 1) / 2)) begin
                        if (rx_sync2 == 1'b0) begin
                            clock_count <= 0; // Reset counter for data bits
                            state       <= RX_DATA_BITS;
                        end else begin
                            state       <= IDLE; // False start bit detected
                        end
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end

                // Sample 8 data bits at full bit period intervals
                RX_DATA_BITS: begin
                    if (clock_count < (CLKS_PER_BIT - 1)) begin
                        clock_count <= clock_count + 1'b1;
                    end else begin
                        clock_count          <= 0;
                        rx_data[bit_index]  <= rx_sync2;

                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1'b1;
                        end else begin
                            bit_index <= 0;
                            state     <= RX_STOP_BIT;
                        end
                    end
                end

                // Receive Stop Bit (should be High)
                RX_STOP_BIT: begin
                    if (clock_count < (CLKS_PER_BIT - 1)) begin
                        clock_count <= clock_count + 1'b1;
                    end else begin
                        rx_valid    <= 1'b1;
                        rx_byte     <= rx_data;
                        clock_count <= 0;
                        state       <= CLEANUP;
                    end
                end

                CLEANUP: begin
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
