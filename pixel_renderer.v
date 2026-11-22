`timescale 1ns / 1ps

module pixel_renderer (
    input clk_25M,
    input video_on,
    input [9:0] x,
    input [9:0] y,
    
    input [1:0] game_state,
    input [5:0] food_x,
    input [5:0] food_y,
    input food_valid,
    
    // Score input (BCD format: [11:8]=hundreds, [7:4]=tens, [3:0]=ones)
    input [11:0] bcd_score,
    
    // Grid RAM Interface
    output reg [10:0] addr_grid_r1,
    input dout_grid1,
    
    // RGB Outputs (4 bits per channel for Zybo Z7)
    output reg [3:0] vga_r,
    output reg [3:0] vga_g,
    output reg [3:0] vga_b
);

    // -------------------------------------------------------
    // Pipeline registers for 1-cycle RAM latency
    // -------------------------------------------------------
    reg video_on_del;
    reg [9:0] x_del, y_del;
    
    wire [5:0] cell_x = x[9:4];
    wire [5:0] cell_y = y[9:4];

    always @(posedge clk_25M) begin
        addr_grid_r1 <= {cell_y[4:0], cell_x};
        x_del        <= x;
        y_del        <= y;
        video_on_del <= video_on;
    end

    wire [5:0] current_cell_x = x_del[9:4];
    wire [5:0] current_cell_y = y_del[9:4];
    
    // -------------------------------------------------------
    // Game Area Bounds  (40 x 27 grid, rows 0-26 = pixels 0-431)
    // Score Area occupies pixel rows 432-479 (y_del >= 432)
    // Game cells are 16x16 pixels: cell_x = x[9:4], cell_y = y[9:4]
    // Game boundary: cell_x = 0-39, cell_y = 0-26 (bottom wall at row 26)
    // -------------------------------------------------------
    wire is_game_area  = (y_del < 10'd432);
    wire is_score_area = (y_del >= 10'd432);
    
    // Game boundary: 40 columns (0-39), 27 rows (0-26)
    // Bottom wall is at row 26 (y = 416-431)
    wire is_wall  = is_game_area &&
                    (current_cell_x == 6'd0 || current_cell_x == 6'd39 ||
                     current_cell_y == 6'd0 || current_cell_y == 6'd26);
    wire is_food  = is_game_area && (current_cell_x == food_x && current_cell_y == food_y && food_valid);
    wire is_snake = is_game_area && dout_grid1;
    
    wire is_border = (x_del[3:0] == 4'h0 || x_del[3:0] == 4'hF ||
                      y_del[3:0] == 4'h0 || y_del[3:0] == 4'hF);

    // -------------------------------------------------------
    // Score Display with Small Bitmap Font
    // Score area: Y = 432 to 479 (48 pixels tall)
    // Center the score text horizontally: "SCORE: XXX"
    // Use 8x8 bitmap font with 2x scaling (16x16 pixels per character)
    // -------------------------------------------------------
    
    // Score area local coordinates
    wire [5:0] score_y = y_del - 10'd432; // 0-47
    wire [9:0] score_x = x_del;          // 0-639
    
    // Center the text horizontally & vertically
    // "SCORE: XXX" = 6 chars + colon + space + 3 digits = 11 chars
    // Each char is 16x16 pixels (8x8 font with 2x scaling)
    // Horizontal width = 11 * 16 = 176 pixels -> Start x = (640 - 176) / 2 = 232
    // Vertical height = 16 pixels in 48px bar -> Start y = (48 - 16) / 2 = 16
    wire [9:0] text_start_x = 10'd232;
    wire [5:0] text_start_y = 6'd16;
    
    wire in_score_text = is_score_area && 
                         (score_x >= text_start_x && score_x < (text_start_x + 10'd176)) &&
                         (score_y >= text_start_y && score_y < (text_start_y + 6'd16));
    
    // Character index (0-10): S,C,O,R,E,: ,X,X,X
    wire [3:0] char_idx = (score_x - text_start_x) >> 4; // Divide by 16
    wire [3:0] char_x   = (score_x - text_start_x) & 4'hF; // 0-15 within character
    wire [3:0] char_y   = (score_y - text_start_y);        // 0-15 within character (2x scaled 8x8 font)
    
    // Font pixel coordinates (8x8 original)
    wire [2:0] font_x = char_x[3:1]; // 0-7 (scaled by 2)
    wire [2:0] font_y = char_y[3:1]; // 0-7 (scaled by 2)
    
    // Which digit to display (if char_idx >= 7)
    reg [3:0] digit_char;
    always @(*) begin
        case (char_idx)
            4'd7: digit_char = bcd_score[11:8];  // Hundreds
            4'd8: digit_char = bcd_score[7:4];   // Tens
            4'd9: digit_char = bcd_score[3:0];   // Ones
            default: digit_char = 4'h0;
        endcase
    end
    
    // 8x8 bitmap font patterns (1 = pixel on)
    // Characters: S, C, O, R, E, :, space, 0-9
    reg [7:0] font_pixel;
    always @(*) begin
        case (char_idx)
            0: begin // S
                case (font_y)
                    0: font_pixel = 8'b01111100;
                    1: font_pixel = 8'b11000011;
                    2: font_pixel = 8'b11000000;
                    3: font_pixel = 8'b01111100;
                    4: font_pixel = 8'b00000011;
                    5: font_pixel = 8'b11000011;
                    6: font_pixel = 8'b01111100;
                    7: font_pixel = 8'b00000000;
                endcase
            end
            1: begin // C
                case (font_y)
                    0: font_pixel = 8'b01111100;
                    1: font_pixel = 8'b11000011;
                    2: font_pixel = 8'b11000000;
                    3: font_pixel = 8'b11000000;
                    4: font_pixel = 8'b11000000;
                    5: font_pixel = 8'b11000011;
                    6: font_pixel = 8'b01111100;
                    7: font_pixel = 8'b00000000;
                endcase
            end
            2: begin // O
                case (font_y)
                    0: font_pixel = 8'b01111100;
                    1: font_pixel = 8'b11000011;
                    2: font_pixel = 8'b11000011;
                    3: font_pixel = 8'b11000011;
                    4: font_pixel = 8'b11000011;
                    5: font_pixel = 8'b11000011;
                    6: font_pixel = 8'b01111100;
                    7: font_pixel = 8'b00000000;
                endcase
            end
            3: begin // R
                case (font_y)
                    0: font_pixel = 8'b01111100;
                    1: font_pixel = 8'b11000011;
                    2: font_pixel = 8'b11000011;
                    3: font_pixel = 8'b01111100;
                    4: font_pixel = 8'b11000110;
                    5: font_pixel = 8'b11000011;
                    6: font_pixel = 8'b11000001;
                    7: font_pixel = 8'b00000000;
                endcase
            end
            4: begin // E
                case (font_y)
                    0: font_pixel = 8'b01111110;
                    1: font_pixel = 8'b11000000;
                    2: font_pixel = 8'b11000000;
                    3: font_pixel = 8'b01111100;
                    4: font_pixel = 8'b11000000;
                    5: font_pixel = 8'b11000000;
                    6: font_pixel = 8'b01111110;
                    7: font_pixel = 8'b00000000;
                endcase
            end
            5: begin // :
                case (font_y)
                    0: font_pixel = 8'b00000000;
                    1: font_pixel = 8'b00110000;
                    2: font_pixel = 8'b00110000;
                    3: font_pixel = 8'b00000000;
                    4: font_pixel = 8'b00110000;
                    5: font_pixel = 8'b00110000;
                    6: font_pixel = 8'b00000000;
                    7: font_pixel = 8'b00000000;
                endcase
            end
            6: begin // space
                font_pixel = 8'b00000000;
            end
            7,8,9: begin // 0-9
                case (digit_char)
                    0: begin // 0
                        case (font_y)
                            0: font_pixel = 8'b01111100;
                            1: font_pixel = 8'b11000110;
                            2: font_pixel = 8'b11001110;
                            3: font_pixel = 8'b11010110;
                            4: font_pixel = 8'b11110110;
                            5: font_pixel = 8'b11000110;
                            6: font_pixel = 8'b01111100;
                            7: font_pixel = 8'b00000000;
                        endcase
                    end
                    1: begin // 1
                        case (font_y)
                            0: font_pixel = 8'b00011000;
                            1: font_pixel = 8'b00111000;
                            2: font_pixel = 8'b00011000;
                            3: font_pixel = 8'b00011000;
                            4: font_pixel = 8'b00011000;
                            5: font_pixel = 8'b00011000;
                            6: font_pixel = 8'b00111100;
                            7: font_pixel = 8'b00000000;
                        endcase
                    end
                    2: begin // 2
                        case (font_y)
                            0: font_pixel = 8'b01111100;
                            1: font_pixel = 8'b11000110;
                            2: font_pixel = 8'b00001110;
                            3: font_pixel = 8'b00011100;
                            4: font_pixel = 8'b00111000;
                            5: font_pixel = 8'b01100000;
                            6: font_pixel = 8'b11111110;
                            7: font_pixel = 8'b00000000;
                        endcase
                    end
                    3: begin // 3
                        case (font_y)
                            0: font_pixel = 8'b01111100;
                            1: font_pixel = 8'b11000110;
                            2: font_pixel = 8'b00001110;
                            3: font_pixel = 8'b00011100;
                            4: font_pixel = 8'b00001110;
                            5: font_pixel = 8'b11000110;
                            6: font_pixel = 8'b01111100;
                            7: font_pixel = 8'b00000000;
                        endcase
                    end
                    4: begin // 4
                        case (font_y)
                            0: font_pixel = 8'b00001100;
                            1: font_pixel = 8'b00011100;
                            2: font_pixel = 8'b00101100;
                            3: font_pixel = 8'b01101100;
                            4: font_pixel = 8'b11111110;
                            5: font_pixel = 8'b00001100;
                            6: font_pixel = 8'b00001100;
                            7: font_pixel = 8'b00000000;
                        endcase
                    end
                    5: begin // 5
                        case (font_y)
                            0: font_pixel = 8'b11111110;
                            1: font_pixel = 8'b11000000;
                            2: font_pixel = 8'b11111100;
                            3: font_pixel = 8'b00001110;
                            4: font_pixel = 8'b00001110;
                            5: font_pixel = 8'b11000110;
                            6: font_pixel = 8'b01111100;
                            7: font_pixel = 8'b00000000;
                        endcase
                    end
                    6: begin // 6
                        case (font_y)
                            0: font_pixel = 8'b01111100;
                            1: font_pixel = 8'b11000000;
                            2: font_pixel = 8'b11111100;
                            3: font_pixel = 8'b11000110;
                            4: font_pixel = 8'b11000110;
                            5: font_pixel = 8'b11000110;
                            6: font_pixel = 8'b01111100;
                            7: font_pixel = 8'b00000000;
                        endcase
                    end
                    7: begin // 7
                        case (font_y)
                            0: font_pixel = 8'b11111110;
                            1: font_pixel = 8'b00000110;
                            2: font_pixel = 8'b00001100;
                            3: font_pixel = 8'b00011000;
                            4: font_pixel = 8'b00011000;
                            5: font_pixel = 8'b00011000;
                            6: font_pixel = 8'b00011000;
                            7: font_pixel = 8'b00000000;
                        endcase
                    end
                    8: begin // 8
                        case (font_y)
                            0: font_pixel = 8'b01111100;
                            1: font_pixel = 8'b11000110;
                            2: font_pixel = 8'b11000110;
                            3: font_pixel = 8'b01111100;
                            4: font_pixel = 8'b11000110;
                            5: font_pixel = 8'b11000110;
                            6: font_pixel = 8'b01111100;
                            7: font_pixel = 8'b00000000;
                        endcase
                    end
                    9: begin // 9
                        case (font_y)
                            0: font_pixel = 8'b01111100;
                            1: font_pixel = 8'b11000110;
                            2: font_pixel = 8'b11000110;
                            3: font_pixel = 8'b01111110;
                            4: font_pixel = 8'b00000110;
                            5: font_pixel = 8'b00001110;
                            6: font_pixel = 8'b01111100;
                            7: font_pixel = 8'b00000000;
                        endcase
                    end
                    default: font_pixel = 8'b00000000;
                endcase
            end
            default: font_pixel = 8'b00000000;
        endcase
    end
    
    // Scale font pixel (2x)
    wire scaled_pixel = font_pixel[7-font_x];
    
    wire draw_score_pixel = in_score_text && scaled_pixel;
    
    // Horizontal separator line at Y = 432 (score_y = 0)
    wire is_separator = is_score_area && (score_y == 0);

    // -------------------------------------------------------
    // Pixel Output
    // -------------------------------------------------------
    always @(posedge clk_25M) begin
        if (!video_on_del) begin
            vga_r <= 4'h0; vga_g <= 4'h0; vga_b <= 4'h0;
        end else if (is_score_area) begin
            // Score bar background: dark navy
            vga_r <= 4'h0; vga_g <= 4'h1; vga_b <= 4'h3;
            
            // Score rendering with priority
            if (draw_score_pixel) begin
                // Bright white score text
                vga_r <= 4'hF; vga_g <= 4'hF; vga_b <= 4'hF;
            end else if (is_separator) begin
                // Bright cyan separator line
                vga_r <= 4'h0; vga_g <= 4'hF; vga_b <= 4'hF;
            end
        end else begin
            // Game area rendering
            if (game_state == 2'b00 || game_state == 2'b01) begin // START / INIT_WAIT
                if (is_wall) begin
                    vga_r <= 4'h1; vga_g <= 4'h3; vga_b <= 4'hA;
                end else begin
                    vga_r <= 4'h0; vga_g <= 4'h0; vga_b <= 4'h2;
                end
            end else if (game_state == 2'b11) begin // GAME OVER
                if (is_wall) begin
                    vga_r <= 4'hC; vga_g <= 4'h0; vga_b <= 4'h0;
                end else if (is_snake) begin
                    vga_r <= 4'h8; vga_g <= 4'h0; vga_b <= 4'h0;
                end else begin
                    vga_r <= 4'h4; vga_g <= 4'h0; vga_b <= 4'h0;
                end
            end else begin // PLAYING
                if (is_wall) begin
                    vga_r <= 4'h5; vga_g <= 4'h5; vga_b <= 4'h6;
                end else if (is_food) begin
                    if (is_border) begin
                        vga_r <= 4'h9; vga_g <= 4'h0; vga_b <= 4'h0;
                    end else begin
                        vga_r <= 4'hF; vga_g <= 4'h2; vga_b <= 4'h2;
                    end
                end else if (is_snake) begin
                    if (is_border) begin
                        vga_r <= 4'h0; vga_g <= 4'h6; vga_b <= 4'h0;
                    end else begin
                        vga_r <= 4'h2; vga_g <= 4'hD; vga_b <= 4'h2;
                    end
                end else begin
                    if (current_cell_x[0] ^ current_cell_y[0]) begin
                        vga_r <= 4'h1; vga_g <= 4'h1; vga_b <= 4'h1;
                    end else begin
                        vga_r <= 4'h0; vga_g <= 4'h0; vga_b <= 4'h0;
                    end
                end
            end
        end
    end

endmodule
