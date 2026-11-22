`timescale 1ns / 1ps

module tb_image_gen;

    reg clk;
    reg [3:0] sw;
    reg ard_up, ard_down, ard_left, ard_right, ard_start;
    
    wire [3:0] vga_r;
    wire [3:0] vga_g;
    wire [3:0] vga_b;
    wire hsync;
    wire vsync;
    wire [6:0] ssd_seg;
    wire ssd_sel;

    top uut (
        .clk(clk),
        .sw(sw),
        .ard_up(ard_up),
        .ard_down(ard_down),
        .ard_left(ard_left),
        .ard_right(ard_right),
        .ard_start(ard_start),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .hsync(hsync),
        .vsync(vsync),
        .ssd_seg(ssd_seg),
        .ssd_sel(ssd_sel)
    );

    // SPEED UP SIMULATION PARAMETERS
    // Make the debouncer extremely fast (~16 us instead of 8.4 ms)
    defparam uut.input_ctrl_inst.DEBOUNCE_MAX = 20'd2000;
    
    // Make the game tick extremely fast (~400 us instead of 100 ms)
    defparam uut.clk_gen_inst.GAME_DIV = 24'd50000;

    // 125 MHz Clock Generation
    initial begin
        clk = 0;
        forever #4 clk = ~clk;
    end

    // Reusable task to capture one full VGA frame and save it to a PPM file
    // Crucially, it FREEZES the game logic while capturing so the snake doesn't move and tear the image!
    task capture_frame;
        input [80*8:1] filename; 
        integer file;
        integer pixel_count;
        begin
            $display("[%0t] Freezing game logic to capture %s cleanly...", $time, filename);
            force uut.clk_game = 0; // Freeze the game clock!
            
            @(negedge vsync);
            @(posedge vsync);
            
            file = $fopen(filename, "w");
            if (file == 0) begin
                $display("Error: Could not open file %s for writing.", filename);
                $finish;
            end
            
            $fwrite(file, "P3\n");
            $fwrite(file, "640 480\n");
            $fwrite(file, "255\n");
            
            pixel_count = 0;
            $display("[%0t] Capturing pixels...", $time);
            
            while (pixel_count < 307200) begin
                @(posedge uut.clk_25M);
                if (uut.renderer_inst.video_on_del) begin
                    $fwrite(file, "%d %d %d\n", {vga_r, vga_r}, {vga_g, vga_g}, {vga_b, vga_b});
                    pixel_count = pixel_count + 1;
                end
            end
            
            $fclose(file);
            $display("[%0t] SUCCESS! Frame saved to %s", $time, filename);
            
            release uut.clk_game; // Unfreeze the game clock!
        end
    endtask

    initial begin
        // ---------------------------------------------------------
        // Initialization
        // ---------------------------------------------------------
        sw = 4'b0001;
        ard_up = 0; ard_down = 0; ard_left = 0; ard_right = 0; ard_start = 0;
        #100;
        sw = 4'b0000; 
        
        // ---------------------------------------------------------
        // 1. Capture the START Screen
        // ---------------------------------------------------------
        #100000;
        capture_frame("01_start.ppm");
        
        // ---------------------------------------------------------
        // 2. Start the game and capture GAMEPLAY (Snake + Food)
        // ---------------------------------------------------------
        $display("[%0t] Pressing START button...", $time);
        ard_start = 1;
        #100000; // Hold for 100us (debouncer is now only 16us)
        ard_start = 0;
        
        wait (uut.game_state == 2'b10);
        $display("[%0t] Game entered PLAYING state.", $time);
        
        // Force the food to spawn directly in front of the snake (22, 15)
        force uut.food_inst.food_x = 22;
        force uut.food_inst.food_y = 15;
        
        capture_frame("02_gameplay.ppm"); 
        
        // ---------------------------------------------------------
        // 3. Capture Snake EATING and GROWING
        // ---------------------------------------------------------
        $display("[%0t] Waiting for snake to eat the food...", $time);
        
        @(posedge uut.fsm_inst.food_eaten_pulse);
        $display("[%0t] FOOD EATEN! Releasing forced food position...", $time);
        
        release uut.food_inst.food_x;
        release uut.food_inst.food_y;
        
        // Wait for one game tick to let the snake visually grow on screen
        @(posedge uut.fsm_inst.game_tick);
        capture_frame("03_eat_food.ppm");
        
        // ---------------------------------------------------------
        // 4. Capture GAME OVER (Collision)
        // ---------------------------------------------------------
        $display("[%0t] Letting the snake run into the right wall naturally...", $time);
        
        // The game tick is now extremely fast (400 us), so the snake will hit the wall in just a few milliseconds!
        wait (uut.game_state == 2'b11);
        $display("[%0t] Game entered GAME OVER state.", $time);
        
        capture_frame("04_game_over.ppm");
        
        // ---------------------------------------------------------
        // Finish Simulation
        // ---------------------------------------------------------
        $display("[%0t] ALL IMAGES GENERATED EXTREMELY FAST AND SUCCESSFULLY!", $time);
        $finish;
    end

endmodule