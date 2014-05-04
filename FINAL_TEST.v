`timescale 100ns / 1000ps

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
	wire TGD_0;

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
		.SPI_MISO(SPI_MISO),
		.TGD_0(TGD_0)
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

		bus_write(8'd1,32'b01000001010101001010000000000000);
		bus_read(8'd1);
		bus_write(8'd2,32'b01100001010101001110000000000000);
		bus_read(8'd2);
		bus_write(8'd3,32'b01000001010101001010101010000011);
		bus_write(8'd4,32'b01100001010101001110000010000011);
		#200000
		bus_read(8'd1);
		bus_read(8'd2);
		bus_read(8'd4);
		
		
		

	end
      
	always #1 CLK_I = ~CLK_I;
	
endmodule

