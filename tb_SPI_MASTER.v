`timescale 100ns / 1000ps


module tb_SPI_MASTER;

	// Inputs
	reg clk;
	reg rst;
	reg [31:0] data_in;
	wire miso;

	// Outputs
	wire [31:0] data_out;
	wire ack_out;
	wire [7:0] buf_addrb;
	wire web;
	wire mosi;
	wire csn;

	M25AA010A mem(
	.SI(mosi),
	.SCK(clk),
	.CS_N(csn),
	.WP_N(1),
	.HOLD_N(1),
	.RESET(rst),
	.SO(miso)
	);

	// Instantiate the Unit Under Test (UUT)
	SPI_MASTER uut (
		.clk(clk),
		.rst(rst),
		.data_out(data_out),
		.data_in(data_in),
		.ack_out(ack_out),
		.buf_addrb(buf_addrb),
		.web(web),
		.mosi(mosi),
		.csn(csn),
		.miso(miso)
	);

	// task bus_write();	//(input [7:0] addr_r); //Busz olvasás taskja
	// begin
	// 	#2
	// 	data_in <= 32'b00000001010101000000000000000010;

	// 	#2
	// 	wait(mosi);

	// 	#2
	// 	//ADR határozatlan
	// 	//DAT határozatlan
	// 	STB_I <= 0;
	// 	CYC_I <= 0;
	// end
	// endtask

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		data_in = 0;
		//miso = 0;

		// Wait 100 ns for global reset to finish
		#100;
		rst = 1;
		#4
		rst = 0;
		// Add stimulus here
		#2
		data_in <= 32'b01000001010101001110000000000000;

		#2
		wait(mosi);



	end

	always #1 clk = ~clk;

endmodule

