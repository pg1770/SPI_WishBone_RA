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
input [40:0] dia;
input [41:0] dib;
output [41:0] doa;
output [41:0] dob;
output acka;
output ackb;
output stopa;
reg [41:0] ram [15:0];
reg [41:0] doa;
reg [41:0] dob;
reg acka=0;
reg ackb=0;
reg stopa=0;

always @(posedge clka)
begin
	if (ena)
	begin
		if (wea)
		begin
			if(!ram[addra][41])
			begin
				ram[addra][40:0] <= dia;
				// read vagy write

				ram[addra][41] <= 1'b1;
				if(!dia[40])	// ha write van
				begin
					acka <= 1'b1;
				end
				else // read van
				begin
					// TODO: elso kor stopa 0-ba, masodik kortol, ha 41. bit 0, akkor ack es stopa <= 1
					stopa <= 0;
				end
			end
			else acka <= 1'b0;
		end
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
