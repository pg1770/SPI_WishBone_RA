`timescale 1ns / 1ps
module v_rams_16 (
	clka,
	clkb,
	ena,
	enb,
	wea,
	web,
	addra,
	addrb,
	dia,
	dib,
	doa,
	dob);

input clka;
input clkb;
input ena;
input enb;
input wea;
input web;
input [4:0] addra;
input [4:0] addrb;
input [41:0] dia;
input [41:0] dib;
output [41:0] doa;
output [41:0] dob;
reg [41:0] ram [15:0];
reg [41:0] doa;
reg [41:0] dob;

always @(posedge clka)
begin
	if (ena)
	begin
		if (wea)
			ram[addra] <= dia;
		doa <= ram[addra];
	end
end

always @(posedge clkb)
begin
	if (enb)
	begin
		if (web)
			ram[addrb] <= dib;
		dob <= ram[addrb];
	end
end

endmodule
