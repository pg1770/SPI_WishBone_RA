`timescale 1ns / 1ps

module clk_div(
  CLK,
  RST,
  CLKOUT
);

input            CLK;
input            RST;
output           CLKOUT;

reg CLKOUT;

always @(posedge CLK)
begin
	if(RST == 1'b1)
	begin
		CLKOUT <= CLK;
	end
	else
	begin
		CLKOUT <= ~CLKOUT;
	end
end

endmodule
