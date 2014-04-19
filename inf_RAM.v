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
	ackb);

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
reg [31:0] ram [255:0];
reg [31:0] doa;
reg [31:0] dob;
reg acka;
reg ackb;

always @(posedge clka)
begin
	if (ena)
	begin
		if (wea)
			ram[addra] <= dia;
		doa <= ram[addra];
		acka <= 1'b1;
	end
	else
	begin
		acka <= 1'b0;
	end
end

always @(posedge clkb)
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

// module v_rams_16 (
// 	clka,
// 	clkb,
// 	ena,
// 	enb,
// 	wea,
// 	web,
// 	addra,
// 	addrb,
// 	stopa,
// 	stopb,
// 	ackbin,
// 	acka,
// 	ackb, //mem2spi_data_valid
// 	dia,
// 	dib,
// 	doa,
// 	dob);

// input clka;
// input clkb;
// input ena;
// input enb;
// input wea;
// input web;
// input ackbin;
// input [4:0] addra;
// input [4:0] addrb;
// input [40:0] dia;
// input [40:0] dib;
// output [40:0] doa;
// output [40:0] dob;
// output acka;
// output stopa;
// output stopb;
// output ackb; //mem2spi_data_valid
// reg [41:0] ram [15:0];
// reg [40:0] doa;
// reg [40:0] dob;

// reg acka;
// reg stopa;
// reg stopb;
// reg cica;
// reg cica2;
// reg ackb;

// // cica problema

// always @(posedge clka)
// begin
// 	if (ena)
// 	begin
// 		if (wea)		// elo kell allitani ertelmesen
// 		begin
// 			if(!ram[addra][41])
// 			begin
// 				ram[addra][40:0] <= dia;
// 				// read vagy write
// 				ram[addra][41] <= 1'b1; // foglalt
// 				if(!dia[40])	// ha write van, 40-es bit: write a 0
// 				begin
// 					acka <= 1'b1;
// 				end
// 				else // read van
// 				begin
// 					// elso kor stopa 0-ba, masodik kortol, ha 41. bit 0, akkor ack es stopa <= 1
// 					if(cica > 0)
// 					begin
// 						stopa <= 1;
// 						cica <= cica - 1;
// 					end
// 					if( ram[addra][41] == 1'b0 )
// 					begin
// 						stopa <= 0;
// 						acka <= 1;
// 						cica <= 1'b1;
// 					end
// 				end
// 			end
// 			else acka <= 1'b0; // ha nincs ack a wb if otthagyja az adatot a buszon
// 		end
// 		doa <= ram[addra][40:0]; // ez mindig kintvan, de nem feltetlen valid
// 		acka <= 1;
// 	end
// 	else // enable negalt
// 	begin
// 		acka <= 0;
// 		stopa <= 0;
// 		cica <= 1;
// 		acka <= 0;
// 	end
// end



// always @(posedge clkb)
// begin
// 	if(enb)
// 	begin
// 		if(ram[addrb][41] == 1'b0) // nem foglalt, nincs mit elvenni
// 			stopb <= 1;
// 		else  // foglalt, van ervenyes adat, amit elvehet az spi
// 		begin
// 			if(ram[addrb][40] == 1'b0) // write
// 			begin
// 			 if(cica2 == 0)
// 			 begin
// 				dob <= ram[addrb][40:0];
// 				ackb <= 1;
// 				cica2 <= 1;
// 			 end
// 			 else
// 			 begin
// 			  ackb <= 0;
// 			  cica2 <= 0;
// 			  stopb <= 0;
// 			 end
// 			end
// 			else // read
// 			begin
// 				if(ackbin == 0) // ha spi meg nem valaszolt, h kesz
// 				begin
// 					dob <= ram[addrb][40:0];
// 					ackb <= 1;
// 					stopb <= 1;
// 				end
// 				else // spi kesz
// 				begin
// 					ram[addrb][40:0] <= dib; // spi akkor az egeszet visszaadja
// 					ram[addrb][41] <= 1'b0;
// 					stopb <= 0;
// 					ackb <= 0;
// 				end
// 			end
// 		end
// 	end
// 	else // enb negalt
// 	begin
// 		cica2 <= 0;
// 		ackb <= 0;
// 		stopb <= 0;
// 	end
// end

// endmodule

	// if (enb)
	// begin
	// 	if (!web)	// TODO: elo kellene allitani ertelmesen
	// 	begin
	// 		if(ram[addrb][41] == 1'b1)
	// 		begin
	// 			dob <= ram[addrb];
	// 			if(cica2 > 0)
	// 			begin
	// 				ackb <= 1;
	// 				cica2 <= cica2 - 1;
	// 			end
	// 			if(ram[addrb][40] == 0) // write van
	// 			begin
	// 				ram[addrb][41] == 1'b0;
	// 				stopb <= 0;

	// 			end
	// 			else // read van, stop-t majd allitani kell, majd a memory write-nal fogjuk
	// 			begin
	// 			end
	// 		end
	// 		else
	// 		begin
	// 			stopb <= 1; // ezt meg majd 0-ba kell huzni
	// 		end
	// 	end
	// 	dob <= ram[addrb];
	// end
	// else // tehat most a memoriat irjuk az spi tudja ezt, o kezdemenyezte a read ciklust
	// begin
	// 	ram[addrb][8:40] <= dib[8:40];
	// 	ram[addrb][41] <= 1'b0;
	// 	stopb <= 0;
	// 	ackb <= 0; // ackb-n a valid data-t ertjuk
	// end
