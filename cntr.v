`timescale 1ns / 1ps

module CNTR(
  CLK,
  RST,
  STOP,
  OUT
);

input         CLK;
input         RST;
input         STOP;
output [3:0]  OUT;

reg    [3:0]  OUT=0;

always @(posedge CLK)
begin
  if (RST) OUT <= 4'b0;
  else if (STOP);
    else if( OUT == 4'b1111 ) OUT <= 0;
      else OUT <= OUT + 1;
end

endmodule
