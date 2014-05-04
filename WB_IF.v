`timescale 1ns / 1ps

// Wishbone buszciklusok fogadasa,
// iras/olvasas muveletek megvalositasa
// a Wishbone busz es a buffer kozott

module WB_IF(
  // WB oldal
  input [7:0] WB_ADR_I,
  input WB_CYC_I, 
  input WB_WE_I,
  input WB_CLK_I,
  input [31:0] WB_DAT_I,
  input WB_RST_I,
  input WB_STB_I,  
  output reg [31:0] WB_DAT_O,
  output reg WB_ACK_O,
  
  output reg TGD_0,
  
  // Buffer oldal
  input BUF_ERR,
  output reg BUF_WR,
  output reg [31:0] BUF_DATA_O,
  output reg [7:0] BUF_ADDR_O,
  input [31:0] BUF_DATA_I,
  input BUF_ACK
  
  );

reg [4:0] state;

//orajel fel- lefuto el jelek 
reg clk_rise_r;
reg clk_fall_r;

wire clk_rise = clk_fall_r^clk_rise_r;
wire clk_fall = ~(clk_fall_r^clk_rise_r);

always@(posedge WB_CLK_I)
begin
	if(WB_RST_I)
		clk_rise_r <= 0;
	else
		clk_rise_r <= ~clk_rise_r;

end

always@(negedge WB_CLK_I)
begin
	if(WB_RST_I)
		clk_fall_r <= 0;
	else
		clk_fall_r <= ~clk_fall_r;
end



always@(negedge WB_CLK_I or posedge WB_CLK_I)
begin

	if(WB_RST_I)
	begin
		TGD_0 <= 0;
		BUF_DATA_O <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		state <= 0;
		BUF_WR <= 0;
		BUF_ADDR_O <= 8'bxxxxxxx;
		WB_ACK_O <= 0;
		WB_DAT_O <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
	end

	else if(clk_fall)
	begin
		case (state)
		
		// kezdeti allapot
		// varjuk, hogy ervenyes ciklus induljon (CYC_I)
		0: begin
			WB_ACK_O <= 0;
			if(WB_CYC_I) 
			begin
				BUF_WR <= WB_WE_I;
				BUF_DATA_O <= WB_DAT_I;
				BUF_ADDR_O <= WB_ADR_I;
				state <= state + 1;
			end
			end
		
		// elozo ciklusban kiadtuk az adatot a buffernek
		// most a buffer ACK-ra varunk
		1: begin
			if (BUF_ACK)
					begin
						state <= state + 1;
					end
			end
		endcase
	end
	
	else if(clk_rise)
	begin
		case (state)
		// ha a buffer befejezte az iras/olvasast, felfutoelre kell
		// kiadnunk a Wishbone fele az ACK es mas jeleket
		2: begin
				WB_ACK_O <= 1;
				TGD_0 <= BUF_ERR;
				state <= state + 1;
				if(!WB_WE_I)
				begin
					WB_DAT_O <= BUF_DATA_I;
				end
		end	
		
		//befejeztuk a Wishbone ciklust
		3: begin
			TGD_0 <= 0;
			BUF_DATA_O <= 40'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
			state <= 0;
			BUF_WR <= 0;
			WB_DAT_O <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
			BUF_ADDR_O <= 8'bxxxxxxx;
			WB_ACK_O <= 0;
			end
		endcase
	end
		
end

endmodule
