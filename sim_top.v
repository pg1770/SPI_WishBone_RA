`timescale 1ns / 1ps

module sim_top;

	// Inputs
	reg [7:0] ADR_I;
	reg CYC_I;
	reg WE_I;
	reg CLK_I;
	reg [31:0] DAT_I;
	reg RST_I;
	reg STB_I;

	// Outputs
	wire [31:0] DAT_O;
	wire ACK_O;

	// Instantiate the Unit Under Test (UUT)
	top uut (
		.ADR_I(ADR_I),
		.CYC_I(CYC_I),
		.WE_I(WE_I),
		.CLK_I(CLK_I),
		.DAT_I(DAT_I),
		.RST_I(RST_I),
		.STB_I(STB_I),
		.DAT_O(DAT_O),
		.ACK_O(ACK_O)
	);

	initial begin
		// Initialize Inputs
		ADR_I = 0;
		CYC_I = 0;
		WE_I = 0;
		CLK_I = 0;
		DAT_I = 0;
		RST_I = 0;
		STB_I = 0;

		// Wait 100 ns for global reset to finish
		#100;

		// Add stimulus here

	end

endmodule

