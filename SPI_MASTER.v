`timescale 1ns / 1ps

module SPI_MASTER(
  input clk,
  input rst,
  output reg [31:0] data_out=0,
  input [31:0] data_in,
  output reg ack_out,
  output reg [7:0] buf_addrb=0,
  output reg web=0,
  output reg mosi,
  output reg csn=1,
  input miso
    );


// byte write seq: (3 byte si)
//  { instruction(0000 x010), address({x,address[6:0]}), data }

// byte read seq:
//  2 byte si: { instruction(0000 x011), address({x,address[6:0]}) }
//  1 byte so: data

 // read status register (may be read at any time, even during a write cycles)
 //  1 byte si: instruction(0000 x101)
 //  1 byte so: status({xxxx, bp1, bp0, wel, wip})
 //  wip: write in progress, readonly, write IS in progress --> 1
 //  wel: write enable latch: readonly
 //  bp[1:0]: block protection, read/write

// WB Message: address[6:0], data[7:0], dcares, R/Wn, foglalt, ready

// mosi, csn negedge-re menjen ki, miso posedge-re jojjon be

reg [23:0] shr_mosi;  // shift regiszter az SPI mosi muveletek reszere
reg [4:0] shr_mosi_cntr=0;  // a kiadando mosi bitek szamat tarolja

reg [23:0] shr_miso;  // shift regiszter az SPI miso muveletek reszere
reg [4:0] shr_miso_cntr=0;  // a kiadando miso bitek szamat tarolja

reg [1:0] state=0;  // a kozponti allapotget deklaracioja


reg wipreadflag=1;  // az SPI memoria status regiszterenek write in progress bitjenek kilvasasat jelzi, innen tudjuk mikor fejezodik be az SPI memoria irasa
reg statusreadflag=1; // az SPI memoria status regiszterenek kiolvasasat jelzi
reg [2:0] webflag=2;  // a Buffer memoria B portjanak write enable jele allapotaval kapcsolatos jelek jelzesere
reg [3:0] wren_cntr=8;  // az SPI memoria Write Enable Latch-enek beallitasahoz hasznalt bitszamlalo
reg [7:0] shr_wren=8'b01100000; // az SPI memoria Write Enable Latch-enek beallitasara szolgalo kishiftelendo parancs
reg wrenflag=1; // az SPI memoria Write Enable Latch-enek beallitasat jelzi

reg [31:0] data_in_temp;  // a Buffer B portjara kiadando adat reszben tartalmazhatja a bemeneti adatokat, ennek tarolasara szolgal a regisztertomb


// Felfuto es lefuto eleket is kezelunk, mert a memoria az adatokat amikor kiadja es mintavetelezi, az termeszetesen nem egyszerre tortenik
// A buffer irasakor is hasznositjuk az alabbi logikat:

reg clk_rise_r=0;
reg clk_fall_r=0;

wire clk_rise = clk_fall_r^clk_rise_r;
wire clk_fall = ~(clk_fall_r^clk_rise_r);

always@(posedge clk)
begin
  if(rst)
    clk_rise_r <= 0;
  else
    clk_rise_r <= ~clk_rise_r;
end

always@(negedge clk)
begin
  if(rst)
    clk_fall_r <= 0;
  else
    clk_fall_r <= ~clk_fall_r;
end

// A mukodes leirasa:

always @(posedge clk or posedge rst or negedge clk) begin
  if (rst) begin
    state <= 0;
    buf_addrb <= 0;
    shr_mosi_cntr <= 0;
    shr_miso_cntr <= 0;
    wren_cntr <= 8;
    wipreadflag <= 1;
    statusreadflag <= 1;
    webflag <= 2;
    web <= 0;
    csn <= 1;
    shr_wren <= 8'b01100000;
    wrenflag <= 1;
  end

  else if (clk_rise)
  begin
    if (data_in[30] == 1'b1 && data_in[31] != 1'b1) begin
      case(state)
        2'b00:    // adatok kiolvasasa a bufferbol
        begin
          if( wren_cntr == 0 && wrenflag == 0)
          begin
            // csn <= 1'b1;        // wren beiras utani csn beallitas
            if(data_in[29] == 1'b1)         // read kell
            begin
              // shr_mosi <= {8'b00000011,1'b0,data_in[6:0],8'b00000000}; // regiszter veget feltoltjuk 0-kal
              shr_mosi <= {8'b00000000,data_in[6:0],1'b0,8'b11000000};
              shr_mosi_cntr <= 16;
              state <= 2'b01;
            end
            else                            // write kell
            begin
              // shr_mosi <= {8'b00000010,1'b0,data_in[6:0],data_in[14:7]};
              shr_mosi <= {data_in[14:7],data_in[6:0],1'b0,8'b01000000};
              shr_mosi_cntr <= 24;
              state <= 2'b01;
            end
          end
        end
        2'b01:  // buffer adatok kishiftelese az spi memoriara, lefuto elre tortenik
        begin
        end

        2'b10:  // ha memoria iras van akkor jutunk ide, az spi status regiszter alapjan nezzuk, hogy kesz van e mar az iras
        begin
          // * 1 * // az spi memoria statusz regiszterenek lekerdezesenek az elokeszitese
          if(shr_mosi_cntr == 5'b0 && wipreadflag == 1)
          begin
            // shr_mosi <= {8'b00000101,16'b0}; // regiszter veget feltoltjuk 0-kal
            shr_mosi <= {16'b0,8'b10100000};
            shr_mosi_cntr <= 8;
            wipreadflag <= 0;
          end

          // * 3 * // a status regiszter tartalmanak fogadasa az SPI memoriatol
          else if ( !(shr_mosi_cntr != 5'b0 && !(shr_mosi_cntr == 0  && wipreadflag == 1) ) )
          begin
            if(statusreadflag == 1 && shr_miso_cntr == 0)
            begin
              shr_miso_cntr <= 8;
              statusreadflag <= 0;
            end
            else if(shr_miso_cntr != 0)
            begin
              shr_miso[shr_miso_cntr-1] <= miso;
              shr_miso_cntr <= shr_miso_cntr - 1;
            end

            else    // ha mar beirtuk a status regiszter tartalmat az shr_miso regiszterbe
            begin
              // csn <= 1'b1;
              if(shr_miso[0] == 1'b0) // tehat ha az iras befejezodott, ez a write in progress bit
              begin
                if(webflag == 2)
                begin
      						data_out[30:0] <= data_in[30:0];
      						data_out[31] <= 1'b1; // az egesz iras ciklus ready

      						webflag <= 1;
                end
    					  else if (webflag == 1)
    					  begin
    						web <= 1;
                webflag <= 0;
    					 end
                else
                begin
                wipreadflag <= 1;
                statusreadflag <= 1;
                web <= 0;
                webflag <= 2;
                state <= 2'b00;
                end
              end
              else
              begin
                 statusreadflag <= 1;
                 wipreadflag <= 1;
               end
            end
          end
        end

        2'b11:  // memoria olvasas eseten jutunk ebbe az allapotba, kiadjuk a Buffernek a kiolvasott ertekekkel frissitett adatot
        begin
          if(shr_miso_cntr != 0)  // miso-t felfuto elre mintavetelezzuk
          begin
            shr_miso[ 7 - (shr_miso_cntr-1) ] <= miso;
            shr_miso_cntr <= shr_miso_cntr -1;
          end
          else // shr_misoba mar ki van olvasva az spi read valasz
          begin

  				if (webflag == 2)
  				begin

  				  data_in_temp <= data_in;
  				  webflag <= 1;
  				end
          else if(webflag == 1)
            begin
              web <= 1;
              webflag <= 0;
				      data_out[14:7] <= shr_miso[7:0];
              data_out[6:0] <= data_in_temp[6:0];
              data_out[30:15] <= data_in_temp[30:15];
              data_out[31] <= 1'b1;

            end
            else
            begin
              web <= 0;
              webflag <= 2;
              buf_addrb <= buf_addrb + 1'b1;
              wren_cntr <= 8;
              shr_wren <= 8'b01100000;
              wrenflag <= 1;
              state <= 2'b00;
            end
          end
        end
      endcase
    end
    else                                  // ha nem foglalt
    begin
      buf_addrb <= buf_addrb + 1;
      wren_cntr <= 8;
      shr_wren <= 8'b01100000;
      wrenflag <= 1;
    end
  end

  else if (clk_fall)
  begin
    if (data_in[30] == 1'b1 && data_in[31] != 1'b1) begin
      case(state)
        2'b00:  // az SPI memoria Write Enable Latch-enek beallitasa, hogy kesobb tudjunk majd irni a memoriaba
        begin
          if( wren_cntr != 0)
          begin
            if(csn == 1'b1)
            begin
              csn <= 1'b0;
            end
            mosi <= shr_wren[0];
            shr_wren <= {1'b0,shr_wren[7:1]};
            wren_cntr <= wren_cntr - 1;
          end
          else
          begin
            csn <= 1'b1;
            wrenflag <= 0;
          end
        end

        2'b01:  // buffer adatok kishiftelese az spi memoriara
        begin
          wrenflag <= 2;
          if(shr_mosi_cntr != 5'b0)
          begin
            if(csn == 1'b1)
            begin
              csn <= 1'b0;
            end
            mosi <= shr_mosi[0];
            shr_mosi <= {1'b0,shr_mosi[22:1]};
            shr_mosi_cntr <= shr_mosi_cntr - 1;
          end
          else
          begin
            if(data_in[29] == 1'b1)
            begin
            state <= 2'b11; // ha olvasas van, arra rogton jon a valasz, nem kell nezni, h kesz van-e, mint az irasnal
            shr_miso_cntr <= 8;
            end
            else
            begin
              csn <= 1'b1;
              state <= 2'b10; // ha iras van
            end
          end
        end

        2'b10:
        // * 2 * // az SPI memoria status regiszterenek lekerdezesehez a parancs kishiftelese
        if(shr_mosi_cntr != 5'b0 && !(shr_mosi_cntr == 0  && wipreadflag == 1) )
        begin
          mosi <= shr_mosi[0];
          shr_mosi <= {1'b0,shr_mosi[22:1]};
          shr_mosi_cntr <= shr_mosi_cntr - 1;
          if(csn == 1'b1)
          begin
            csn <= 1'b0;
          end
        end

        // * 4 *  // a chip select visszaigazitasa (ez csak lefuto elre tortenhet, a mosi allitassal egyetemben)
        else if ( !(shr_mosi_cntr != 5'b0 && !(shr_mosi_cntr == 0  && wipreadflag == 1) ) )
        begin
          if( !( shr_miso_cntr != 0 && !(statusreadflag == 1 && shr_miso_cntr ==0) ) )
          begin
            csn <= 1'b1;
          end
        end

        2'b11: begin if(shr_miso_cntr == 0 && webflag == 2) csn <= 1; end   // chip select allitasa lefuto elre
      endcase
    end
  end

end

endmodule
