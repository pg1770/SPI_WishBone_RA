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

reg [24:0]       clkCount =  25'h0000000;
parameter [24:0] cntEndVal = 25'h0000002;


always @(posedge CLK or posedge RST)
  if (RST == 1'b1) begin
    CLKOUT <= 1'b0;
    clkCount <= 25'h0000000;
  end
  else begin
    if (clkCount == cntEndVal) begin
      CLKOUT <= (~CLKOUT);
      clkCount <= 25'h0000000;
    end
    else begin
      clkCount <= clkCount + 1'b1;
    end
  end

endmodule
