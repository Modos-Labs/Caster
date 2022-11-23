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
//  /   /         Filename: iodrp_controller.v
// /___/   /\     Date Last Modified: $Date: 2011/06/02 07:17:24 $
// \   \  /  \    Date Created: Mon Feb 9 2009
//  \___\/\___\
//
//Device: Spartan6
//Design Name: DDR/DDR2/DDR3/LPDDR
//Purpose:  Xilinx reference design for IODRP controller for v0.9 device
//
//Reference:
//
//    Revision: Date:       Comment
//    1.0:      02/06/09:   Initial version for MIG wrapper.
//    1.1:      02/01/09:   updates to indentations.
//    1.2:      02/12/09:   changed non-blocking assignments to blocking ones
//                          for state machine always block.  Also, assigned
//                          intial value to load_shift_n to avoid latch
// End Revision
//*******************************************************************************

`timescale 1ps/1ps

module iodrp_controller(
  input   wire  [7:0] memcell_address,
  input   wire  [7:0] write_data,
  output  reg   [7:0] read_data,
  input   wire        rd_not_write,
  input   wire        cmd_valid,
  output  wire        rdy_busy_n,
  input   wire        use_broadcast,
  input   wire        sync_rst,
  input   wire        DRP_CLK,
  output  reg         DRP_CS,
  output  wire        DRP_SDI,  //output to IODRP SDI pin
  output  reg         DRP_ADD,
  output  reg         DRP_BKST,
  input   wire        DRP_SDO   //input from IODRP SDO pin
  );

  reg   [7:0]   memcell_addr_reg;     // Register where memcell_address is captured during the READY state
  reg   [7:0]   data_reg;             // Register which stores the write data until it is ready to be shifted out
  reg   [7:0]   shift_through_reg;    // The shift register which shifts out SDO and shifts in SDI.
                                      // This register is loaded before the address or data phase, but continues
                                      // to shift for a writeback of read data
  reg           load_shift_n;         // The signal which causes shift_through_reg to load the new value from data_out_mux, or continue to shift data in from DRP_SDO
  reg           addr_data_sel_n;      // The signal which indicates where the shift_through_reg should load from.  0 -> data_reg  1 -> memcell_addr_reg
  reg   [2:0]   bit_cnt;              // The counter for which bit is being shifted during address or data phase
  reg           rd_not_write_reg;
  reg           AddressPhase;         // This is set after the first address phase has executed
  reg           capture_read_data;

  (* FSM_ENCODING="one-hot" *) reg [2:0] state, nextstate;

  wire  [7:0]   data_out_mux;         // The mux which selects between data_reg and memcell_addr_reg for sending to shift_through_reg
  wire          DRP_SDI_pre;          // added so that DRP_SDI output is only active when DRP_CS is active

  localparam  READY             = 3'h0;
  localparam  DECIDE            = 3'h1;
  localparam  ADDR_PHASE        = 3'h2;
  localparam  ADDR_TO_DATA_GAP  = 3'h3;
  localparam  ADDR_TO_DATA_GAP2 = 3'h4;
  localparam  ADDR_TO_DATA_GAP3 = 3'h5;
  localparam  DATA_PHASE        = 3'h6;
  localparam  ALMOST_READY      = 3'h7;

  localparam  IOI_DQ0           = 5'h01;
  localparam  IOI_DQ1           = 5'h00;
  localparam  IOI_DQ2           = 5'h03;
  localparam  IOI_DQ3           = 5'h02;
  localparam  IOI_DQ4           = 5'h05;
  localparam  IOI_DQ5           = 5'h04;
  localparam  IOI_DQ6           = 5'h07;
  localparam  IOI_DQ7           = 5'h06;
  localparam  IOI_DQ8           = 5'h09;
  localparam  IOI_DQ9           = 5'h08;
  localparam  IOI_DQ10          = 5'h0B;
  localparam  IOI_DQ11          = 5'h0A;
  localparam  IOI_DQ12          = 5'h0D;
  localparam  IOI_DQ13          = 5'h0C;
  localparam  IOI_DQ14          = 5'h0F;
  localparam  IOI_DQ15          = 5'h0E;
  localparam  IOI_UDQS_CLK      = 5'h1D;
  localparam  IOI_UDQS_PIN      = 5'h1C;
  localparam  IOI_LDQS_CLK      = 5'h1F;
  localparam  IOI_LDQS_PIN      = 5'h1E;
  //synthesis translate_off
  reg   [32*8-1:0]  state_ascii;
  always @ (state) begin
    case (state)
      READY             :state_ascii  <= "READY";
      DECIDE            :state_ascii  <= "DECIDE";
      ADDR_PHASE        :state_ascii  <= "ADDR_PHASE";
      ADDR_TO_DATA_GAP  :state_ascii  <= "ADDR_TO_DATA_GAP";
      ADDR_TO_DATA_GAP2 :state_ascii  <= "ADDR_TO_DATA_GAP2";
      ADDR_TO_DATA_GAP3 :state_ascii  <= "ADDR_TO_DATA_GAP3";
      DATA_PHASE        :state_ascii  <= "DATA_PHASE";
      ALMOST_READY      :state_ascii  <= "ALMOST_READY";
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


  /*********************************************
   *   Shift Registers / Bit Counter
   *********************************************/
  assign data_out_mux = addr_data_sel_n ? memcell_addr_reg : data_reg;

  always @ (posedge DRP_CLK) begin
    if(sync_rst)
      shift_through_reg <= 8'b0;
    else begin
      if (load_shift_n)     //Assume the shifter is either loading or shifting, bit 0 is shifted out first
        shift_through_reg <= data_out_mux;
      else
        shift_through_reg <= {DRP_SDO, shift_through_reg[7:1]};
    end
  end

  always @ (posedge DRP_CLK) begin
    if (((state == ADDR_PHASE) | (state == DATA_PHASE)) & !sync_rst)
      bit_cnt <= bit_cnt + 1;
    else
      bit_cnt <= 3'b000;
  end

  always @ (posedge DRP_CLK) begin
    if(sync_rst) begin
      read_data   <= 8'h00;
//     capture_read_data <= 1'b0;
    end
    else begin
//       capture_read_data <= (state == DATA_PHASE);
//       if(capture_read_data)
      if(state == ALMOST_READY)
        read_data <= shift_through_reg;
//      else
//        read_data <= read_data;
    end
  end

  always @ (posedge DRP_CLK) begin
    if(sync_rst) begin
      AddressPhase  <= 1'b0;
    end
    else begin
      if (AddressPhase) begin
        // Keep it set until we finish the cycle
        AddressPhase <= AddressPhase && ~(state == ALMOST_READY);
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
    if (state == READY)
      DRP_BKST  <= use_broadcast;
  end

//  assign DRP_SDI_pre  = (DRP_CS)? shift_through_reg[0] : 1'b0;  //if DRP_CS is inactive, just drive 0 out - this is a possible place to pipeline for increased performance
//  assign DRP_SDI      = (rd_not_write_reg & DRP_CS & !DRP_ADD)? DRP_SDO : DRP_SDI_pre; //If reading, then feed SDI back out SDO - this is a possible place to pipeline for increased performance
  assign DRP_SDI = shift_through_reg[0]; // The new read method only requires that we shift out the address and the write data

  /*********************************************
   *   State Machine
   *********************************************/
  always @ (*) begin
    addr_data_sel_n = 1'b0;
    load_shift_n    = 1'b0;
    case (state)
      READY:  begin
        if(cmd_valid)
          nextstate   = DECIDE;
        else
          nextstate   = READY;
      end
      DECIDE: begin
        load_shift_n    = 1;
        addr_data_sel_n = 1;
        nextstate       = ADDR_PHASE;
      end
      ADDR_PHASE: begin
        if(&bit_cnt)
          if (rd_not_write_reg)
            if (AddressPhase)
              // After the second pass go to end of statemachine
              nextstate = ALMOST_READY;
            else
              // execute a second address phase for the read access.
              nextstate = DECIDE;
          else
            nextstate = ADDR_TO_DATA_GAP;
        else
          nextstate   = ADDR_PHASE;
      end
      ADDR_TO_DATA_GAP: begin
        load_shift_n  = 1;
        nextstate     = ADDR_TO_DATA_GAP2;
      end
      ADDR_TO_DATA_GAP2: begin
        load_shift_n  = 1;
        nextstate     = ADDR_TO_DATA_GAP3;
      end
      ADDR_TO_DATA_GAP3: begin
        load_shift_n  = 1;
        nextstate     = DATA_PHASE;
      end
      DATA_PHASE: begin
        if(&bit_cnt)
          nextstate   = ALMOST_READY;
        else
          nextstate   = DATA_PHASE;
      end
      ALMOST_READY: begin
        nextstate     = READY;
      end
      default: begin
        nextstate     = READY;
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
