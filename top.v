`timescale 1ns / 1ps

module top(
  input [7:0] ADR_I,
  input CYC_I,  // valid bus cycle in progress
  input WE_I,
  input CLK_I,
  input [31:0] DAT_I,
  input RST_I,
  input STB_I,  // de facto Slave Select
  output [31:0] DAT_O,
  output ACK_O
    );


clk_div DIVi(
  .CLK(CLK_I),
  .RST(RST_I),
  .CLKOUT(CLKb)
);

wire [3:0] CNTROUTa;
wire [3:0] CNTROUTb;
wire STOPa;

CNTR CNTRa(
  .CLK(CLK_I),
  .RST(RST_I),
  .STOP(),
  .OUT(CNTROUTa)
);

CNTR CNTRb(
  .CLK(CLKb),
  .RST(RST_I),
  .STOP(),
  .OUT(CNTROUTb)
);

reg wea=0;
reg web=0;

v_rams_16 ram_42_x_16(
  .clka(CLK_I),
  .clkb(CLKd),
  .ena(1'b1),
  .enb(1'b1),
  .wea(wea),
  .web(web),
  .addra(CNTROUTa),
  .addrb(CNTROUTb),
  .dia(),
  .dib(),
  .doa(),
  .dob()
  );



endmodule
