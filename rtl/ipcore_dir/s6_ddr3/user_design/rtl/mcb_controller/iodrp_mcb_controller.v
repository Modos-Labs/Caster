//*****************************************************************************
// (c) Copyright 2009 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: %version
//  \   \         Application: MIG
//  /   /         Filename: iodrp_mcb_controller.v
// /___/   /\     Date Last Modified: $Date: 2011/06/02 07:17:24 $
// \   \  /  \    Date Created: Mon Feb 9 2009
//  \___\/\___\
//
//Device: Spartan6
//Design Name: DDR/DDR2/DDR3/LPDDR
//Purpose:  Xilinx reference design for IODRP controller for v0.9 device
//Reference:
//
//  Revision:      Date:  Comment
//       1.0:  3/19/09:  Initial version for IODRP_MCB read operations.
//       1.1:  4/03/09:  SLH - Added left shift for certain IOI's
// End Revision
//**********************************************************************************

`timescale 1ps/1ps

`ifdef ALTERNATE_READ
`else
  `define ALTERNATE_READ 1'b1
`endif

module iodrp_mcb_controller(
  input   wire  [7:0] memcell_address,
  input   wire  [7:0] write_data,
  output  reg   [7:0] read_data = 0,
  input   wire        rd_not_write,
  input   wire        cmd_valid,
  output  wire        rdy_busy_n,
  input   wire        use_broadcast,
  input   wire  [4:0] drp_ioi_addr,
  input   wire        sync_rst,
  input   wire        DRP_CLK,
  output  reg         DRP_CS,
  output  wire        DRP_SDI,  //output to IODRP SDI pin
  output  reg         DRP_ADD,
  output  reg         DRP_BKST,
  input   wire        DRP_SDO,   //input from IODRP SDO pin
  output  reg         MCB_UIREAD = 1'b0
  );

   reg [7:0]          memcell_addr_reg;     // Register where memcell_address is captured during the READY state
   reg [7:0]          data_reg;             // Register which stores the write data until it is ready to be shifted out
   reg [8:0]          shift_through_reg;    // The shift register which shifts out SDO and shifts in SDI.
                                            //    This register is loaded before the address or data phase, but continues to shift for a writeback of read data
   reg                load_shift_n;         // The signal which causes shift_through_reg to load the new value from data_out_mux, or continue to shift data in from DRP_SDO
   reg                addr_data_sel_n;      // The signal which indicates where the shift_through_reg should load from.  0 -> data_reg  1 -> memcell_addr_reg
   reg [2:0]          bit_cnt= 3'b0;        // The counter for which bit is being shifted during address or data phase
   reg                rd_not_write_reg;
   reg                AddressPhase;         // This is set after the first address phase has executed
   reg                DRP_CS_pre;
   reg                extra_cs;

   (* FSM_ENCODING="GRAY" *) reg [3:0] state, nextstate;

   wire [8:0]   data_out;
   reg  [8:0]   data_out_mux; // The mux which selects between data_reg and memcell_addr_reg for sending to shift_through_reg
   wire DRP_SDI_pre;          //added so that DRP_SDI output is only active when DRP_CS is active

   localparam READY             = 4'h0;
   localparam DECIDE            = 4'h1;
   localparam ADDR_PHASE        = 4'h2;
   localparam ADDR_TO_DATA_GAP  = 4'h3;
   localparam ADDR_TO_DATA_GAP2 = 4'h4;
   localparam ADDR_TO_DATA_GAP3 = 4'h5;
   localparam DATA_PHASE        = 4'h6;
   localparam ALMOST_READY      = 4'h7;
   localparam ALMOST_READY2     = 4'h8;
   localparam ALMOST_READY3     = 4'h9;

   localparam IOI_DQ0           = 5'h01;
   localparam IOI_DQ1           = 5'h00;
   localparam IOI_DQ2           = 5'h03;
   localparam IOI_DQ3           = 5'h02;
   localparam IOI_DQ4           = 5'h05;
   localparam IOI_DQ5           = 5'h04;
   localparam IOI_DQ6           = 5'h07;
   localparam IOI_DQ7           = 5'h06;
   localparam IOI_DQ8           = 5'h09;
   localparam IOI_DQ9           = 5'h08;
   localparam IOI_DQ10          = 5'h0B;
   localparam IOI_DQ11          = 5'h0A;
   localparam IOI_DQ12          = 5'h0D;
   localparam IOI_DQ13          = 5'h0C;
   localparam IOI_DQ14          = 5'h0F;
   localparam IOI_DQ15          = 5'h0E;
   localparam IOI_UDQS_CLK      = 5'h1D;
   localparam IOI_UDQS_PIN      = 5'h1C;
   localparam IOI_LDQS_CLK      = 5'h1F;
   localparam IOI_LDQS_PIN      = 5'h1E;

   //synthesis translate_off
   reg [32*8-1:0] state_ascii;
   always @ (state) begin
      case (state)
  READY     :state_ascii<="READY";
  DECIDE      :state_ascii<="DECIDE";
  ADDR_PHASE    :state_ascii<="ADDR_PHASE";
  ADDR_TO_DATA_GAP  :state_ascii<="ADDR_TO_DATA_GAP";
  ADDR_TO_DATA_GAP2 :state_ascii<="ADDR_TO_DATA_GAP2";
  ADDR_TO_DATA_GAP3 :state_ascii<="ADDR_TO_DATA_GAP3";
  DATA_PHASE    :state_ascii<="DATA_PHASE";
  ALMOST_READY    :state_ascii<="ALMOST_READY";
  ALMOST_READY2   :state_ascii<="ALMOST_READY2";
  ALMOST_READY3   :state_ascii<="ALMOST_READY3";
      endcase // case(state)
   end
   //synthesis translate_on

   /*********************************************
    *   Input Registers
    *********************************************/
   always @ (posedge DRP_CLK) begin
      if(state == READY) begin
        memcell_addr_reg <= memcell_address;
        data_reg <= write_data;
        rd_not_write_reg <= rd_not_write;
      end
   end

   assign rdy_busy_n = (state == READY);

   // The changes below are to compensate for an issue with 1.0 silicon.
   // It may still be necessary to add a clock cycle to the ADD and CS signals

//`define DRP_v1_0_FIX    // Uncomment out this line for synthesis

task shift_n_expand (
  input   [7:0] data_in,
  output  [8:0] data_out
  );

  begin
    if (data_in[0])
      data_out[1:0]  = 2'b11;
    else
      data_out[1:0]  = 2'b00;

    if (data_in[1:0] == 2'b10)
      data_out[2:1]  = 2'b11;
    else
      data_out[2:1]  = {data_in[1], data_out[1]};

    if (data_in[2:1] == 2'b10)
      data_out[3:2]  = 2'b11;
    else
      data_out[3:2]  = {data_in[2], data_out[2]};

    if (data_in[3:2] == 2'b10)
      data_out[4:3]  = 2'b11;
    else
      data_out[4:3]  = {data_in[3], data_out[3]};

    if (data_in[4:3] == 2'b10)
      data_out[5:4]  = 2'b11;
    else
      data_out[5:4]  = {data_in[4], data_out[4]};

    if (data_in[5:4] == 2'b10)
      data_out[6:5]  = 2'b11;
    else
      data_out[6:5]  = {data_in[5], data_out[5]};

    if (data_in[6:5] == 2'b10)
      data_out[7:6]  = 2'b11;
    else
      data_out[7:6]  = {data_in[6], data_out[6]};

    if (data_in[7:6] == 2'b10)
      data_out[8:7]  = 2'b11;
    else
      data_out[8:7]  = {data_in[7], data_out[7]};
  end
endtask


   always @(*) begin
    case(drp_ioi_addr)
`ifdef DRP_v1_0_FIX
      IOI_DQ0       : data_out_mux  = data_out<<1;
      IOI_DQ1       : data_out_mux  = data_out;
      IOI_DQ2       : data_out_mux  = data_out<<1;
//      IOI_DQ2       : data_out_mux  = data_out;
      IOI_DQ3       : data_out_mux  = data_out;
      IOI_DQ4       : data_out_mux  = data_out;
      IOI_DQ5       : data_out_mux  = data_out;
      IOI_DQ6       : shift_n_expand (data_out, data_out_mux);
//      IOI_DQ6       : data_out_mux  = data_out;
      IOI_DQ7       : data_out_mux  = data_out;
      IOI_DQ8       : data_out_mux  = data_out<<1;
      IOI_DQ9       : data_out_mux  = data_out;
      IOI_DQ10      : data_out_mux  = data_out<<1;
      IOI_DQ11      : data_out_mux  = data_out;
      IOI_DQ12      : data_out_mux  = data_out<<1;
      IOI_DQ13      : data_out_mux  = data_out;
      IOI_DQ14      : data_out_mux  = data_out<<1;
      IOI_DQ15      : data_out_mux  = data_out;
      IOI_UDQS_CLK  : data_out_mux  = data_out<<1;
      IOI_UDQS_PIN  : data_out_mux  = data_out<<1;
      IOI_LDQS_CLK  : data_out_mux  = data_out;
      IOI_LDQS_PIN  : data_out_mux  = data_out;
`else
`endif
      IOI_DQ0       : data_out_mux  = data_out;
      IOI_DQ1       : data_out_mux  = data_out;
      IOI_DQ2       : data_out_mux  = data_out;
      IOI_DQ3       : data_out_mux  = data_out;
      IOI_DQ4       : data_out_mux  = data_out;
      IOI_DQ5       : data_out_mux  = data_out;
      IOI_DQ6       : data_out_mux  = data_out;
      IOI_DQ7       : data_out_mux  = data_out;
      IOI_DQ8       : data_out_mux  = data_out;
      IOI_DQ9       : data_out_mux  = data_out;
      IOI_DQ10      : data_out_mux  = data_out;
      IOI_DQ11      : data_out_mux  = data_out;
      IOI_DQ12      : data_out_mux  = data_out;
      IOI_DQ13      : data_out_mux  = data_out;
      IOI_DQ14      : data_out_mux  = data_out;
      IOI_DQ15      : data_out_mux  = data_out;
      IOI_UDQS_CLK  : data_out_mux  = data_out;
      IOI_UDQS_PIN  : data_out_mux  = data_out;
      IOI_LDQS_CLK  : data_out_mux  = data_out;
      IOI_LDQS_PIN  : data_out_mux  = data_out;
      default       : data_out_mux  = data_out;
    endcase
   end


   /*********************************************
    *   Shift Registers / Bit Counter
    *********************************************/
   assign     data_out = (addr_data_sel_n)? {1'b0, memcell_addr_reg} : {1'b0, data_reg};

   always @ (posedge DRP_CLK) begin
      if(sync_rst)
        shift_through_reg <= 9'b0;
      else begin
        if (load_shift_n)     //Assume the shifter is either loading or shifting, bit 0 is shifted out first
          shift_through_reg <= data_out_mux;
        else
          shift_through_reg <= {1'b0, DRP_SDO, shift_through_reg[7:1]};
      end
   end

   always @ (posedge DRP_CLK) begin
      if (((state == ADDR_PHASE) | (state == DATA_PHASE)) & !sync_rst)
        bit_cnt <= bit_cnt + 1;
      else
        bit_cnt <= 3'b0;
   end

  always @ (posedge DRP_CLK) begin
    if(sync_rst) begin
      read_data <= 8'h00;
    end
    else begin
      if(state == ALMOST_READY3)
        read_data <= shift_through_reg;
    end
  end

  always @ (posedge DRP_CLK) begin
    if(sync_rst) begin
      AddressPhase  <= 1'b0;
    end
    else begin
      if (AddressPhase) begin
        // Keep it set until we finish the cycle
        AddressPhase <= AddressPhase && ~(state == ALMOST_READY2);
      end
      else begin
        // set the address phase when ever we finish the address phase
        AddressPhase <= (state == ADDR_PHASE) && (bit_cnt == 3'b111);
      end
    end
  end

   /*********************************************
    *   DRP Signals
    *********************************************/
   always @ (posedge DRP_CLK) begin
      DRP_ADD     <= (nextstate == ADDR_PHASE);
      DRP_CS      <= (nextstate == ADDR_PHASE) | (nextstate == DATA_PHASE);
//      DRP_CS      <= (drp_ioi_addr != IOI_DQ0) ? (nextstate == ADDR_PHASE) | (nextstate == DATA_PHASE) : (bit_cnt != 3'b111) && (nextstate == ADDR_PHASE) | (nextstate == DATA_PHASE);
      MCB_UIREAD  <= (nextstate == DATA_PHASE) && rd_not_write_reg;
      if (state == READY)
        DRP_BKST  <= use_broadcast;
   end

   assign DRP_SDI_pre = (DRP_CS)? shift_through_reg[0] : 1'b0;  //if DRP_CS is inactive, just drive 0 out - this is a possible place to pipeline for increased performance
   assign DRP_SDI = (rd_not_write_reg & DRP_CS & !DRP_ADD)? DRP_SDO : DRP_SDI_pre; //If reading, then feed SDI back out SDO - this is a possible place to pipeline for increased performance


   /*********************************************
    *   State Machine
    *********************************************/
  always @ (*) begin
    addr_data_sel_n = 1'b0;
    load_shift_n = 1'b0;
    case (state)
      READY:  begin
         load_shift_n = 0;
         if(cmd_valid)
          nextstate = DECIDE;
         else
          nextstate = READY;
        end
      DECIDE: begin
          load_shift_n = 1;
          addr_data_sel_n = 1;
          nextstate = ADDR_PHASE;
        end
      ADDR_PHASE: begin
         load_shift_n = 0;
         if(&bit_cnt[2:0])
           if (`ALTERNATE_READ && rd_not_write_reg)
             if (AddressPhase)
               // After the second pass go to end of statemachine
               nextstate = ALMOST_READY;
             else
               // execute a second address phase for the alternative access method.
               nextstate = DECIDE;
           else
            nextstate = ADDR_TO_DATA_GAP;
         else
          nextstate = ADDR_PHASE;
        end
      ADDR_TO_DATA_GAP: begin
          load_shift_n = 1;
          nextstate = ADDR_TO_DATA_GAP2;
        end
      ADDR_TO_DATA_GAP2: begin
         load_shift_n = 1;
         nextstate = ADDR_TO_DATA_GAP3;
        end
      ADDR_TO_DATA_GAP3: begin
         load_shift_n = 1;
         nextstate = DATA_PHASE;
        end
      DATA_PHASE: begin
         load_shift_n = 0;
         if(&bit_cnt)
            nextstate = ALMOST_READY;
         else
          nextstate = DATA_PHASE;
        end
      ALMOST_READY: begin
         load_shift_n = 0;
         nextstate = ALMOST_READY2;
         end
      ALMOST_READY2: begin
         load_shift_n = 0;
         nextstate = ALMOST_READY3;
         end
      ALMOST_READY3: begin
         load_shift_n = 0;
         nextstate = READY;
         end
      default: begin
         load_shift_n = 0;
         nextstate = READY;
       end
    endcase
  end

  always @ (posedge DRP_CLK) begin
    if(sync_rst)
      state <= READY;
    else
      state <= nextstate;
   end

endmodule
