`timescale 1ns / 1ps

module snake_memory (
    input clk,
    
    // --- Coordinate RAM ---
    input we_coord,
    input [10:0] addr_coord_w,
    input [11:0] din_coord,
    input [10:0] addr_coord_r,
    output reg [11:0] dout_coord,

    // --- Grid RAM (Tile map) ---
    // Port for Controller to update grid (head/tail)
    input we_grid,
    input [10:0] addr_grid_w,
    input din_grid,
    
    // Read Port 1: For VGA Renderer
    input [10:0] addr_grid_r1,
    output reg dout_grid1,
    
    // Read Port 2: For Food Generator and Collision Detector
    input [10:0] addr_grid_r2,
    output reg dout_grid2
);

    // 2048 x 12-bit Coordinate RAM: {Y[5:0], X[5:0]}
    reg [11:0] coord_ram [0:2047];
    
    integer i;
    initial begin
        for (i = 0; i < 2048; i = i + 1) begin
            coord_ram[i] = 12'd0;
        end
    end

    always @(posedge clk) begin
        if (we_coord)
            coord_ram[addr_coord_w] <= din_coord;
        dout_coord <= coord_ram[addr_coord_r];
    end

    // 2048 x 1-bit Grid RAM (1 = snake segment, 0 = empty)
    // Address format: {Y[4:0], X[5:0]}
    // Will be synthesized as Distributed RAM because of 1 write / 2 read ports
    reg grid_ram [0:2047];
    
    initial begin
        for (i = 0; i < 2048; i = i + 1) begin
            grid_ram[i] = 1'b0;
        end
    end
    
    always @(posedge clk) begin
        if (we_grid)
            grid_ram[addr_grid_w] <= din_grid;
        dout_grid1 <= grid_ram[addr_grid_r1];
        dout_grid2 <= grid_ram[addr_grid_r2];
    end

endmodule
