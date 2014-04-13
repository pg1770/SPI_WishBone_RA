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
wire STOPb;

CNTR CNTRa(
  .CLK(CLK_I),
  .RST(RST_I),
  .STOP(STOPa),
  .OUT(CNTROUTa)
);

CNTR CNTRb(
  .CLK(CLKb),
  .RST(RST_I),
  .STOP(STOPb),
  .OUT(CNTROUTb)
);

reg WEa=0;
reg WEb=0;
wire dob;
wire dib;
wire ackb;
wire ackbin;

v_rams_16 ram_42_x_16(
  .clka(CLK_I),
  .clkb(CLKd),
  .ena(!RST_I),
  .enb(!RST_I),
  .wea(),
  .web(1'b1),
  .addra(CNTROUTa),
  .addrb(CNTROUTb),
  .stopa(STOPa),
  .stopb(STOPb),
  .acka(),
  .ackb(ackb),
  .ackbin(ackbin),
  .dia(),
  .dib(dib),
  .doa(),
  .dob(dob)
  );

wire mosi;
wire miso;

SPI_MASTER spi_if(
  .clk(CLKd),
  .rst(RST_I),
  .bin(dob),
  .bout(dib),
  .backin(ackbin),
  .backout(ackb),
  .min(mosi),
  .mout(miso)
  );

M25AA010A spi_mem(
  .SI(mosi),                             // serial data input
  .SCK(CLKd),                            // serial data clock
  .CS_N(1'b0),                           // chip select - active low
  .WP_N(1'b1),                          // write protect pin - active low
  .HOLD_N(1'b1),                         // interface suspend - active low
  .RESET(RST_I),                          // model reset/power-on reset
  .SO(miso)                             // serial data output
);


endmodule
