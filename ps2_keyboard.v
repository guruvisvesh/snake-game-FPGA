`timescale 1ns / 1ps

// ============================================================================
// Module Name: ps2_keyboard
// Target: Digilent Basys 3 (Artix-7 XC7A35T)
// Description: Decodes PS/2 keyboard signals coming from the onboard PIC24
//              microcontroller (USB HID Host on Connector J2).
//
// Pin Mapping on Basys 3:
//   ps2_clk  = Pin C17 (PULLUP true)
//   ps2_data = Pin B17 (PULLUP true)
//
// Key Mappings (Make Codes):
//   W          : 8'h1D  -> kb_up
//   S          : 8'h1B  -> kb_down
//   A          : 8'h1C  -> kb_left
//   D          : 8'h23  -> kb_right
//   Up Arrow   : 8'h75  -> kb_up
//   Down Arrow : 8'h72  -> kb_down
//   Left Arrow : 8'h6B  -> kb_left
//   Right Arrow: 8'h74  -> kb_right
//   Spacebar   : 8'h29  -> kb_start
//   Enter      : 8'h5A  -> kb_start
// ============================================================================

module ps2_keyboard (
    input clk,            // 100 MHz system clock
    input rst,            // Active high reset
    input ps2_clk,        // PS/2 clock from pin C17
    input ps2_data,       // PS/2 data from pin B17

    output reg kb_up,
    output reg kb_down,
    output reg kb_left,
    output reg kb_right,
    output reg kb_start
);

    // ------------------------------------------------------------------------
    // 1. Debounce and synchronize PS/2 Clock and Data
    // ------------------------------------------------------------------------
    reg [7:0] clk_filter = 8'hFF;
    reg ps2_clk_clean = 1'b1;

    reg data_sync1 = 1'b1, data_sync2 = 1'b1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_filter    <= 8'hFF;
            ps2_clk_clean <= 1'b1;
            data_sync1    <= 1'b1;
            data_sync2    <= 1'b1;
        end else begin
            clk_filter <= {clk_filter[6:0], ps2_clk};
            if (clk_filter == 8'h00)
                ps2_clk_clean <= 1'b0;
            else if (clk_filter == 8'hFF)
                ps2_clk_clean <= 1'b1;

            data_sync1 <= ps2_data;
            data_sync2 <= data_sync1;
        end
    end

    // Falling edge detector on clean PS/2 clock
    reg ps2_clk_prev = 1'b1;
    wire ps2_clk_fall = (ps2_clk_prev == 1'b1 && ps2_clk_clean == 1'b0);

    always @(posedge clk or posedge rst) begin
        if (rst) ps2_clk_prev <= 1'b1;
        else     ps2_clk_prev <= ps2_clk_clean;
    end

    // ------------------------------------------------------------------------
    // 2. 11-Bit Frame Shift Register
    // Frame format: 1 Start bit (0), 8 Data bits (LSB first), 1 Parity, 1 Stop (1)
    // ------------------------------------------------------------------------
    reg [3:0] bit_cnt = 4'd0;
    reg [10:0] shift_reg = 11'd0;
    reg scancode_ready = 1'b0;
    reg [7:0] scancode = 8'h00;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_cnt        <= 4'd0;
            shift_reg      <= 11'd0;
            scancode_ready <= 1'b0;
            scancode       <= 8'h00;
        end else begin
            scancode_ready <= 1'b0;

            if (ps2_clk_fall) begin
                shift_reg <= {data_sync2, shift_reg[10:1]};

                if (bit_cnt == 4'd10) begin
                    bit_cnt        <= 4'd0;
                    scancode       <= shift_reg[9:2]; // Extract 8 data bits
                    scancode_ready <= 1'b1;
                end else begin
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // 3. Scan Code Decoder (Make vs Break Code)
    // Break code is preceded by 8'hF0
    // ------------------------------------------------------------------------
    reg is_break = 1'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            is_break <= 1'b0;
            kb_up    <= 1'b0;
            kb_down  <= 1'b0;
            kb_left  <= 1'b0;
            kb_right <= 1'b0;
            kb_start <= 1'b0;
        end else begin
            // Default pulse to 0
            kb_up    <= 1'b0;
            kb_down  <= 1'b0;
            kb_left  <= 1'b0;
            kb_right <= 1'b0;
            kb_start <= 1'b0;

            if (scancode_ready) begin
                if (scancode == 8'hF0) begin
                    is_break <= 1'b1; // Next scancode is release
                end else if (scancode == 8'hE0) begin
                    // Extended key prefix, ignore and wait for actual key
                end else begin
                    if (!is_break) begin
                        // Key Press (Make code)
                        case (scancode)
                            8'h1D, 8'h75: kb_up    <= 1'b1; // W or Up Arrow
                            8'h1B, 8'h72: kb_down  <= 1'b1; // S or Down Arrow
                            8'h1C, 8'h6B: kb_left  <= 1'b1; // A or Left Arrow
                            8'h23, 8'h74: kb_right <= 1'b1; // D or Right Arrow
                            8'h29, 8'h5A: kb_start <= 1'b1; // Spacebar or Enter
                            default: ;
                        endcase
                    end
                    is_break <= 1'b0;
                end
            end
        end
    end

endmodule
