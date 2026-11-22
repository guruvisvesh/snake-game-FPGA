`timescale 1ns / 1ps

module tb_collision;

    reg clk;
    reg [5:0] head_x;
    reg [5:0] head_y;
    reg [1:0] direction;
    reg [5:0] food_x;
    reg [5:0] food_y;
    reg dout_grid;
    
    wire [10:0] addr_grid_r;
    wire wall_collision;
    wire self_collision;
    wire food_collision;

    collision_detector uut (
        .clk(clk),
        .head_x(head_x),
        .head_y(head_y),
        .direction(direction),
        .food_x(food_x),
        .food_y(food_y),
        .dout_grid(dout_grid),
        .addr_grid_r(addr_grid_r),
        .wall_collision(wall_collision),
        .self_collision(self_collision),
        .food_collision(food_collision)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Test 1: No collision
        head_x = 20; head_y = 15; direction = 2'b11; // RIGHT
        food_x = 30; food_y = 20;
        dout_grid = 0;
        #20;
        
        // Test 2: Wall collision (moving right into wall)
        head_x = 38; direction = 2'b11;
        #20;
        
        // Test 3: Food collision (head on food)
        head_x = 30; head_y = 20; direction = 2'b00;
        #20;
        
        // Test 4: Self collision (next cell is 1)
        head_x = 20; head_y = 15; direction = 2'b11; // next cell will be 21, 15
        dout_grid = 1; // fake grid data response
        #20;

        $finish;
    end

endmodule
