`timescale 1ns / 1ps

// ============================================================================
// Basys 3 Input Controller
// Handles 5 digital push buttons on Basys 3 (Active HIGH: pressed = 1)
// BTNU (T18) = UP
// BTND (U17) = DOWN
// BTNL (W19) = LEFT
// BTNR (T17) = RIGHT
// BTNC (U18) = CENTER (RESET / START)
// ============================================================================

module input_controller (
    input clk,            // System clock (100 MHz)
    input rst,            // Active high reset (from BTNC or SW0)

    // Push Button Inputs on Basys 3 (Active High: pressed = 1)
    // btn[0] = UP (T18), btn[1] = DOWN (U17), btn[2] = LEFT (W19), btn[3] = RIGHT (T17)
    input [3:0] btn,

    // Synchronized output (for Game FSM)
    output btn_start,

    // Direction output (for Snake Controller)
    output reg [1:0] direction // 00: UP, 01: DOWN, 10: LEFT, 11: RIGHT
);

    // Direction Encoding
    parameter UP    = 2'b00;
    parameter DOWN  = 2'b01;
    parameter LEFT  = 2'b10;
    parameter RIGHT = 2'b11;

    // -------------------------------------------------------------------------
    // 1. Synchronizer for Push Buttons (Active HIGH on Basys 3)
    // -------------------------------------------------------------------------
    reg [3:0] sync1, sync2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync1 <= 4'b0000;
            sync2 <= 4'b0000;
        end else begin
            sync1 <= btn;
            sync2 <= sync1;
        end
    end

    // Active HIGH signals on Basys 3
    wire btn_up    = sync2[0]; // BTNU (T18)
    wire btn_down  = sync2[1]; // BTND (U17)
    wire btn_left  = sync2[2]; // BTNL (W19)
    wire btn_right = sync2[3]; // BTNR (T17)

    // -------------------------------------------------------------------------
    // 2. Edge Detection
    // -------------------------------------------------------------------------
    reg [3:0] btn_prev;
    wire btn_up_rise    = btn_up    & ~btn_prev[0];
    wire btn_down_rise  = btn_down  & ~btn_prev[1];
    wire btn_left_rise  = btn_left  & ~btn_prev[2];
    wire btn_right_rise = btn_right & ~btn_prev[3];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_prev <= 4'b0000;
        end else begin
            btn_prev <= {btn_right, btn_left, btn_down, btn_up};
        end
    end

    // -------------------------------------------------------------------------
    // 3. Game Start Trigger (Any direction button press starts game)
    // -------------------------------------------------------------------------
    wire any_button_press = btn_up_rise | btn_down_rise | btn_left_rise | btn_right_rise;

    reg any_button_prev;
    assign btn_start = any_button_press & ~any_button_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            any_button_prev <= 1'b0;
        end else begin
            any_button_prev <= any_button_press;
        end
    end

    // -------------------------------------------------------------------------
    // 4. Direction Logic (Prevents immediate 180-degree turn)
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            direction <= RIGHT;
        end else begin
            if (btn_up_rise && direction != DOWN)
                direction <= UP;
            else if (btn_down_rise && direction != UP)
                direction <= DOWN;
            else if (btn_left_rise && direction != RIGHT)
                direction <= LEFT;
            else if (btn_right_rise && direction != LEFT)
                direction <= RIGHT;
        end
    end

endmodule
