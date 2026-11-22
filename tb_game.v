`timescale 1ns / 1ps

module tb_game;

    reg clk;
    reg rst;
    reg clk_game;
    reg btn_start;
    reg wall_collision;
    reg self_collision;
    reg food_collision;
    reg snake_ready;
    reg food_valid;

    wire init_snake;
    wire move_snake;
    wire generate_food;
    wire [1:0] game_state;

    game_fsm uut (
        .clk(clk),
        .rst(rst),
        .clk_game(clk_game),
        .btn_start(btn_start),
        .wall_collision(wall_collision),
        .self_collision(self_collision),
        .food_collision(food_collision),
        .snake_ready(snake_ready),
        .food_valid(food_valid),
        .init_snake(init_snake),
        .move_snake(move_snake),
        .generate_food(generate_food),
        .game_state(game_state)
    );

    // 125 MHz clock
    initial begin
        clk = 0;
        forever #4 clk = ~clk;
    end

    // 10 Hz game clock (simulated fast)
    initial begin
        clk_game = 0;
        forever #100 clk_game = ~clk_game;
    end

    initial begin
        // Initialize Inputs
        rst = 1;
        btn_start = 0;
        wall_collision = 0;
        self_collision = 0;
        food_collision = 0;
        snake_ready = 0;
        food_valid = 0;

        #100;
        rst = 0;
        
        // Wait and start
        #150;
        btn_start = 1;
        #10;
        btn_start = 0;

        // Simulate snake initialization
        #50;
        snake_ready = 1;

        // Wait a few game ticks
        #500;
        
        // Simulate wall collision
        wall_collision = 1;
        #200;
        wall_collision = 0;

        $finish;
    end

endmodule
