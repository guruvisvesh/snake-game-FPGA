// Simulation models for Xilinx primitives
// These behavioral models allow the design to simulate in ModelSim without actual Xilinx libraries

// -------------------------------------------------------------------
// MMCME2_BASE - Mixed Mode Clock Manager (Simulation Model)
// -------------------------------------------------------------------
module MMCME2_BASE #(
    parameter BANDWIDTH = "OPTIMIZED",
    parameter CLKFBOUT_MULT_F = 8.0,
    parameter CLKFBOUT_PHASE = 0.0,
    parameter CLKIN1_PERIOD = 8.0,
    parameter real CLKOUT0_DIVIDE_F = 4.0,
    parameter integer CLKOUT1_DIVIDE = 40,
    parameter DIVCLK_DIVIDE = 1
) (
    input CLKIN1,           // Clock input (125 MHz)
    input PWRDWN,           // Power down
    input RST,              // Reset
    input CLKFBIN,          // Feedback clock
    output CLKOUT0,         // 250 MHz output (Serial Clock)
    output CLKOUT1,         // 25 MHz output (Pixel Clock)
    output CLKFBOUT,        // Feedback clock output
    output LOCKED           // Lock output
);

    // Simplified behavioral model for simulation
    // In real hardware, this is a complex PLL with specific phase relationships
    // For simulation, we'll just divide the input clock appropriately
    
    reg [7:0] div_counter_25m;
    reg [2:0] div_counter_250m;
    reg clk_25m_reg;
    reg clk_250m_reg;
    reg locked_reg;
    
    // 125 MHz to 25 MHz: divide by 5 (real hardware uses 40 divide)
    // 125 MHz to 250 MHz: multiply by 2 (real hardware uses 4 divide)
    
    always @(posedge CLKIN1 or posedge RST) begin
        if (RST) begin
            div_counter_25m <= 0;
            div_counter_250m <= 0;
            clk_25m_reg <= 0;
            clk_250m_reg <= 0;
            locked_reg <= 0;
        end else if (!PWRDWN) begin
            // 25 MHz generation (divide by 5 for simulation speed)
            div_counter_25m <= div_counter_25m + 1;
            if (div_counter_25m == 4) begin
                div_counter_25m <= 0;
                clk_25m_reg <= ~clk_25m_reg;
            end
            
            // 250 MHz generation (toggle every cycle - simplified)
            div_counter_250m <= div_counter_250m + 1;
            if (div_counter_250m == 0) begin
                clk_250m_reg <= ~clk_250m_reg;
            end
            
            // Lock signal after some cycles
            locked_reg <= 1;
        end
    end
    
    assign CLKOUT0 = clk_250m_reg; // 250 MHz serial clock
    assign CLKOUT1 = clk_25m_reg;  // 25 MHz pixel clock
    assign CLKFBOUT = CLKOUT1; // Simple feedback
    assign LOCKED = locked_reg;

endmodule

// -------------------------------------------------------------------
// BUFG - Global Clock Buffer (Simulation Model)
// -------------------------------------------------------------------
module BUFG (
    input I,
    output O
);
    // Simple buffer for simulation
    assign O = I;
endmodule

// -------------------------------------------------------------------
// OBUFDS - Differential Output Buffer (Simulation Model)
// -------------------------------------------------------------------
module OBUFDS (
    input I,
    output O,
    output OB
);
    // Differential output buffer for simulation
    assign O = I;
    assign OB = ~I;
endmodule