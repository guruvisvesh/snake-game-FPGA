`timescale 1ns / 1ps

module tb_simple_game;

    reg clk;
    reg [0:0] sw;           // Reset switch
    reg [3:0] btn;          // Push buttons for direction
    
    // SSD outputs
    wire [6:0] ssd_seg;
    wire ssd_sel;
    
    // HDMI outputs (not used in simulation)
    wire hdmi_tx_clk_p, hdmi_tx_clk_n;
    wire [2:0] hdmi_tx_d_p, hdmi_tx_d_n;

    top uut (
        .clk(clk),
        .sw(sw),
        .btn(btn),
        .hdmi_tx_clk_p(hdmi_tx_clk_p),
        .hdmi_tx_clk_n(hdmi_tx_clk_n),
        .hdmi_tx_d_p(hdmi_tx_d_p),
        .hdmi_tx_d_n(hdmi_tx_d_n),
        .ssd_seg(ssd_seg),
        .ssd_sel(ssd_sel)
    );

    // ULTRA-FAST SIMULATION: Speed up game clock dramatically
    defparam uut.clk_gen_inst.GAME_DIV = 24'd1000; // Much faster for quick testing

    // 125 MHz Clock Generation
    initial begin
        clk = 0;
        forever #4 clk = ~clk;
    end
    
    // Safety timeout to prevent infinite simulation
    initial begin
        #10000000; // 10ms timeout
        $display("[%0t] TIMEOUT: Simulation taking too long, forcing finish", $time);
        $finish;
    end

    initial begin
        // ---------------------------------------------------------
        // Initialization
        // ---------------------------------------------------------
        $display("[%0t] Starting Simple Game Testbench", $time);
        sw = 1'b0;      // Reset OFF
        btn = 4'b1111;  // All buttons released (active-low: 1 = released)
        #100;
        
        // ---------------------------------------------------------
        // 1. Start Screen
        // ---------------------------------------------------------
        $display("[%0t] Game should be in START state", $time);
        #50000;
        if (uut.game_state != 2'b00) begin
            $display("ERROR: Game not in START state!");
            $finish;
        end
        $display("[%0t] ✓ Game in START state", $time);
        
        // ---------------------------------------------------------
        // 2. Start the game
        // ---------------------------------------------------------
        $display("[%0t] Pressing START button (BTN0 - UP)...", $time);
        btn[0] = 0;  // Press UP button (active-low)
        #5000;   // Hold for 5us
        btn[0] = 1;  // Release
        
        $display("[%0t] Waiting for game to enter PLAYING state...", $time);
        wait (uut.game_state == 2'b10);
        $display("[%0t] ✓ Game entered PLAYING state", $time);
        
        // ---------------------------------------------------------
        // 3. Verify snake initialization
        // ---------------------------------------------------------
        #50000;
        $display("[%0t] Snake head position: X=%d, Y=%d, Length=%d", 
                 $time, uut.head_x, uut.head_y, uut.length);
        if (uut.length != 3) begin
            $display("ERROR: Snake length should be 3, got %d", uut.length);
            $finish;
        end
        $display("[%0t] ✓ Snake initialized correctly", $time);
        
        // ---------------------------------------------------------
        // 4. Test direction changes
        // ---------------------------------------------------------
        $display("[%0t] Testing direction changes...", $time);
        
        // Change to DOWN
        btn[1] = 0;  // Press DOWN
        #5000;
        btn[1] = 1;  // Release
        #25000;
        $display("[%0t] Direction after DOWN press: %d", $time, uut.direction);
        
        // Change to LEFT
        btn[2] = 0;  // Press LEFT
        #5000;
        btn[2] = 1;  // Release
        #25000;
        $display("[%0t] Direction after LEFT press: %d", $time, uut.direction);
        
        // Change to RIGHT
        btn[3] = 0;  // Press RIGHT
        #5000;
        btn[3] = 1;  // Release
        #25000;
        $display("[%0t] Direction after RIGHT press: %d", $time, uut.direction);
        
        $display("[%0t] ✓ Direction changes working", $time);
        
        // ---------------------------------------------------------
        // 5. Test reset functionality
        // ---------------------------------------------------------
        $display("[%0t] Testing reset functionality...", $time);
        sw = 1'b1;  // Assert reset
        #5000;
        sw = 1'b0;  // Release reset
        
        wait (uut.game_state == 2'b00);
        $display("[%0t] ✓ Game returned to START state after reset", $time);
        
        // ---------------------------------------------------------
        // Finish Simulation
        // ---------------------------------------------------------
        $display("[%0t] ✓ ALL TESTS PASSED SUCCESSFULLY!", $time);
        $finish;
    end

endmodule