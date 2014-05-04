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
	dob,
	acka,
	ackb,
	errora);

input clka;
input clkb;
input ena;
input enb;
input wea;
input web;
input [7:0] addra;
input [7:0] addrb;
input [31:0] dia;
input [31:0] dib;
output [31:0] doa;
output [31:0] dob;
output acka;
output ackb;
output reg errora;
reg [31:0] ram [255:0];
reg [31:0] doa;
reg [31:0] dob;
reg acka;
reg ackb;

integer i;
// WB Message: address[6:0], data[7:0], dcares, R/nW, foglalt, ready
reg acka_cntr;

initial begin 			// buffer memoria inicializalasa 0 kezdeti ertekekkel
	for( i = 0; i < 256; i = i + 1 )
	begin
		ram[i] <= 32'd0;
	end
end


always @(posedge clka)
begin

	if (ena)
	begin
		//ack 1 orajelig kell h tartson, ha a counterje fel van húzva, akkor ebben a lepesben
		// kell lehuznunk az ack ot
		if (acka_cntr == 1)
		begin
			acka <= 1'b0;
			acka_cntr <= 0;
			errora <= 1'b0;
		end

		// WB irna a bufferbe
		if (wea)
		begin
			// ha meg nem foglalt a hely akkor beirjuk
			if(ram[addra][30] != 1'b1)
			begin
				ram[addra][29:0] <= dia[29:0];
				acka <= 1'b1;
				acka_cntr <= 1;
				ram[addra][31] <= 1'b0;	//ready
				ram[addra][30] <= 1'b1;	//foglalt
			end
			// ha foglalt a hely
			else
			begin
				errora <= 1'b1;
				acka <= 1'b1;
				acka_cntr <= 1;
			end
		end //end WB write
		// WB readel
		else
		begin
			acka <= 1'b1;
			//ha mar ready volt az uzenet, akkor ki is torolhetjuk a foglaltsagot
			// mivel mar atadtuk a Wbnak a kesz adatot
			if(ram[addra][31] == 1'b1)
			begin
				ram[addra][30] <= 1'b0;
			end
		end //end WB read
		doa <= ram[addra];		// majd kiolvasonak nezni kell h ready-e

	end

	else
	begin
		acka_cntr <= 0;
		acka <= 1'b0;
		errora <= 1'b0;
	end

end

always @(negedge clkb) // A Buffer SPI feloli oldala, szokvanyos memoriakent mukodik
begin
	if (enb)
	begin
		if (web)
			ram[addrb] <= dib;
		dob <= ram[addrb];
		ackb <= 1'b1;
	end
	else
	begin
		ackb <= 1'b0;
	end
end


endmodule

