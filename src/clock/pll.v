/**
 * PLL configuration
 *
 * This Verilog module was generated automatically
 * using the icepll tool from the IceStorm project.
 * Use at your own risk.
 *
 * Given input frequency:       100.000 MHz
 * Requested output frequency:   20.000 MHz
 * Achieved output frequency:    20.000 MHz
 */

module pll(
	input  clock_in,
	output clock_out,
	output locked
	);

SB_PLL40_CORE #(
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'b0100),		// DIVR =  4
		.DIVF(7'b0011111),	// DIVF = 31
		.DIVQ(3'b101),		// DIVQ =  5
		.FILTER_RANGE(3'b010)	// FILTER_RANGE = 2
	) uut (
		.LOCK(locked),
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.REFERENCECLK(clock_in),
		.PLLOUTCORE(clock_out)
		);

endmodule

`ifdef SIMULATION
module SB_PLL40_CORE #(
    parameter [3:0] DIVR = 4'b0100,
    parameter [6:0] DIVF = 7'b0011111,
    parameter [2:0] DIVQ = 3'b101,
    parameter [2:0] FILTER_RANGE = 3'b010,
    parameter FEEDBACK_PATH = "SIMPLE"
) (
    input  RESETB,
    input  BYPASS,
    input  REFERENCECLK,
    output PLLOUTCORE,
    output LOCK
);
    // For simulation, pass the input clock through and assert LOCK high.
    assign PLLOUTCORE = REFERENCECLK;
    assign LOCK = 1'b1;
endmodule
`else
// Synthesis (or black-box) implementation of SB_PLL40_CORE is provided by the vendor toolchain.
`endif