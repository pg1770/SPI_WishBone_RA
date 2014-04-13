`timescale 1ns / 1ps


module sim_inf_ram;

	// Inputs
	reg clka;
	reg clkb;
	reg ena;
	reg enb;
	reg wea;
	reg [4:0] addra;
	reg [4:0] addrb;
	reg ackbin;
	reg [40:0] dia;
	reg [40:0] dib;

	// Outputs
	wire stopa;
	wire stopb;
	wire acka;
	wire ackb;
	wire [40:0] doa;
	wire [40:0] dob;

	// Instantiate the Unit Under Test (UUT)
	v_rams_16 uut (
		.clka(clka),
		.clkb(clkb),
		.ena(ena),
		.enb(enb),
		.wea(wea),
		.addra(addra),
		.addrb(addrb),
		.stopa(stopa),
		.stopb(stopb),
		.ackbin(ackbin),
		.acka(acka),
		.ackb(ackb),
		.dia(dia),
		.dib(dib),
		.doa(doa),
		.dob(dob)
	);

	initial begin
		// Initialize Inputs
		clka = 0;
		clkb = 0;
		ena = 0;
		enb = 0;
		wea = 0;
		addra = 0;
		addrb = 0;
		ackbin = 0;
		dia = 0;
		dib = 0;

		// Wait 100 ns for global reset to finish
		#100;

		// Add stimulus here
		ena = 1;
		enb = 1;
		wea = 1;


	end

	always #1 clka = ~clka;
	always #4 clkb = ~clkb;

endmodule

