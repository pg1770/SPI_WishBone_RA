`timescale 100ns / 1000ps //32

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

	
wire mem_o;
reg mem_cs_n;
reg mem_si;

reg [23:0] mem_beshift; 

wire shift = 23'b00000011;

	M25AA010A mem(
	.SI(mem_si),
	.SCK(CLK_I),
	.CS_N(mem_cs_n),
	.WP_N(1),
	.HOLD_N(1),
	.RESET(RST_I),
	.SO(mem_O)
	);
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
	
	
	task mem_write_enable();
	begin
		// 8 bit instruction, 16 bit dont care
		mem_beshift <= {8'b00000110,8'd0, 8'b00000000 };
		
		#1
		mem_cs_n <= 0;
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];

		#2
		mem_cs_n <= 1;
		#1
		mem_si <= 0;
		
	end
	endtask
	
	//felfut�elnel hivodjon meg
	//status regiszter olvasasa
	task mem_status_read();
	begin
		// 8 bit instruction, 16 bit dont care
		mem_beshift <= {8'b00000101,8'd0, 8'b00000000 };
		
		#1
		mem_cs_n <= 0;
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		//8 volt
		//varjuk az adatot
		#16
		#2
		mem_cs_n <= 1;
		#1
		mem_si <= 0;
		
	end
	endtask


	task mem_write(input [6:0] addr_w, input [7:0] data_w);
	begin
		
		// instruction, write addres, data
		mem_beshift <= {8'b00000010, 1'b0, addr_w, data_w };
		
		#1
		mem_cs_n = 0;
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		//10  volt
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		//20  volt
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
		#2
		mem_beshift <= {mem_beshift[22:0], mem_beshift[23]};
		mem_si <= mem_beshift[23];
			
		#2
		
		mem_cs_n <= 1;
		
		
		#1
		mem_si <= 0;
		
	end
	endtask
	
	

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
		
		mem_cs_n = 1;

		// Wait 100 ns for global reset to finish
		#50
		RST_I = 1;
		#20
		RST_I = 0;
		#5
		// Add stimulus here
		#10
		mem_write_enable();
		#10
		mem_write(7'b0000000, 8'b11111111);
		# 50

		mem_status_read ();
		
		/*
		bus_read(1);
		bus_write(1,32'hABCD);
		bus_read(1);
		bus_write(1,32'hFEDC);
		bus_read(1);
		*/
	end

	always #1 CLK_I = ~CLK_I;

endmodule

