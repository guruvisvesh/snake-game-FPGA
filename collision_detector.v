`timescale 1ns / 1ps

module collision_detector (
    input clk,
    input [5:0] head_x,
    input [5:0] head_y,
    input [1:0] direction,
    input [5:0] food_x,
    input [5:0] food_y,
    
    // Grid RAM Interface
    input dout_grid,          // Read Port 2 data
    output reg [10:0] addr_grid_r, // Read Port 2 address
    
    // Collision Outputs
    output wall_collision,
    output self_collision,
    output food_collision
);

    reg [5:0] next_x, next_y;

    // Calculate where the head WILL be on the next move
    always @(*) begin
        case (direction)
            2'b00: begin next_x = head_x; next_y = head_y - 1; end // UP
            2'b01: begin next_x = head_x; next_y = head_y + 1; end // DOWN
            2'b10: begin next_x = head_x - 1; next_y = head_y; end // LEFT
            2'b11: begin next_x = head_x + 1; next_y = head_y; end // RIGHT
            default: begin next_x = head_x; next_y = head_y; end
        endcase
    end

    // Always fetch the grid data for the NEXT cell to check self-collision before moving
    always @(posedge clk) begin
        addr_grid_r <= {next_y[4:0], next_x};
    end

    // Wall collision is true if the NEXT cell is outside the 40x27 play area.
    // X goes from 1 to 38, Y from 1 to 25 (leaving a 1-cell border for the wall)
    assign wall_collision = (next_x == 0 || next_x >= 39 || next_y == 0 || next_y >= 26);

    // Self collision is true if the NEXT cell is a 1 in the grid (and not a wall to avoid false positives)
    assign self_collision = dout_grid && !wall_collision;

    // Food collision is true if the CURRENT head is on the food.
    // (Checked by snake_controller after it moves)
    assign food_collision = (head_x == food_x && head_y == food_y);

endmodule
