`timescale 1ns / 1ps

module game_fsm (
    input clk,
    input rst,
    input clk_game,          // 10 Hz game clock
    input btn_start,         // Debounced start button
    
    input wall_collision,
    input self_collision,
    input food_collision,
    input snake_ready,
    input food_valid,

    output reg init_snake,
    output reg move_snake,
    output reg generate_food,
    output reg [1:0] game_state // 00: START, 01: INIT_WAIT, 10: PLAYING, 11: GAME_OVER
);

    parameter ST_START     = 2'b00;
    parameter ST_INIT_WAIT = 2'b01;
    parameter ST_PLAYING   = 2'b10;
    parameter ST_GAME_OVER = 2'b11;

    // Edge detector for game clock (1-cycle pulse)
    reg clk_game_prev;
    wire game_tick;
    always @(posedge clk) begin
        clk_game_prev <= clk_game;
    end
    assign game_tick = (clk_game && !clk_game_prev);

    // Edge detector for start button
    reg btn_start_prev;
    wire btn_start_press;
    always @(posedge clk) begin
        btn_start_prev <= btn_start;
    end
    assign btn_start_press = (btn_start && !btn_start_prev);

    // Edge detector for food collision
    reg food_collision_prev;
    wire food_eaten_pulse;
    always @(posedge clk) begin
        food_collision_prev <= food_collision;
    end
    assign food_eaten_pulse = (food_collision && !food_collision_prev);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            game_state <= ST_START;
            init_snake <= 0;
            move_snake <= 0;
            generate_food <= 0;
        end else begin
            // Default single-cycle pulses
            init_snake <= 0;
            move_snake <= 0;
            generate_food <= 0;
            
            // Generate food asynchronously when eaten during gameplay
            if (food_eaten_pulse && game_state == ST_PLAYING) begin
                generate_food <= 1;
            end

            case (game_state)
                ST_START: begin
                    if (btn_start_press) begin
                        init_snake <= 1;
                        game_state <= ST_INIT_WAIT;
                    end
                end
                
                ST_INIT_WAIT: begin
                    // Wait for snake_controller to finish clearing RAM and initializing
                    // snake_ready might be high for 1 cycle before controller drops it,
                    // so we make sure we don't transition if init_snake was just asserted.
                    // Added timeout to prevent getting stuck
                    if (snake_ready) begin
                        generate_food <= 1;
                        game_state <= ST_PLAYING;
                    end
                end
                
                ST_PLAYING: begin
                    if (game_tick) begin
                        if (wall_collision || self_collision) begin
                            game_state <= ST_GAME_OVER;
                        end else begin
                            move_snake <= 1;
                        end
                    end
                end
                
                ST_GAME_OVER: begin
                    if (btn_start_press) begin
                        game_state <= ST_START;
                    end
                end
            endcase
        end
    end

endmodule
