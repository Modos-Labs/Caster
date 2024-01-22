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
//  /   /         Filename: mcb_soft_calibration_top.v
// /___/   /\     Date Last Modified: $Date: 2011/06/02 07:17:25 $
// \   \  /  \    Date Created: Mon Feb 9 2009
//  \___\/\___\
//
//Device: Spartan6
//Design Name: DDR/DDR2/DDR3/LPDDR
//Purpose:  Xilinx reference design top-level simulation
//           wrapper file for input termination calibration
//Reference:
//
//  Revision:      Date:  Comment
//     1.0:  2/06/09:  Initial version for MIG wrapper.
//     1.1:  3/16/09: Added pll_lock port, for using it to gate reset
//     1.2: 6/06/09:  Removed MCB_UIDQCOUNT.
//     1.3: 6/18/09:  corrected/changed MCB_SYSRST to be an output port
//     1.4: 6/24/09:  gave RZQ and ZIO each their own unique ADD and SDI nets
//     1.5: 10/08/09: removed INCDEC_TRESHOLD parameter - making it a localparam inside mcb_soft_calibration
//     1.6: 02/04/09: Added condition generate statmenet for ZIO pin.	   
//     1.7: 04/12/10: Added CKE_Train signal to fix DDR2 init wait .
//
// End Revision
//**********************************************************************************

`timescale 1ps/1ps

module mcb_soft_calibration_top  # (
  parameter       C_MEM_TZQINIT_MAXCNT  = 10'h512,  // DDR3 Minimum delay between resets
  parameter       C_MC_CALIBRATION_MODE = "CALIBRATION", // if set to CALIBRATION will reset DQS IDELAY to DQS_NUMERATOR/DQS_DENOMINATOR local_param values, and does dynamic recal,
                                                         // if set to NOCALIBRATION then defaults to hard cal blocks setting of C_MC_CALBRATION_DELAY *and* no dynamic recal will be done 
  parameter       SKIP_IN_TERM_CAL  = 1'b0,     // provides option to skip the input termination calibration
  parameter       SKIP_DYNAMIC_CAL  = 1'b0,     // provides option to skip the dynamic delay calibration
  parameter       SKIP_DYN_IN_TERM  = 1'b0,     // provides option to skip the input termination calibration
  parameter       C_SIMULATION      = "FALSE",  // Tells us whether the design is being simulated or implemented
  parameter       C_MEM_TYPE        = "DDR"	// provides the memory device used for the design
  )
  (
  input   wire        UI_CLK,                 // Input - global clock to be used for input_term_tuner and IODRP clock
  input   wire        RST,                    // Input - reset for input_term_tuner - synchronous for input_term_tuner state machine, asynch for IODRP (sub)controller
  input   wire        IOCLK,                  // Input - IOCLK input to the IODRP's
  output  wire        DONE_SOFTANDHARD_CAL,   // active high flag signals soft calibration of input delays is complete and MCB_UODONECAL is high (MCB hard calib complete)
  input   wire        PLL_LOCK,               // Lock signal from PLL
  input   wire        SELFREFRESH_REQ,     
  input   wire        SELFREFRESH_MCB_MODE,
  output  wire         SELFREFRESH_MCB_REQ ,
  output  wire         SELFREFRESH_MODE,    
  
  
  
  
  output  wire        MCB_UIADD,              // to MCB's UIADD port
  output  wire        MCB_UISDI,              // to MCB's UISDI port
  input   wire        MCB_UOSDO,
  input   wire        MCB_UODONECAL,
  input   wire        MCB_UOREFRSHFLAG,
  output  wire        MCB_UICS,
  output  wire        MCB_UIDRPUPDATE,
  output  wire        MCB_UIBROADCAST,
  output  wire  [4:0] MCB_UIADDR,
  output  wire        MCB_UICMDEN,
  output  wire        MCB_UIDONECAL,
  output  wire        MCB_UIDQLOWERDEC,
  output  wire        MCB_UIDQLOWERINC,
  output  wire        MCB_UIDQUPPERDEC,
  output  wire        MCB_UIDQUPPERINC,
  output  wire        MCB_UILDQSDEC,
  output  wire        MCB_UILDQSINC,
  output  wire        MCB_UIREAD,
  output  wire        MCB_UIUDQSDEC,
  output  wire        MCB_UIUDQSINC,
  output  wire        MCB_RECAL,
  output  wire        MCB_SYSRST,
  output  wire        MCB_UICMD,
  output  wire        MCB_UICMDIN,
  output  wire  [3:0] MCB_UIDQCOUNT,
  input   wire  [7:0] MCB_UODATA,
  input   wire        MCB_UODATAVALID,
  input   wire        MCB_UOCMDREADY,
  input   wire        MCB_UO_CAL_START,
  
  inout   wire        RZQ_Pin,
  inout   wire        ZIO_Pin,
  output  wire            CKE_Train
  
  );

  wire IODRP_ADD;
  wire IODRP_SDI;
  wire RZQ_IODRP_SDO;
  wire RZQ_IODRP_CS;
  wire ZIO_IODRP_SDO;
  wire ZIO_IODRP_CS;
  wire IODRP_SDO;
  wire IODRP_CS;
  wire IODRP_BKST;
  wire RZQ_ZIO_ODATAIN;
  wire RZQ_ZIO_TRISTATE;
  wire RZQ_TOUT;
  wire ZIO_TOUT;
  wire [7:0] Max_Value;
  wire ZIO_IN;
  wire RZQ_IN;
  reg     ZIO_IN_R1, ZIO_IN_R2;
  reg     RZQ_IN_R1, RZQ_IN_R2;
  assign RZQ_ZIO_ODATAIN  = ~RST;
  assign RZQ_ZIO_TRISTATE = ~RST;
  assign IODRP_BKST       = 1'b0;  //future hook for possible BKST to ZIO and RZQ


mcb_soft_calibration #(
  .C_MEM_TZQINIT_MAXCNT (C_MEM_TZQINIT_MAXCNT),
  .C_MC_CALIBRATION_MODE(C_MC_CALIBRATION_MODE),
  .SKIP_IN_TERM_CAL     (SKIP_IN_TERM_CAL),
  .SKIP_DYNAMIC_CAL     (SKIP_DYNAMIC_CAL),
  .SKIP_DYN_IN_TERM     (SKIP_DYN_IN_TERM),
  .C_SIMULATION         (C_SIMULATION),
  .C_MEM_TYPE           (C_MEM_TYPE)
  ) 
mcb_soft_calibration_inst (
  .UI_CLK               (UI_CLK),  // main clock input for logic and IODRP CLK pins.  At top level, this should also connect to IODRP2_MCB CLK pins
  .RST                  (RST),             // main system reset for both this Soft Calibration block - also will act as a passthrough to MCB's SYSRST
  .PLL_LOCK             (PLL_LOCK), //lock signal from PLL
  .SELFREFRESH_REQ      (SELFREFRESH_REQ),    
  .SELFREFRESH_MCB_MODE  (SELFREFRESH_MCB_MODE),
  .SELFREFRESH_MCB_REQ   (SELFREFRESH_MCB_REQ ),
  .SELFREFRESH_MODE     (SELFREFRESH_MODE),   
  
  .DONE_SOFTANDHARD_CAL (DONE_SOFTANDHARD_CAL),// active high flag signals soft calibration of input delays is complete and MCB_UODONECAL is high (MCB hard calib complete)        .IODRP_ADD(IODRP_ADD),       // RZQ and ZIO IODRP ADD port, and MCB's UIADD port
  .IODRP_ADD            (IODRP_ADD),       // RZQ and ZIO IODRP ADD port
  .IODRP_SDI            (IODRP_SDI),       // RZQ and ZIO IODRP SDI port, and MCB's UISDI port
  .RZQ_IN               (RZQ_IN_R2),         // RZQ pin from board - expected to have a 2*R resistor to ground
  .RZQ_IODRP_SDO        (RZQ_IODRP_SDO),   // RZQ IODRP's SDO port
  .RZQ_IODRP_CS         (RZQ_IODRP_CS),   // RZQ IODRP's CS port
  .ZIO_IN               (ZIO_IN_R2),         // Z-stated IO pin - garanteed not to be driven externally
  .ZIO_IODRP_SDO        (ZIO_IODRP_SDO),   // ZIO IODRP's SDO port
  .ZIO_IODRP_CS         (ZIO_IODRP_CS),   // ZIO IODRP's CS port
  .MCB_UIADD            (MCB_UIADD),      // to MCB's UIADD port
  .MCB_UISDI            (MCB_UISDI),      // to MCB's UISDI port
  .MCB_UOSDO            (MCB_UOSDO),      // from MCB's UOSDO port (User output SDO)
  .MCB_UODONECAL        (MCB_UODONECAL), // indicates when MCB hard calibration process is complete
  .MCB_UOREFRSHFLAG     (MCB_UOREFRSHFLAG), //high during refresh cycle and time when MCB is innactive
  .MCB_UICS             (MCB_UICS),         // to MCB's UICS port (User Input CS)
  .MCB_UIDRPUPDATE      (MCB_UIDRPUPDATE),  // MCB's UIDRPUPDATE port (gets passed to IODRP2_MCB's MEMUPDATE port: this controls shadow latch used during IODRP2_MCB writes).  Currently just trasnparent
  .MCB_UIBROADCAST      (MCB_UIBROADCAST),  // to MCB's UIBROADCAST port (User Input BROADCAST - gets passed to IODRP2_MCB's BKST port)
  .MCB_UIADDR           (MCB_UIADDR),        //to MCB's UIADDR port (gets passed to IODRP2_MCB's AUXADDR port
  .MCB_UICMDEN          (MCB_UICMDEN),       //set to take control of UI interface - removes control from internal calib block
  .MCB_UIDONECAL        (MCB_UIDONECAL),
  .MCB_UIDQLOWERDEC     (MCB_UIDQLOWERDEC),
  .MCB_UIDQLOWERINC     (MCB_UIDQLOWERINC),
  .MCB_UIDQUPPERDEC     (MCB_UIDQUPPERDEC),
  .MCB_UIDQUPPERINC     (MCB_UIDQUPPERINC),
  .MCB_UILDQSDEC        (MCB_UILDQSDEC),
  .MCB_UILDQSINC        (MCB_UILDQSINC),
  .MCB_UIREAD           (MCB_UIREAD),        //enables read w/o writing by turning on a SDO->SDI loopback inside the IODRP2_MCBs (doesn't exist in regular IODRP2).  IODRPCTRLR_R_WB becomes don't-care.
  .MCB_UIUDQSDEC        (MCB_UIUDQSDEC),
  .MCB_UIUDQSINC        (MCB_UIUDQSINC),
  .MCB_RECAL            (MCB_RECAL),         //when high initiates a hard re-calibration sequence
  .MCB_UICMD            (MCB_UICMD        ),
  .MCB_UICMDIN          (MCB_UICMDIN      ),
  .MCB_UIDQCOUNT        (MCB_UIDQCOUNT    ),
  .MCB_UODATA           (MCB_UODATA       ),
  .MCB_UODATAVALID      (MCB_UODATAVALID  ),
  .MCB_UOCMDREADY       (MCB_UOCMDREADY   ),
  .MCB_UO_CAL_START     (MCB_UO_CAL_START),
  .MCB_SYSRST           (MCB_SYSRST       ), //drives the MCB's SYSRST pin - the main reset for MCB
  .Max_Value            (Max_Value        ),  // Maximum Tap Value from calibrated IOI
  .CKE_Train            (CKE_Train)
);



always@(posedge UI_CLK,posedge RST)
if (RST)        
   begin
        ZIO_IN_R1 <= 1'b0; 
        ZIO_IN_R2 <= 1'b0;

        RZQ_IN_R1 <= 1'b0; 
        RZQ_IN_R2 <= 1'b0;         
   end
else
   begin

        ZIO_IN_R1 <= ZIO_IN;
        ZIO_IN_R2 <= ZIO_IN_R1;
        RZQ_IN_R1 <= RZQ_IN;
        RZQ_IN_R2 <= RZQ_IN_R1;
   end

IOBUF IOBUF_RZQ (
    .O  (RZQ_IN),
    .IO (RZQ_Pin),
    .I  (RZQ_OUT),
    .T  (RZQ_TOUT)
    );

IODRP2 IODRP2_RZQ       (
      .DATAOUT(),
      .DATAOUT2(),
      .DOUT(RZQ_OUT),
      .SDO(RZQ_IODRP_SDO),
      .TOUT(RZQ_TOUT),
      .ADD(IODRP_ADD),
      .BKST(IODRP_BKST),
      .CLK(UI_CLK),
      .CS(RZQ_IODRP_CS),
      .IDATAIN(RZQ_IN),
      .IOCLK0(IOCLK),
      .IOCLK1(1'b1),
      .ODATAIN(RZQ_ZIO_ODATAIN),
      .SDI(IODRP_SDI),
      .T(RZQ_ZIO_TRISTATE)
      );


generate 
if ((C_MEM_TYPE == "DDR" || C_MEM_TYPE == "DDR2" || C_MEM_TYPE == "DDR3") &&
     (SKIP_IN_TERM_CAL == 1'b0)
     ) begin : gen_zio

IOBUF IOBUF_ZIO (
    .O  (ZIO_IN),
    .IO (ZIO_Pin),
    .I  (ZIO_OUT),
    .T  (ZIO_TOUT)
    );


IODRP2 IODRP2_ZIO       (
      .DATAOUT(),
      .DATAOUT2(),
      .DOUT(ZIO_OUT),
      .SDO(ZIO_IODRP_SDO),
      .TOUT(ZIO_TOUT),
      .ADD(IODRP_ADD),
      .BKST(IODRP_BKST),
      .CLK(UI_CLK),
      .CS(ZIO_IODRP_CS),
      .IDATAIN(ZIO_IN),
      .IOCLK0(IOCLK),
      .IOCLK1(1'b1),
      .ODATAIN(RZQ_ZIO_ODATAIN),
      .SDI(IODRP_SDI),
      .T(RZQ_ZIO_TRISTATE)
      );


end 
endgenerate
      

endmodule
