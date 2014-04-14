// *******************************************************************************************************
// **                                                                                                   **
// **   25LC010A.v - 25LC010A 1K-BIT SPI SERIAL EEPROM (VCC = +2.5V TO +5.5V)                           **
// **                                                                                                   **
// *******************************************************************************************************
// **                                                                                                   **
// **                   This information is distributed under license from Young Engineering.           **
// **                              COPYRIGHT (c) 2006 YOUNG ENGINEERING                                 **
// **                                      ALL RIGHTS RESERVED                                          **
// **                                                                                                   **
// **                                                                                                   **
// **   Young Engineering provides design expertise for the digital world                               **
// **   Started in 1990, Young Engineering offers products and services for your electronic design      **
// **   project.  We have the expertise in PCB, FPGA, ASIC, firmware, and software design.              **
// **   From concept to prototype to production, we can help you.                                       **
// **                                                                                                   **
// **   http://www.young-engineering.com/                                                               **
// **                                                                                                   **
// *******************************************************************************************************
// **                                                                                                   **
// **   This information is provided to you for your convenience and use with Microchip products only.  **
// **   Microchip disclaims all liability arising from this information and its use.                    **
// **                                                                                                   **
// **   THIS INFORMATION IS PROVIDED "AS IS." MICROCHIP MAKES NO REPRESENTATION OR WARRANTIES OF        **
// **   ANY KIND WHETHER EXPRESS OR IMPLIED, WRITTEN OR ORAL, STATUTORY OR OTHERWISE, RELATED TO        **
// **   THE INFORMATION PROVIDED TO YOU, INCLUDING BUT NOT LIMITED TO ITS CONDITION, QUALITY,           **
// **   PERFORMANCE, MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR PURPOSE.                         **
// **   MICROCHIP IS NOT LIABLE, UNDER ANY CIRCUMSTANCES, FOR SPECIAL, INCIDENTAL OR CONSEQUENTIAL      **
// **   DAMAGES, FOR ANY REASON WHATSOEVER.                                                             **
// **                                                                                                   **
// **   It is your responsibility to ensure that your application meets with your specifications.       **
// **                                                                                                   **
// *******************************************************************************************************
// **                                                                                                   **
// **   Revision       : 1.2                                                                            **
// **   Modified Date  : 06/05/2006                                                                     **
// **   Revision History:                                                                               **
// **                                                                                                   **
// **   02/01/2006:  Initial design                                                                     **
// **   03/10/2006:  Modified the write logic to update at the end of the write cycle.                  **
// **   06/05/2006:  Converted instruction value parameters to macro definitions.                       **
// **                Modified output data shifter to allow for continuous status register reads.        **
// **                Corrected timing checks to reference proper clock edges.                           **
// **                Added tCLD & tCLE timing checks.                                                   **
// **                Changed the legal information in the header                                        **
// **                                                                                                   **
// *******************************************************************************************************
// **                                       TABLE OF CONTENTS                                           **
// *******************************************************************************************************
// **---------------------------------------------------------------------------------------------------**
// **   DECLARATIONS                                                                                    **
// **---------------------------------------------------------------------------------------------------**
// **---------------------------------------------------------------------------------------------------**
// **   INITIALIZATION                                                                                  **
// **---------------------------------------------------------------------------------------------------**
// **---------------------------------------------------------------------------------------------------**
// **   CORE LOGIC                                                                                      **
// **---------------------------------------------------------------------------------------------------**
// **   1.01:  Internal Reset Logic                                                                     **
// **   1.02:  Input Data Shifter                                                                       **
// **   1.03:  Bit Clock Counter                                                                        **
// **   1.04:  Instruction Register                                                                     **
// **   1.05:  Address Register                                                                         **
// **   1.06:  Block Protect Bits                                                                       **
// **   1.07:  Write Data Buffer                                                                        **
// **   1.08:  Write Enable Bit                                                                         **
// **   1.09:  Write Cycle Processor                                                                    **
// **   1.10:  Output Data Shifter                                                                      **
// **   1.11:  Output Data Buffer                                                                       **
// **                                                                                                   **
// **---------------------------------------------------------------------------------------------------**
// **   DEBUG LOGIC                                                                                     **
// **---------------------------------------------------------------------------------------------------**
// **   2.01:  Memory Data Bytes                                                                        **
// **   2.02:  Page Buffer Bytes                                                                        **
// **                                                                                                   **
// **---------------------------------------------------------------------------------------------------**
// **   TIMING CHECKS                                                                                   **
// **---------------------------------------------------------------------------------------------------**
// **                                                                                                   **
// *******************************************************************************************************


`timescale 1ns/10ps

module M25LC010A (SI, SO, SCK, CS_N, WP_N, HOLD_N, RESET);

   input                SI;                             // serial data input
   input                SCK;                            // serial data clock

   input                CS_N;                           // chip select - active low
   input                WP_N;                           // write protect pin - active low

   input                HOLD_N;                         // interface suspend - active low

   input                RESET;                          // model reset/power-on reset

   output               SO;                             // serial data output


// *******************************************************************************************************
// **   DECLARATIONS                                                                                    **
// *******************************************************************************************************

   reg  [07:00]         DataShifterI;                   // serial input data shifter
   reg  [07:00]         DataShifterO;                   // serial output data shifter
   reg  [31:00]         BitCounter;                     // serial input bit counter
   reg  [07:00]         InstRegister;                   // instruction register
   reg  [07:00]         AddrRegister;                   // address register

   wire                 InstructionREAD;                // decoded instruction byte
   wire                 InstructionRDSR;                // decoded instruction byte
   wire                 InstructionWRSR;                // decoded instruction byte
   wire                 InstructionWRDI;                // decoded instruction byte
   wire                 InstructionWREN;                // decoded instruction byte
   wire                 InstructionWRITE;               // decoded instruction byte

   reg  [07:00]         WriteBuffer [0:15];             // 16-byte page write buffer
   reg  [03:00]         WritePointer;                   // page buffer pointer
   reg  [04:00]         WriteCounter;                   // byte write counter

   reg                  WriteEnable;                    // memory write enable bit
   wire                 RstWriteEnable;                 // asynchronous reset
   wire                 SetWriteEnable;                 // register set
   wire                 ClrWriteEnable;                 // register clear

   reg                  WriteActive;                    // write operation in progress

   reg                  BlockProtect0;                  // memory block write protect
   reg                  BlockProtect1;                  // memory block write protect
   reg                  BlockProtect0_New;              // memory data to be written
   reg                  BlockProtect1_New;              // memory data to be written

   reg  [03:00]         PageAddress;                    // page buffer address
   reg  [06:00]         BaseAddress;                    // memory write base address
   reg  [06:00]         MemWrAddress;                   // memory write address
   reg  [06:00]         MemRdAddress;                   // memory read address

   reg  [07:00]         MemoryBlock [0:127];            // EEPROM data memory array (128x8)

   reg                  SO_DO;                          // serial output data - data
   wire                 SO_OE;                          // serial output data - output enable

   reg                  SO_Enable;                      // serial data output enable

   wire                 OutputEnable1;                  // timing accurate output enable
   wire                 OutputEnable2;                  // timing accurate output enable
   wire                 OutputEnable3;                  // timing accurate output enable

   integer              LoopIndex;                      // iterative loop index

   integer              tWC;                            // timing parameter
   integer              tV;                             // timing parameter
   integer              tHZ;                            // timing parameter
   integer              tHV;                            // timing parameter
   integer              tDIS;                           // timing parameter

`define PAGE_SIZE 16                                    // 16-byte page size
`define WREN  3'b110                                    // Write Enable instruction
`define READ  3'b011                                    // Read instruction
`define WRDI  3'b100                                    // Write Disable instruction
`define WRSR  3'b001                                    // Write Status Register instruction
`define WRITE 3'b010                                    // Write instruction
`define RDSR  3'b101                                    // Read Status Register instruction

// *******************************************************************************************************
// **   INITIALIZATION                                                                                  **
// *******************************************************************************************************

   initial begin
      `ifdef VCC_2_5V_TO_4_5V
         tWC  = 5000000;                                // memory write cycle time
         tV   = 100;                                    // output valid from SCK low
         tHZ  = 60;                                     // HOLD_N low to output high-Z
         tHV  = 60;                                     // HOLD_N high to output valid
         tDIS = 80;                                     // CS_N high to output disable
      `else
      `ifdef VCC_4_5V_TO_5_5V
         tWC  = 5000000;                                // memory write cycle time
         tV   = 50;                                     // output valid from SCK low
         tHZ  = 30;                                     // HOLD_N low to output high-Z
         tHV  = 30;                                     // HOLD_N high to output valid
         tDIS = 40;                                     // CS_N high to output disable
      `else
         tWC  = 5000000;                                // memory write cycle time
         tV   = 50;                                     // output valid from SCK low
         tHZ  = 30;                                     // HOLD_N low to output high-Z
         tHV  = 30;                                     // HOLD_N high to output valid
         tDIS = 40;                                     // CS_N high to output disable
      `endif
      `endif
   end

   initial begin
      BlockProtect0 = 0;
      BlockProtect1 = 0;

      WriteActive = 0;
      WriteEnable = 0;
   end


// *******************************************************************************************************
// **   CORE LOGIC                                                                                      **
// *******************************************************************************************************
// -------------------------------------------------------------------------------------------------------
//      1.01:  Internal Reset Logic
// -------------------------------------------------------------------------------------------------------

   always @(negedge CS_N) BitCounter   <= 0;
   always @(negedge CS_N) SO_Enable    <= 0;
   always @(negedge CS_N) if (!WriteActive) WritePointer <= 0;
   always @(negedge CS_N) if (!WriteActive) WriteCounter <= 0;

// -------------------------------------------------------------------------------------------------------
//      1.02:  Input Data Shifter
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCK) begin
      if (HOLD_N == 1) begin
         if (CS_N == 0)         DataShifterI <= {DataShifterI[6:0],SI};
      end
   end

// -------------------------------------------------------------------------------------------------------
//      1.03:  Bit Clock Counter
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCK) begin
      if (HOLD_N == 1) begin
         if (CS_N == 0)         BitCounter <= BitCounter + 1;
      end
   end

// -------------------------------------------------------------------------------------------------------
//      1.04:  Instruction Register
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCK) begin
      if (HOLD_N == 1) begin
         if (BitCounter == 7)   InstRegister <= {DataShifterI[6:0],SI};
      end
   end

   assign InstructionREAD  = (InstRegister[7:4] == 0) & (InstRegister[2:0] == `READ);
   assign InstructionRDSR  = (InstRegister[7:4] == 0) & (InstRegister[2:0] == `RDSR);
   assign InstructionWRSR  = (InstRegister[7:4] == 0) & (InstRegister[2:0] == `WRSR);
   assign InstructionWRDI  = (InstRegister[7:4] == 0) & (InstRegister[2:0] == `WRDI);
   assign InstructionWREN  = (InstRegister[7:4] == 0) & (InstRegister[2:0] == `WREN);
   assign InstructionWRITE = (InstRegister[7:4] == 0) & (InstRegister[2:0] == `WRITE);

// -------------------------------------------------------------------------------------------------------
//      1.05:  Address Register
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCK) begin
      if (HOLD_N == 1) begin
         if ((BitCounter == 15) & !WriteActive) AddrRegister <= {DataShifterI[6:0],SI};
      end
   end

// -------------------------------------------------------------------------------------------------------
//      1.06:  Block Protect Bits
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCK) begin
      if (HOLD_N == 1) begin
         if ((BitCounter == 15) & InstructionWRSR & WriteEnable & !WriteActive) begin
            BlockProtect1_New <= DataShifterI[02];
            BlockProtect0_New <= DataShifterI[01];
         end
      end
   end

// -------------------------------------------------------------------------------------------------------
//      1.07:  Write Data Buffer
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCK) begin
      if (HOLD_N == 1) begin
         if ((BitCounter >= 23) & (BitCounter[2:0] == 7) & InstructionWRITE & WriteEnable & !WriteActive) begin
            WriteBuffer[WritePointer] <= {DataShifterI[6:0],SI};

            WritePointer <= WritePointer + 1;
            if (WriteCounter < `PAGE_SIZE) WriteCounter <= WriteCounter + 1;
         end
      end
   end

// -------------------------------------------------------------------------------------------------------
//      1.08:  Write Enable Bit
// -------------------------------------------------------------------------------------------------------

   always @(posedge CS_N or posedge RstWriteEnable) begin
      if (RstWriteEnable)       WriteEnable <= 0;
      else if (SetWriteEnable)  WriteEnable <= 1;
      else if (ClrWriteEnable)  WriteEnable <= 0;
   end

   assign RstWriteEnable = RESET | (WP_N == 0);

   assign SetWriteEnable = (BitCounter == 8) & InstructionWREN & !WriteActive;
   assign ClrWriteEnable = (BitCounter == 8) & InstructionWRDI & !WriteActive;

// -------------------------------------------------------------------------------------------------------
//      1.09:  Write Cycle Processor
// -------------------------------------------------------------------------------------------------------

   always @(posedge CS_N) begin
      if ((BitCounter == 16) & (BitCounter[2:0] == 0) & InstructionWRSR  & WriteEnable & !WriteActive) begin
         WriteActive = 1;
         #(tWC);

         BlockProtect1 = BlockProtect1_New;
         BlockProtect0 = BlockProtect0_New;

         WriteActive = 0;
         WriteEnable = 0;
      end
      if ((BitCounter >= 24) & (BitCounter[2:0] == 0) & InstructionWRITE & WriteEnable & !WriteActive) begin
         for (LoopIndex = 0; LoopIndex < WriteCounter; LoopIndex = LoopIndex + 1) begin
            BaseAddress = {AddrRegister[6:4],4'h0};
            PageAddress = (AddrRegister[3:0] + LoopIndex);

            MemWrAddress = {BaseAddress[6:4],PageAddress[3:0]};

            if ({BlockProtect1,BlockProtect0} == 2'b00) begin
               WriteActive = 1;
            end
            if ({BlockProtect1,BlockProtect0} == 2'b01) begin
               if ((MemWrAddress >= 7'h60) && (MemWrAddress <= 7'h7F)) begin
                  // write protected region
               end
               else begin
                  WriteActive = 1;
               end
            end
            if ({BlockProtect1,BlockProtect0} == 2'b10) begin
               if ((MemWrAddress >= 7'h40) && (MemWrAddress <= 7'h7F)) begin
                  // write protected region
               end
               else begin
                  WriteActive = 1;
               end
            end
            if ({BlockProtect1,BlockProtect0} == 2'b11) begin
               if ((MemWrAddress >= 7'h00) && (MemWrAddress <= 7'h7F)) begin
                  // write protected region
               end
               else begin
                  WriteActive = 1;
               end
            end
         end

         if (WriteActive) begin
            #(tWC);

            for (LoopIndex = 0; LoopIndex < WriteCounter; LoopIndex = LoopIndex + 1) begin
               BaseAddress = {AddrRegister[6:4],4'h0};
               PageAddress = (AddrRegister[3:0] + LoopIndex);

               MemWrAddress = {BaseAddress[6:4],PageAddress[3:0]};

               if ({BlockProtect1,BlockProtect0} == 2'b00) begin
                  MemoryBlock[MemWrAddress] = WriteBuffer[LoopIndex];
               end
               if ({BlockProtect1,BlockProtect0} == 2'b01) begin
                  if ((MemWrAddress >= 7'h60) && (MemWrAddress <= 7'h7F)) begin
                     // write protected region
                  end
                  else begin
                     MemoryBlock[MemWrAddress] = WriteBuffer[LoopIndex];
                  end
               end
               if ({BlockProtect1,BlockProtect0} == 2'b10) begin
                  if ((MemWrAddress >= 7'h40) && (MemWrAddress <= 7'h7F)) begin
                     // write protected region
                  end
                  else begin
                     MemoryBlock[MemWrAddress] = WriteBuffer[LoopIndex];
                  end
               end
               if ({BlockProtect1,BlockProtect0} == 2'b11) begin
                  if ((MemWrAddress >= 7'h00) && (MemWrAddress <= 7'h7F)) begin
                     // write protected region
                  end
                  else begin
                     MemoryBlock[MemWrAddress] = WriteBuffer[LoopIndex];
                  end
               end
            end
         end

         WriteActive = 0;
         WriteEnable = 0;
      end
   end

// -------------------------------------------------------------------------------------------------------
//      1.10:  Output Data Shifter
// -------------------------------------------------------------------------------------------------------

   always @(negedge SCK) begin
      if (HOLD_N == 1) begin
         if ((BitCounter >= 16) & (BitCounter[2:0] == 0) & InstructionREAD & !WriteActive) begin
            if (BitCounter == 16) begin
               DataShifterO <= MemoryBlock[AddrRegister[6:0]];
               MemRdAddress <= AddrRegister + 1;
               SO_Enable    <= 1;
            end
            else begin
               DataShifterO <= MemoryBlock[MemRdAddress[6:0]];
               MemRdAddress <= MemRdAddress + 1;
            end
         end
         else if ((BitCounter > 7) & (BitCounter[2:0] == 3'b000) & InstructionRDSR) begin
            DataShifterO <= {4'b0000,BlockProtect1,BlockProtect0,WriteEnable,WriteActive};
            SO_Enable    <= 1;
         end
         else begin
            DataShifterO <= DataShifterO << 1;
         end
      end
   end

// -------------------------------------------------------------------------------------------------------
//      1.11:  Output Data Buffer
// -------------------------------------------------------------------------------------------------------

   bufif1 (SO, SO_DO, SO_OE);

   always @(DataShifterO) SO_DO <= #(tV) DataShifterO[07];

   bufif1 #(tV,0)    (OutputEnable1, SO_Enable, 1);
   notif1 #(tDIS)    (OutputEnable2, CS_N,   1);
   bufif1 #(tHV,tHZ) (OutputEnable3, HOLD_N, 1);

   assign SO_OE = OutputEnable1 & OutputEnable2 & OutputEnable3;


// *******************************************************************************************************
// **   DEBUG LOGIC                                                                                     **
// *******************************************************************************************************
// -------------------------------------------------------------------------------------------------------
//      2.01:  Memory Data Bytes
// -------------------------------------------------------------------------------------------------------

   wire [07:00] MemoryByte00 = MemoryBlock[000];
   wire [07:00] MemoryByte01 = MemoryBlock[001];
   wire [07:00] MemoryByte02 = MemoryBlock[002];
   wire [07:00] MemoryByte03 = MemoryBlock[003];
   wire [07:00] MemoryByte04 = MemoryBlock[004];
   wire [07:00] MemoryByte05 = MemoryBlock[005];
   wire [07:00] MemoryByte06 = MemoryBlock[006];
   wire [07:00] MemoryByte07 = MemoryBlock[007];
   wire [07:00] MemoryByte08 = MemoryBlock[008];
   wire [07:00] MemoryByte09 = MemoryBlock[009];
   wire [07:00] MemoryByte0A = MemoryBlock[010];
   wire [07:00] MemoryByte0B = MemoryBlock[011];
   wire [07:00] MemoryByte0C = MemoryBlock[012];
   wire [07:00] MemoryByte0D = MemoryBlock[013];
   wire [07:00] MemoryByte0E = MemoryBlock[014];
   wire [07:00] MemoryByte0F = MemoryBlock[015];

   wire [07:00] MemoryByte70 = MemoryBlock[112];
   wire [07:00] MemoryByte71 = MemoryBlock[113];
   wire [07:00] MemoryByte72 = MemoryBlock[114];
   wire [07:00] MemoryByte73 = MemoryBlock[115];
   wire [07:00] MemoryByte74 = MemoryBlock[116];
   wire [07:00] MemoryByte75 = MemoryBlock[117];
   wire [07:00] MemoryByte76 = MemoryBlock[118];
   wire [07:00] MemoryByte77 = MemoryBlock[119];
   wire [07:00] MemoryByte78 = MemoryBlock[120];
   wire [07:00] MemoryByte79 = MemoryBlock[121];
   wire [07:00] MemoryByte7A = MemoryBlock[122];
   wire [07:00] MemoryByte7B = MemoryBlock[123];
   wire [07:00] MemoryByte7C = MemoryBlock[124];
   wire [07:00] MemoryByte7D = MemoryBlock[125];
   wire [07:00] MemoryByte7E = MemoryBlock[126];
   wire [07:00] MemoryByte7F = MemoryBlock[127];

// -------------------------------------------------------------------------------------------------------
//      2.02:  Page Buffer Bytes
// -------------------------------------------------------------------------------------------------------

   wire [07:00] PageBuffer00 = WriteBuffer[00];
   wire [07:00] PageBuffer01 = WriteBuffer[01];
   wire [07:00] PageBuffer02 = WriteBuffer[02];
   wire [07:00] PageBuffer03 = WriteBuffer[03];
   wire [07:00] PageBuffer04 = WriteBuffer[04];
   wire [07:00] PageBuffer05 = WriteBuffer[05];
   wire [07:00] PageBuffer06 = WriteBuffer[06];
   wire [07:00] PageBuffer07 = WriteBuffer[07];
   wire [07:00] PageBuffer08 = WriteBuffer[08];
   wire [07:00] PageBuffer09 = WriteBuffer[09];
   wire [07:00] PageBuffer0A = WriteBuffer[10];
   wire [07:00] PageBuffer0B = WriteBuffer[11];
   wire [07:00] PageBuffer0C = WriteBuffer[12];
   wire [07:00] PageBuffer0D = WriteBuffer[13];
   wire [07:00] PageBuffer0E = WriteBuffer[14];
   wire [07:00] PageBuffer0F = WriteBuffer[15];


// *******************************************************************************************************
// **   TIMING CHECKS                                                                                   **
// *******************************************************************************************************

   wire TimingCheckEnable = (RESET == 0) & (CS_N == 0);

   specify
      `ifdef VCC_2_5V_TO_4_5V
         specparam
            tHI  = 100,                                 // Clock high time
            tLO  = 100,                                 // Clock low time
            tSU  =  20,                                 // Data setup time
            tHD  =  40,                                 // Data hold time
            tHS  =  40,                                 // HOLD_N setup time
            tHH  =  40,                                 // HOLD_N hold time
            tCSD =  50,                                 // CS_N disable time
            tCSS = 100,                                 // CS_N setup time
            tCSH = 200,                                 // CS_N hold time
            tCLD = 50,                                  // Clock delay time
            tCLE = 50;                                  // Clock enable time
      `else
      `ifdef VCC_4_5V_TO_5_5V
         specparam
            tHI  =  50,                                 // Clock high time
            tLO  =  50,                                 // Clock low time
            tSU  =  10,                                 // Data setup time
            tHD  =  20,                                 // Data hold time
            tHS  =  20,                                 // HOLD_N setup time
            tHH  =  20,                                 // HOLD_N hold time
            tCSD =  50,                                 // CS_N disable time
            tCSS =  50,                                 // CS_N setup time
            tCSH = 100,                                 // CS_N hold time
            tCLD = 50,                                  // Clock delay time
            tCLE = 50;                                  // Clock enable time
      `else
         specparam
            tHI  =  50,                                 // Clock high time
            tLO  =  50,                                 // Clock low time
            tSU  =  10,                                 // Data setup time
            tHD  =  20,                                 // Data hold time
            tHS  =  20,                                 // HOLD_N setup time
            tHH  =  20,                                 // HOLD_N hold time
            tCSD =  50,                                 // CS_N disable time
            tCSS =  50,                                 // CS_N setup time
            tCSH = 100,                                 // CS_N hold time
            tCLD = 50,                                  // Clock delay time
            tCLE = 50;                                  // Clock enable time
      `endif
      `endif

      $width (posedge SCK,  tHI);
      $width (negedge SCK,  tLO);
      $width (posedge CS_N, tCSD);

      $setup (SI, posedge SCK &&& TimingCheckEnable, tSU);
      $setup (negedge CS_N, posedge SCK &&& TimingCheckEnable, tCSS);
      $setup (negedge SCK, negedge HOLD_N &&& TimingCheckEnable, tHS);
      $setup (posedge CS_N, posedge SCK &&& TimingCheckEnable, tCLD);

      $hold  (posedge SCK    &&& TimingCheckEnable, SI,   tHD);
      $hold  (posedge SCK    &&& TimingCheckEnable, posedge CS_N, tCSH);
      $hold  (posedge HOLD_N &&& TimingCheckEnable, posedge SCK,  tHH);
      $hold  (posedge SCK    &&& TimingCheckEnable, negedge CS_N, tCLE);
  endspecify

endmodule
