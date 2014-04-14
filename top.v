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

wire acka;
wire wea;
wire [40:0] dia;
wire [40:0] doa;

WB_IF wb_if(
  .WB_ADR_I(ADR_I),
  .WB_CYC_I(CYC_I),
  .WB_WE_I(WE_I),
  .WB_CLK_I(CLK_I),
  .WB_DAT_I(DAT_I),
  .WB_RST_I(RST_I),
  .WB_STB_I(STB_I),
  .WB_DAT_O(DAT_O),
  .WB_ACK_O(ACK_O),
  .BUF_STATUS(wena),
  .BUF_DATA_O(dia),
  .BUF_DATA_I(doa),
  .BUF_ACK(acka)
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

reg we_BUFF_to_SPI=0;
reg we_SPI_to_BUFF=0;
wire [40:0] data_BUFF_to_SPI;
wire [40:0] data_SPI_to_BUFF;
wire ack_BUFF_to_SPI;
wire ack_SPI_to_BUFF;

v_rams_16 ram_42_x_16(
  .clka(CLK_I),
  .clkb(CLKd),
  .ena(!RST_I),
  .enb(!RST_I),
  .wea(wea),
  .web(1'b1),
  .addra(CNTROUTa),
  .addrb(CNTROUTb),
  .stopa(STOPa),
  .stopb(STOPb),
  .acka(acka),
  .ackb(ack_BUFF_to_SPI),
  .ackbin(ack_SPI_to_BUFF),
  .dia(dia),
  .dib(data_SPI_to_BUFF),
  .doa(doa),
  .dob(data_BUFF_to_SPI)
  );

wire mosi;
wire miso;

SPI_MASTER spi_if(
  .clk(CLKd),
  .rst(RST_I),
  .data_out(data_SPI_to_BUFF),
  .data_in(data_BUFF_to_SPI),
  .ack_out(ack_SPI_to_BUFF),
  .ack_in(ack_BUFF_to_SPI),
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
