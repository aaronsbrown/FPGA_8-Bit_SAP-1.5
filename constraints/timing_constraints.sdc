# Create clock for the input 100 MHz clock
create_clock -name clk -period 10.0 [get_ports clk]

# Create clock for the PLL output (20 MHz)
create_clock -name clk_out -period 50.0 [get_nets clk_out]