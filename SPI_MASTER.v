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
  // output sck,   // ez lehet nemkene kulon
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

reg [23:0] shr_mosi;
reg [4:0] shr_mosi_cntr=0;

reg [23:0] shr_miso;
reg [4:0] shr_miso_cntr=0;

reg [1:0] state=0;

reg spimem_wip;

reg wipreadflag=1;
reg statusreadflag=1;
reg webflag=1;
reg [3:0] wren_cntr=8;
reg [7:0] shr_wren=8'b01100000;

reg [31:0] data_in_temp;

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

always @(posedge clk or posedge rst or negedge clk) begin
  if (rst) begin
    state <= 0;
    buf_addrb <= 0;
    shr_mosi_cntr <= 0;
    shr_miso_cntr <= 0;
    wren_cntr <= 8;
    wipreadflag <= 1;
    statusreadflag <= 1;
    webflag <= 1;
    web <= 0;
    csn <= 1;
    shr_wren <= 8'b01100000;
  end

  else if (clk_rise)
  begin
    if (data_in[30] == 1'b1 && data_in[31] != 1'b1) begin   // ha foglalt, kelljen h es nem ready?
      case(state)
        2'b00:    // adatok bufferbol
        begin
          if( wren_cntr == 0)    // barmi elott beallitjuk a write enable regisztert a memoriaban
          begin
            csn <= 1'b1;        // wren beiras utani csn beallitas
            if(data_in[29] == 1'b1)         // read kell
            begin
              // shr_mosi <= {8'b00000011,1'b0,data_in[6:0],8'b00000000}; // regiszter veget feltoltjuk 0-kal, mert miertne
              shr_mosi <= {8'b00000000,data_in[6:0],1'b0,8'b11000000};
              shr_mosi_cntr <= 16;
              state <= 2'b01;
            end
            else                            // write kell
            begin
              // shr_mosi <= {8'b00000010,1'b0,data_in[6:0],data_in[14:7]};
              shr_mosi <= {data_in[14:7],data_in[6:0],1'b0,8'b01000000};
              shr_mosi_cntr <= 24;    // itt majd figyelni kell...
              state <= 2'b01;
            end
          end
        end
        2'b01:  // buffer adatok kishiftelese az spi memoriara
        begin   // ez teljesen a negedgenel van
          // if(shr_mosi_cntr != 5'b0)
          // begin
          //   if(csn == 1'b1)
          //   begin
          //     csn <= 1'b0;
          //   end
          //   mosi <= shr_mosi[0];
          //   shr_mosi <= {1'b0,shr_mosi[22:1]};
          //   shr_mosi_cntr <= shr_mosi_cntr - 1;
          // end
          // else
          // begin
          //   if(data_in[29] == 1'b1)
          //   begin
          //   state <= 2'b11; // ha olvasas van, arra rogton jon a valasz nem kell nezni, h kesze, mint az irasnal
          //   shr_miso_cntr <= 8;
          //   end
          //   else
          //   begin
          //     csn <= 1'b1;
          //     state <= 2'b10; // ha iras van
          //   end
          // end
        end

        2'b10:  // ha iras van, az spi status regiszter alapjan nezzuk, hogy kesz van e mar az iras
        begin
          // * 1 *
          if(shr_mosi_cntr == 5'b0 && wipreadflag == 1)
          begin
            // shr_mosi <= {8'b00000101,16'b0}; // regiszter veget feltoltjuk 0-kal, mert miertne
            shr_mosi <= {16'b0,8'b10100000};
            shr_mosi_cntr <= 8;
            wipreadflag <= 0;
          end

          // else if(shr_mosi_cntr != 5'b0)
          // begin
          //   mosi <= shr_mosi[0];
          //   shr_mosi <= {1'b0,shr_mosi[22:1]};
          //   shr_mosi_cntr <= shr_mosi_cntr - 1;
          //   if(csn == 1'b1)
          //   begin
          //     csn <= 1'b0;
          //   end
          // end

          // else  // jon a valasz a status regisztertol
          // else if( shr_mosi_cntr == 5'b0)

          // * 3 *
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
              shr_mosi_cntr <= shr_mosi_cntr - 1;
            end

            else    // ha mar beirtuk a status regiszter tartalmat az shr_miso regiszterbe
            begin
              // csn <= 1'b1;
              if(shr_miso[7] == 1'b0) // tehat ha az iras befejezodott
              begin
                if(webflag == 1)
                begin
                  web <= 1;
                  webflag <= 0;
                end
                else
                begin
                data_out[30:0] <= data_in[30:0];
                data_out[31] <= 1'b1; // az egesz iras ciklus ready
                wipreadflag <= 1;
                statusreadflag <= 1;
                web <= 0;
                webflag <= 1; // remelem ez igy ok
                state <= 2'b00;
                end
              end
            end
          end
        end

        2'b11:
        begin
          if(shr_miso_cntr != 0) // if(shr_mosi_cntr != 0)
          begin
            shr_miso[shr_miso_cntr-1] <= miso;
            shr_miso_cntr <= shr_miso_cntr -1;
          end
          else // shr_misoba mar ki van olvasva az spi read valasz
          begin
            if(webflag == 1)
            begin
              web <= 1;
              webflag <= 0;
              data_in_temp <= data_in;
            end
            else
            begin
              data_out[14:7] <= shr_miso[7:0];
              data_out[6:0] <= data_in_temp[6:0];
              data_out[30:15] <= data_in_temp[30:15];
              data_out[31] <= 1'b1;
              web <= 0;
              webflag <= 1;
              buf_addrb <= buf_addrb + 1'b1;
              state <= 2'b00;
            end
          end
        end
      endcase
    end
    else                                  // ha nem foglalt
    begin
      buf_addrb <= buf_addrb + 1;
    end
  end

  else if (clk_fall)
  begin
    if (data_in[30] == 1'b1 && data_in[31] != 1'b1) begin
      case(state)
        2'b00:
        begin
          if( wren_cntr != 0)
          begin
            if(csn == 1'b1)
            begin
              csn <= 1'b0;
            end
            mosi <= shr_wren[0];
            shr_wren <= {1'b0,shr_mosi[7:1]};
            shr_mosi_cntr <= shr_mosi_cntr - 1;
          end
        end
        2'b01:  // buffer adatok kishiftelese az spi memoriara
        begin
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
            state <= 2'b11; // ha olvasas van, arra rogton jon a valasz nem kell nezni, h kesze, mint az irasnal
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
        // * 2 *
        if(shr_mosi_cntr != 5'b0 && !(shr_mosi_cntr == 0  && wipreadflag == 1) )  // check
        begin
          mosi <= shr_mosi[0];
          shr_mosi <= {1'b0,shr_mosi[22:1]};
          shr_mosi_cntr <= shr_mosi_cntr - 1;
          if(csn == 1'b1)
          begin
            csn <= 1'b0;
          end
        end

        // * 4 *
        else if ( !(shr_mosi_cntr != 5'b0 && !(shr_mosi_cntr == 0  && wipreadflag == 1) ) ) // ezt lehet ki lehet szedni
        begin
          if( !( shr_miso_cntr != 0 && !(statusreadflag == 1 && shr_miso_cntr ==0) ) )
          begin
            csn <= 1'b1;
          end
        end

        2'b11: begin if(shr_miso_cntr == 0 && webflag == 0) csn <= 1; end // webflag lehuzasat mar latja a negedge elvileg
      endcase
    end
  end

end

// bufferbol parancs kiolvasasa, leforditasa, cim, adat a memoriaparancsba
// memoriaparancs hosszu shiftregiszterek
// spi jelek: sck, mosi, miso, ss
// tehat sck-t generalni kell, mosi, miso-t attol fuggoen milyen parancs van,
// cs minden ciklus elejen, kapuzassal!
// cs utan varas ???

endmodule
