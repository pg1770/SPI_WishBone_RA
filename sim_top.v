`timescale 1ns / 1ps //32

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

	task bus_read(input [7:0] addr_r); //Busz olvasás taskja
	begin
		#2 //következő órajelre kezdjük
		ADR_I <= addr_r;
		WE_I <= 0;
		STB_I <= 1;
		CYC_I <= 1;

		#2
		wait(ACK_O);

		#2
		//ADR határozatlan
		//DAT határozatlan
		STB_I <= 0;
		CYC_I <= 0;
	end
	endtask

	task bus_write(input [7:0] addr_w, input [31:0] data_w); //Busz írás taskja
	begin

		#2 ADR_I <= addr_w;
		WE_I <= 1;
		DAT_I <= data_w;
		STB_I <= 1;
		CYC_I <= 1;

		#2 wait(ACK_O);

		#2 STB_I <= 0;
		CYC_I <= 0;
		//ADR határozatlan
		//DAT határozatlan

	end
	endtask

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
		bus_read(1);
		bus_write(1,32'hFEDC);
		bus_read(1);
	end

	always #1 CLK_I = ~CLK_I;

endmodule



