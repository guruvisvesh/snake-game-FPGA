## Clock signal (100 MHz Basys 3 board clock)
set_property -dict { PACKAGE_PIN W5    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

## Basys 3 Onboard Push Buttons (Active HIGH)
# BTNU (T18) = UP
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]; 

# BTND (U17) = DOWN
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]; 

# BTNL (W19) = LEFT
set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]; 

# BTNR (T17) = RIGHT
set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]; 

# Reset Switch SW0 (V17 = Switch 0)
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { btnC }];   

## USB HID PS/2 Keyboard on Basys 3 (Connector J2)
set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33   PULLUP TRUE } [get_ports { ps2_clk }];
set_property -dict { PACKAGE_PIN B17   IOSTANDARD LVCMOS33   PULLUP TRUE } [get_ports { ps2_data }];

## Laptop USB-UART RX on Basys 3 (Connector J4)
set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports { uart_rx }];

## Basys 3 Native VGA HD-15 Connector
set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS33 } [get_ports { vgaRed[0] }];
set_property -dict { PACKAGE_PIN H19   IOSTANDARD LVCMOS33 } [get_ports { vgaRed[1] }];
set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS33 } [get_ports { vgaRed[2] }];
set_property -dict { PACKAGE_PIN N19   IOSTANDARD LVCMOS33 } [get_ports { vgaRed[3] }];

set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { vgaGreen[0] }];
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { vgaGreen[1] }];
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { vgaGreen[2] }];
set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports { vgaGreen[3] }];

set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { vgaBlue[0] }];
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { vgaBlue[1] }];
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { vgaBlue[2] }];
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports { vgaBlue[3] }];

set_property -dict { PACKAGE_PIN P19   IOSTANDARD LVCMOS33 } [get_ports { Hsync }];
set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33 } [get_ports { Vsync }];

## Basys 3 Onboard 4-Digit 7-Segment Display
set_property -dict { PACKAGE_PIN W7    IOSTANDARD LVCMOS33 } [get_ports { seg[0] }]; # CA (Segment a)
set_property -dict { PACKAGE_PIN W6    IOSTANDARD LVCMOS33 } [get_ports { seg[1] }]; # CB (Segment b)
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS33 } [get_ports { seg[2] }]; # CC (Segment c)
set_property -dict { PACKAGE_PIN V8    IOSTANDARD LVCMOS33 } [get_ports { seg[3] }]; # CD (Segment d)
set_property -dict { PACKAGE_PIN U5    IOSTANDARD LVCMOS33 } [get_ports { seg[4] }]; # CE (Segment e)
set_property -dict { PACKAGE_PIN V5    IOSTANDARD LVCMOS33 } [get_ports { seg[5] }]; # CF (Segment f)
set_property -dict { PACKAGE_PIN U7    IOSTANDARD LVCMOS33 } [get_ports { seg[6] }]; # CG (Segment g)

set_property -dict { PACKAGE_PIN U2    IOSTANDARD LVCMOS33 } [get_ports { an[0] }];  # AN0 (Rightmost digit)
set_property -dict { PACKAGE_PIN U4    IOSTANDARD LVCMOS33 } [get_ports { an[1] }];  # AN1
set_property -dict { PACKAGE_PIN V4    IOSTANDARD LVCMOS33 } [get_ports { an[2] }];  # AN2
set_property -dict { PACKAGE_PIN W4    IOSTANDARD LVCMOS33 } [get_ports { an[3] }];  # AN3 (Leftmost digit)
