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
  output ACK_O,
  
  output SPI_MOSI,                             // serial data input
  output SPI_CLK,                            // serial data clock
  output SPI_CS_N,                           // chip select - active low
  output SPI_WP_N,                          // write protect pin - active low
  output SPI_HOLD_N,                         // interface suspend - active low
  output SPI_RESET,                          // model reset/power-on reset
  input  SPI_MISO                             // serial data output
  );



assign SPI_HOLD_N = 1;
assign SPI_WP_N = 1;

assign SPI_RESET = RST_I;

wire WB_to_BUFF_WE;
wire [40:0] WB_to_BUFF_ADR;
wire [31:0] WB_to_BUFF_DATA;
wire [31:0] BUFF_to_WB_DATA;
wire BUFF_to_WB_ACK;
wire BUFF_to_WB_ERR;

wire [31:0] SPI_to_BUFF_DATA;
wire [31:0] BUFF_to_SPI_DATA;
wire SPI_to_BUFF_ACK;
wire [7:0] SPI_to_BUFF_ADR;
wire SPI_to_BUFF_WE;

wire CLKd;

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
  .BUF_WR(WB_to_BUFF_WE),
  .BUF_ADDR_O(WB_to_BUFF_ADR),
  .BUF_DATA_O(WB_to_BUFF_DATA),
  .BUF_DATA_I(BUFF_to_WB_DATA),
  .BUF_ACK(BUFF_to_WB_ACK)
  );



clk_div DIVi(
  .CLK(CLK_I),
  .RST(RST_I),
  .CLKOUT(CLKd)
);


v_rams_16 ram_42_x_16(
  .clka(CLK_I),
  .clkb(CLKd),
  .ena(!RST_I),
  .enb(!RST_I),
  .wea(WB_to_BUFF_WE),
  .web(SPI_to_BUFF_WE),
  .addra(WB_to_BUFF_ADR),
  .addrb(SPI_to_BUFF_ADR),
  .acka(BUFF_to_WB_ACK),
  .ackb(SPI_to_BUFF_ACK),
  .dia(WB_to_BUFF_DATA),
  .dib(SPI_to_BUF_DATA),
  .doa(BUFF_to_WB_DATA),
  .dob(BUF_to_SPI_DATA),
  .errora(BUFF_to_WB_ERR)  //ezzel meg kellene vmit kezdeni a Wb nal
  );



SPI_MASTER spi_if(
	.clk(CLKd),
	.rst(RST_I),
	.data_out(SPI_to_BUFF_DATA),
	.data_in(BUFF_to_SPI_DATA),
	.ack_out(SPI_to_BUFF_ACK),
	.buf_addrb(SPI_to_BUFF_ADR),
	.web(SPI_to_BUFF_WE),
	.mosi(SPI_MOSI),
	.csn(SPI_CS_N),
	.miso(SPI_MISO)
);

endmodule
