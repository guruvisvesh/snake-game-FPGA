`timescale 1ns / 1ps

module food_generator (
    input clk,
    input rst,
    input generate_food,     // Pulse to generate new food
    input snake_ready,       // Only generate if snake initialization is done
    
    // Interface to snake_memory (Grid RAM)
    output reg [10:0] addr_grid_r,
    input dout_grid,
    
    // Outputs
    output reg [5:0] food_x,
    output reg [5:0] food_y,
    output reg food_valid
);

    wire [15:0] random_val;
    
    lfsr random_gen (
        .clk(clk),
        .rst(rst),
        .rnd(random_val)
    );

    parameter S_IDLE     = 0;
    parameter S_REROLL   = 1;
    parameter S_CHECK    = 2;
    parameter S_EVALUATE = 3;

    reg [1:0] state;
    reg [5:0] test_x;
    reg [5:0] test_y;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            food_valid <= 0;
            food_x <= 20; // Default safe position
            food_y <= 10;
        end else begin
            case (state)
                S_IDLE: begin
                    if (generate_food && snake_ready) begin
                        food_valid <= 0;
                        state <= S_REROLL;
                    end
                end
                
                S_REROLL: begin
                    // Extract 6 bits for X and Y
                    test_x = random_val[5:0];
                    test_y = random_val[11:6];
                    
                    // Keep values within 40x27 grid boundaries (1 to max-1 to avoid walls)
                    if (test_x > 0 && test_x < 39 && test_y > 0 && test_y < 26) begin
                        addr_grid_r <= {test_y[4:0], test_x};
                        state <= S_CHECK;
                    end
                    // Else remain in S_REROLL for next random value
                end
                
                S_CHECK: begin
                    // 1 cycle wait for BRAM read
                    state <= S_EVALUATE;
                end
                
                S_EVALUATE: begin
                    if (dout_grid == 1'b1) begin
                        // Food spawned on the snake! Try again.
                        state <= S_REROLL;
                    end else begin
                        // Valid food position
                        food_x <= test_x;
                        food_y <= test_y;
                        food_valid <= 1;
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
