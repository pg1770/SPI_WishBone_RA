`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:22:20 05/03/2014
// Design Name:   top
// Module Name:   E:/WB_SPI_hazi_git/hazi_local_project/FINAL_TEST.v
// Project Name:  WB_SPI_RA
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module FINAL_TEST;

	// Inputs
	reg [7:0] ADR_I;
	reg CYC_I;
	reg WE_I;
	reg CLK_I;
	reg [31:0] DAT_I;
	reg RST_I;
	reg STB_I;
	wire SPI_MISO;

	// Outputs
	wire [31:0] DAT_O;
	wire ACK_O;
	wire SPI_MOSI;
	wire SPI_CLK;
	wire SPI_CS_N;
	wire SPI_WP_N;
	wire SPI_HOLD_N;
	wire SPI_RESET;

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
		.ACK_O(ACK_O), 
		.SPI_MOSI(SPI_MOSI), 
		.SPI_CLK(SPI_CLK), 
		.SPI_CS_N(SPI_CS_N), 
		.SPI_WP_N(SPI_WP_N), 
		.SPI_HOLD_N(SPI_HOLD_N), 
		.SPI_RESET(SPI_RESET), 
		.SPI_MISO(SPI_MISO)
	);


	M25AA010A mem(
	.SI(SPI_MOSI),
	.SCK(SPI_CLK),
	.CS_N(SPI_CS_N),
	.WP_N(SPI_WP_N),
	.HOLD_N(SPI_HOLD_N),
	.RESET(SPI_RESET),
	.SO(SPI_MISO)
	);
	
	
	
	
	task bus_read(input [7:0] addr_r); 
	begin
		#2 
		ADR_I <= addr_r;
		WE_I <= 0;
		STB_I <= 1;
		CYC_I <= 1;

		#2
		wait(ACK_O);
		#2
		
		STB_I <= 0;
		CYC_I <= 0;
	end
	endtask
	
	//felfutoelre hivjuk
	task bus_write(input [7:0] addr_w, input [31:0] data_w); //Busz írás taskja
	begin

		#2 
		ADR_I <= addr_w;
		WE_I <= 1;
		DAT_I <= data_w;
		STB_I <= 1;
		CYC_I <= 1;

		#2 wait(ACK_O);
		#2

		STB_I <= 0;
		CYC_I <= 0;
		WE_I <= 0;
		
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
		#50
		RST_I = 1;
		#20
		RST_I = 0;
		#11

		bus_write(1,32'b01000001010101001010000000000000);
		bus_read(1);
		bus_write(2,32'h01100001010101001110000000000000);
		bus_read(2);
		
		#1000
		bus_read(1);
		
		

	end
      
	always #1 CLK_I = ~CLK_I;
	
endmodule

