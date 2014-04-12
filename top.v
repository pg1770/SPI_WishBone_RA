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
  .CLKOUT(CLKd)
);

v_rams_16 ram_42_x_16(
  .clka(CLK_I),
  .clkb(clk),
  .ena(sel11),
  .enb(1'b1),
  .wea(1'b1),
  .web(1'b0),
  .addra(jaddr),
  .addrb(address),
  .dia({jparity, jdata}),
  .dib(18'h00000),
  .doa({dopa,doa[15:0]}),
  .dob(instruction1));



endmodule
