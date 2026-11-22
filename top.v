`timescale 1ns / 1ps

// ============================================================================
// Top Level Module for Basys 3 Snake Game
// Inputs: 
//   - clk: 100 MHz oscillator (Pin W5)
//   - btn[3:0]: Direction buttons (BTNU=T18, BTND=U17, BTNL=W19, BTNR=T17)
//   - btnC: Center button for Reset (BTNC=U18)
// Outputs:
//   - vgaRed, vgaGreen, vgaBlue, Hsync, Vsync (Native Basys 3 VGA HD-15 port)
//   - seg[6:0], an[3:0] (Native Basys 3 4-digit 7-segment display)
// ============================================================================

module top (
    input clk,            // 100 MHz board clock (Pin W5)
    
    // 5 Direction & Reset Push Buttons / Switch on Basys 3
    input [3:0] btn,      // btn[0]=UP(T18), btn[1]=DOWN(U17), btn[2]=LEFT(W19), btn[3]=RIGHT(T17)
    input btnC,           // Reset switch (SW0 = Pin V17)
    
    // USB Keyboard (PS/2 interface via on-board PIC24 chip on Connector J2)
    input ps2_clk,        // Pin C17 (PULLUP)
    input ps2_data,       // Pin B17 (PULLUP)

    // Laptop USB-UART Receiver (Micro-USB Connector J4)
    input uart_rx,        // Pin B18
    
    // Basys 3 Onboard VGA Port Outputs (Unchanged)
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output Hsync,
    output Vsync,
    
    // Basys 3 Onboard 4-Digit 7-Segment Display
    output [6:0] seg,
    output [3:0] an
);

    wire rst = btnC;
    
    // ----------------------------------------------------
    // Clocks
    // ----------------------------------------------------
    wire clk_25M;
    wire clk_game;
    wire clk_serial;

    clock_generator clk_gen_inst (
        .clk_100M(clk),
        .rst(rst),
        .clk_25M(clk_25M),
        .clk_serial(clk_serial),
        .clk_game(clk_game)
    );

    // ----------------------------------------------------
    // USB Keyboard Decoder (PS/2 over USB-A Port J2)
    // ----------------------------------------------------
    wire kb_up, kb_down, kb_left, kb_right, kb_start;

    ps2_keyboard ps2_inst (
        .clk(clk),
        .rst(rst),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .kb_up(kb_up),
        .kb_down(kb_down),
        .kb_left(kb_left),
        .kb_right(kb_right),
        .kb_start(kb_start)
    );

    // ----------------------------------------------------
    // Laptop USB-UART Receiver (115200 baud on 100 MHz clock)
    // ----------------------------------------------------
    wire [7:0] uart_byte;
    wire uart_valid;

    uart_rx #(.CLKS_PER_BIT(868)) uart_inst (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .rx_byte(uart_byte),
        .rx_valid(uart_valid)
    );

    wire uart_up    = uart_valid && (uart_byte == "U" || uart_byte == "u" || uart_byte == "W" || uart_byte == "w");
    wire uart_down  = uart_valid && (uart_byte == "D" || uart_byte == "d" || uart_byte == "S" || uart_byte == "s");
    wire uart_left  = uart_valid && (uart_byte == "L" || uart_byte == "l" || uart_byte == "A" || uart_byte == "a");
    wire uart_right = uart_valid && (uart_byte == "R" || uart_byte == "r" || uart_byte == "D" || uart_byte == "d");
    wire uart_start = uart_valid && (uart_byte == " " || uart_byte == 8'h0D);

    // Combine all input sources (Onboard Buttons + USB Keyboard + Laptop UART)
    wire [3:0] combined_btn;
    assign combined_btn[0] = btn[0] | kb_up    | uart_up;
    assign combined_btn[1] = btn[1] | kb_down  | uart_down;
    assign combined_btn[2] = btn[2] | kb_left  | uart_left;
    assign combined_btn[3] = btn[3] | kb_right | uart_right;

    // ----------------------------------------------------
    // Input Controller (Edge Detection & Direction Logic)
    // ----------------------------------------------------
    wire [1:0] direction;
    wire btn_start_internal;
    wire btn_start = btn_start_internal | kb_start | uart_start;

    input_controller input_ctrl_inst (
        .clk(clk),
        .rst(rst),
        .btn(combined_btn),
        .btn_start(btn_start_internal),
        .direction(direction)
    );

    // ----------------------------------------------------
    // Game FSM
    // ----------------------------------------------------
    wire init_snake, move_snake, generate_food;
    wire [1:0] game_state;
    wire snake_ready, food_valid;
    wire wall_collision, self_collision, food_collision;
    
    game_fsm fsm_inst (
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

    // ----------------------------------------------------
    // Snake Memory
    // ----------------------------------------------------
    wire we_coord, we_grid;
    wire [10:0] addr_coord_w, addr_coord_r, addr_grid_w;
    wire [11:0] din_coord, dout_coord;
    wire din_grid;
    
    wire [10:0] addr_grid_r1;
    wire dout_grid1;
    wire [10:0] addr_grid_r2;
    wire dout_grid2;

    snake_memory memory_inst (
        .clk(clk),
        .we_coord(we_coord),
        .addr_coord_w(addr_coord_w),
        .din_coord(din_coord),
        .addr_coord_r(addr_coord_r),
        .dout_coord(dout_coord),
        
        .we_grid(we_grid),
        .addr_grid_w(addr_grid_w),
        .din_grid(din_grid),
        
        .addr_grid_r1(addr_grid_r1),
        .dout_grid1(dout_grid1),
        
        .addr_grid_r2(addr_grid_r2),
        .dout_grid2(dout_grid2)
    );

    // ----------------------------------------------------
    // Snake Controller
    // ----------------------------------------------------
    wire [5:0] head_x, head_y;
    wire [10:0] length;
    
    reg food_col_prev;
    wire food_eaten_pulse;
    always @(posedge clk) food_col_prev <= food_collision;
    assign food_eaten_pulse = (food_collision && !food_col_prev);

    snake_controller ctrl_inst (
        .clk(clk),
        .rst(rst),
        .init_snake(init_snake),
        .move_snake(move_snake),
        .direction(direction),
        .food_eaten(food_eaten_pulse),
        
        .we_coord(we_coord),
        .addr_coord_w(addr_coord_w),
        .din_coord(din_coord),
        .addr_coord_r(addr_coord_r),
        .dout_coord(dout_coord),
        
        .we_grid(we_grid),
        .addr_grid_w(addr_grid_w),
        .din_grid(din_grid),
        
        .head_x(head_x),
        .head_y(head_y),
        .length(length),
        .snake_ready(snake_ready)
    );

    // ----------------------------------------------------
    // Food Generator
    // ----------------------------------------------------
    wire [5:0] food_x, food_y;
    wire [10:0] food_gen_addr;
    
    food_generator food_inst (
        .clk(clk),
        .rst(rst),
        .generate_food(generate_food),
        .snake_ready(snake_ready),
        .addr_grid_r(food_gen_addr),
        .dout_grid(dout_grid2),
        .food_x(food_x),
        .food_y(food_y),
        .food_valid(food_valid)
    );

    // ----------------------------------------------------
    // Collision Detector
    // ----------------------------------------------------
    wire [10:0] collision_addr;
    
    collision_detector collision_inst (
        .clk(clk),
        .head_x(head_x),
        .head_y(head_y),
        .direction(direction),
        .food_x(food_x),
        .food_y(food_y),
        .dout_grid(dout_grid2),
        .addr_grid_r(collision_addr),
        .wall_collision(wall_collision),
        .self_collision(self_collision),
        .food_collision(food_collision)
    );

    // Multiplex Read Port 2
    assign addr_grid_r2 = (!food_valid || generate_food) ? food_gen_addr : collision_addr;

    // ----------------------------------------------------
    // VGA Controller & Pixel Renderer (Basys 3 Native VGA)
    // ----------------------------------------------------
    wire [9:0] x, y;
    wire video_on;
    wire [11:0] bcd_score;

    vga_controller vga_inst (
        .clk_25M(clk_25M),
        .rst(rst),
        .hsync(Hsync),
        .vsync(Vsync),
        .x(x),
        .y(y),
        .video_on(video_on)
    );

    pixel_renderer renderer_inst (
        .clk_25M(clk_25M),
        .video_on(video_on),
        .x(x),
        .y(y),
        .game_state(game_state),
        .food_x(food_x),
        .food_y(food_y),
        .food_valid(food_valid),
        .bcd_score(bcd_score),
        .addr_grid_r1(addr_grid_r1),
        .dout_grid1(dout_grid1),
        .vga_r(vgaRed),
        .vga_g(vgaGreen),
        .vga_b(vgaBlue)
    );

    // ----------------------------------------------------
    // Score Counter & Basys 3 7-Segment Display Driver
    // ----------------------------------------------------
    score_counter score_inst (
        .clk(clk),
        .rst(rst),
        .clear(init_snake),
        .increment(food_eaten_pulse),
        .bcd_score(bcd_score)
    );
    
    basys3_ssd_driver ssd_inst (
        .clk(clk),
        .rst(rst),
        .bcd(bcd_score),
        .seg(seg),
        .an(an)
    );

endmodule
