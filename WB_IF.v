`timescale 1ns / 1ps

module WB_IF(
  //WB
  input [7:0] WB_ADR_I,
  input WB_CYC_I, 
  input WB_WE_I,
  input WB_CLK_I,
  input [31:0] WB_DAT_I,
  input WB_RST_I,
  input WB_STB_I,  
  output reg [31:0] WB_DAT_O,
  output reg WB_ACK_O,
  
  //memory
  output reg BUF_STATUS,
  output reg [40:0] BUF_DATA_O,
  input [40:0] BUF_DATA_I,
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
		BUF_DATA_O <= 40'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		state <= 0;
		BUF_STATUS <= 0;
		WB_ACK_O <= 0;
		WB_DAT_O <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
	end

	else if(clk_fall)
	begin
		case (state)
		0: begin
			if(WB_CYC_I) //state 0, CYC_I most jelent meg
			begin
				if(WB_WE_I)	//iras van
				begin
					BUF_DATA_O <= {WB_ADR_I[7:0], WB_DAT_I[31:0], 1'b0};
					BUF_STATUS <= 1;
					state <= state + 1;
				end
				else //read
				begin
					BUF_DATA_O <= {WB_ADR_I[7:0], WB_DAT_I[31:0], 1'b1};
					BUF_STATUS <= 1;
					state <= state + 1;
				end
			end
			end
		endcase
	end
	
	else if(clk_rise)
	begin
		case (state)
		1: begin
			if(WB_WE_I)	//iras van
				begin
					if (BUF_ACK)
					begin
						WB_ACK_O <= 1;
						state <= state + 1;
					end
				end
				else //read
				begin
					if(BUF_ACK)
					begin
						WB_DAT_O <= BUF_DATA_I[39:8];
						WB_ACK_O <= 1;
						state <= state + 1;
					end
				end
			end
		2: begin
			BUF_DATA_O <= 40'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
			state <= 0;
			BUF_STATUS <= 0;
			WB_ACK_O <= 0;
			WB_DAT_O <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
			end
		endcase
	end
	
	
	
end

 

endmodule
