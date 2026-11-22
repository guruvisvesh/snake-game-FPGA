`timescale 1ns / 1ps

module snake_controller (
    input clk,
    input rst,
    input init_snake,        // Pulse to initialize snake
    input move_snake,        // Pulse to move snake by one step
    input [1:0] direction,   // 00:UP, 01:DOWN, 10:LEFT, 11:RIGHT
    input food_eaten,        // High if food was eaten this step
    
    // To snake_memory (Coordinate RAM)
    output reg we_coord,
    output reg [10:0] addr_coord_w,
    output reg [11:0] din_coord,
    output reg [10:0] addr_coord_r,
    input [11:0] dout_coord,

    // To snake_memory (Grid RAM)
    output reg we_grid,
    output reg [10:0] addr_grid_w,
    output reg din_grid,

    // Status outputs
    output reg [5:0] head_x,
    output reg [5:0] head_y,
    output reg [10:0] length,
    output reg snake_ready
);

    parameter UP = 2'b00, DOWN = 2'b01, LEFT = 2'b10, RIGHT = 2'b11;
    
    // FSM States
    parameter S_IDLE       = 4'd0;
    parameter S_CLEAR_GRID = 4'd1;
    parameter S_INIT1      = 4'd2;
    parameter S_INIT2      = 4'd3;
    parameter S_INIT3      = 4'd4;
    parameter S_MOVE_HEAD  = 4'd5;
    parameter S_WRITE_HEAD = 4'd6;
    parameter S_CHECK_FOOD = 4'd7;
    parameter S_READ_TAIL  = 4'd8;
    parameter S_CLEAR_TAIL = 4'd9;
    parameter S_DONE       = 4'd10;

    reg [3:0] state;
    reg [10:0] clear_idx;
    reg [10:0] head_ptr;
    reg [10:0] tail_ptr;
    reg [5:0] next_head_x;
    reg [5:0] next_head_y;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            clear_idx <= 0;
            head_ptr <= 0;
            tail_ptr <= 0;
            length <= 0;
            head_x <= 0;
            head_y <= 0;
            snake_ready <= 0;
            
            we_coord <= 0;
            we_grid <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    we_coord <= 0;
                    we_grid <= 0;
                    if (init_snake) begin
                        snake_ready <= 0;
                        clear_idx <= 0;
                        state <= S_CLEAR_GRID;
                    end else if (move_snake && snake_ready) begin
                        state <= S_MOVE_HEAD;
                    end
                end
                
                S_CLEAR_GRID: begin
                    we_grid <= 1;
                    addr_grid_w <= clear_idx;
                    din_grid <= 0;
                    if (clear_idx == 11'd2047) begin
                        state <= S_INIT1;
                    end else begin
                        clear_idx <= clear_idx + 1;
                    end
                end
                
                S_INIT1: begin
                    we_coord <= 1; addr_coord_w <= 0; din_coord <= {6'd15, 6'd18}; // Y=15, X=18
                    we_grid <= 1;  addr_grid_w <= {5'd15, 6'd18}; din_grid <= 1;
                    tail_ptr <= 0;
                    state <= S_INIT2;
                end
                
                S_INIT2: begin
                    we_coord <= 1; addr_coord_w <= 1; din_coord <= {6'd15, 6'd19}; // Y=15, X=19
                    we_grid <= 1;  addr_grid_w <= {5'd15, 6'd19}; din_grid <= 1;
                    state <= S_INIT3;
                end
                
                S_INIT3: begin
                    we_coord <= 1; addr_coord_w <= 2; din_coord <= {6'd15, 6'd20}; // Y=15, X=20
                    we_grid <= 1;  addr_grid_w <= {5'd15, 6'd20}; din_grid <= 1;
                    head_ptr <= 2;
                    head_x <= 20;
                    head_y <= 15;
                    length <= 3;
                    state <= S_DONE;
                end
                
                S_MOVE_HEAD: begin
                    case (direction)
                        UP:    begin next_head_x <= head_x; next_head_y <= head_y - 1; end
                        DOWN:  begin next_head_x <= head_x; next_head_y <= head_y + 1; end
                        LEFT:  begin next_head_x <= head_x - 1; next_head_y <= head_y; end
                        RIGHT: begin next_head_x <= head_x + 1; next_head_y <= head_y; end
                    endcase
                    state <= S_WRITE_HEAD;
                end
                
                S_WRITE_HEAD: begin
                    head_x <= next_head_x;
                    head_y <= next_head_y;
                    head_ptr <= head_ptr + 1;
                    
                    we_coord <= 1;
                    addr_coord_w <= head_ptr + 1;
                    din_coord <= {next_head_y, next_head_x};
                    
                    we_grid <= 1;
                    addr_grid_w <= {next_head_y[4:0], next_head_x};
                    din_grid <= 1;
                    
                    state <= S_CHECK_FOOD;
                end
                
                S_CHECK_FOOD: begin
                    we_coord <= 0;
                    we_grid <= 0;
                    if (food_eaten) begin
                        length <= length + 1;
                        state <= S_DONE;
                    end else begin
                        addr_coord_r <= tail_ptr;
                        state <= S_READ_TAIL;
                    end
                end
                
                S_READ_TAIL: begin
                    // 1 cycle for BRAM read to complete
                    state <= S_CLEAR_TAIL;
                end
                
                S_CLEAR_TAIL: begin
                    we_grid <= 1;
                    // dout_coord is {Y[5:0], X[5:0]}. Grid address needs {Y[4:0], X[5:0]}
                    addr_grid_w <= {dout_coord[10:6], dout_coord[5:0]};
                    din_grid <= 0;
                    tail_ptr <= tail_ptr + 1;
                    state <= S_DONE;
                end
                
                S_DONE: begin
                    we_grid <= 0;
                    we_coord <= 0;
                    snake_ready <= 1;
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
