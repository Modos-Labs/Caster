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
//  /   /         Filename: mcb_soft_calibration.v
// /___/   /\     Date Last Modified: $Date: 2011/06/02 07:17:24 $
// \   \  /  \    Date Created: Mon Feb 9 2009
//  \___\/\___\
//
//Device: Spartan6
//Design Name: DDR/DDR2/DDR3/LPDDR
//Purpose:  Xilinx reference design for MCB Soft
//           Calibration
//Reference:
//
//  Revision:      Date:  Comment
//       1.0:  2/06/09:   Initial version for MIG wrapper.
//       1.1:  2/09/09:   moved Max_Value_Previous assignments to be completely inside CASE statement for next-state logic (needed to get it working correctly)
//       1.2:  2/12/09:   Many other changes.
//       1.3:  2/26/09:   Removed section with Max_Value_pre and DQS_COUNT_PREVIOUS_pre, and instead added PREVIOUS_STATE reg and moved assignment to within STATE
//       1.4:  3/02/09:   Removed comments out of sensitivity list of always block to mux SDI, SDO, CS, and ADD.  Also added reg declaration for PREVIOUS_STATE
//       1.5:  3/16/09:   Added pll_lock port, and using it to gate reset.  Changing RST (except input port) to RST_reg and gating it with pll_lock.
//       1.6:  6/05/09:   Added START_DYN_CAL_PRE with pulse on SYSRST; removed MCB_UIDQCOUNT.
//       1.7:  6/24/09:   Gave RZQ and ZIO each their own unique ADD and SDI nets
//       2.0:  7/30/09:   Added dynamic Input Termination
//       2.1:  8/02/09:   Added sampling of DQS input delays to make sure we never decrement below h00 (or increment above hEF).
//       2.2:  8/04/09:   Added 2's compliment register "DQS_COUNT_VIRTUAL", and signficantly changed the increment/decrement algorythm - now will track a virtual
//                        negative DQS_COUNT value if needed.  Got rid of DQS_COUNT_UP/DOWN registers
//       2.3:  10/10/09:  Massive overhaul
//       2.4:  10/14/09:  Fixed: from START, if SKIP_IN_TERM_CAL go to WRITE_CALIBRATE
//       2.5:  10/15/09:  Changed OVERRIDE_DQS_CAL to CALMODE_EQ_CALIBRATION, and made it override SKIP_DYNAMIC_CAL (to 1) whenever C_MC_CALIBRATION_MODE="NOCALIBRATION"
//       2.6:  12/15/09:  Changed STATE from 7-bit to 6-bit.  Dropped (* FSM_ENCODING="BINARY" *) for STATE. Moved MCB_UICMDEN = 0 from OFF_RZQ_PTERM to RST_DELAY. 
//                        Changed the "reset" always block so that RST_reg is always set to 1 when the PLL loses lock, and is now held in reset for at least 16 clocks.  Added PNSKEW option.
//       2.7:  12/23/09:  Added new states "SKEW" and "MULTIPLY_DIVIDE" to help with timing.
//       2.8:  01/14/10:  Added functionality to allow for SUSPEND.  Changed MCB_SYSRST port from wire to reg.
//       2.9:  02/01/10:  More changes to SUSPEND and Reset logic to handle SUSPEND properly.  Also - eliminated 2's comp DQS_COUNT_VIRTUAL, and replaced with 8bit TARGET_DQS_DELAY which
//                        will track most recnet Max_Value.  Eliminated DQS_COUNT_PREVIOUS. Combined DQS_COUNT_INITIAL and DQS_Delay into DQS_DELAY_INITIAL.  Changed DQS_COUNT* to DQS_DELAY*.
//                        Changed MCB_SYSRST port back to wire (from reg).
//       3.0:  02/10/10:  Added count_inc and count_dec to add a few (4) UI_CLK cycles latency to the INC and DEC signals (to deal with latency on UOREFRSHFLAG)
//       3.1:  02/23/10:  Registered the DONE_SOFTANDHARD_CAL for timing.   
//       3.2:  02/28/10:  Corrected the   WAIT_SELFREFRESH_EXIT_DQS_CAL logic;
//       3.3:  03/02/10:  Changed PNSKEW to default on (1'b1)
//       3.4:  03/04/10:  Recoded the RST_Reg logic.
//       3.5:  03/05/10:  Changed Result register to be 16-bits.  Changed DQS_NUMERATOR/DENOMINATOR values to 3/8 (from 6/16)
//       3.6:  03/10/10:  Improvements to Reset logic    
//       3.7:  04/12/10:  Added DDR2 Initialization fix to meet 400 ns wait as outlined in step d) of JEDEC DDR2 spec .
//       3.8:  05/24/10:  Added 200us Wait logic to control CKE_Train. The 200us Wait counter assumes UI_CLK freq not higher than 100 MHz.
//       3.9   02/11/11:  Apply a different skkew for the P and N inputs for the differential LDQS and UDQS signals to provide more noise immunity.
//       4.0   04/11/11:  Added sync FF for RZA_IN and ZIO_IN async inputs.
//       4.1   03/08/12:  Fixed SELFREFRESH_MCB_REQ logic. It should not need depend on the SM STATE so that
//                        MCB can come out of selfresh mode. SM requires refresh cycle to update the DQS value. 
//       4.2   05/10/12:  All P/N terms of input and bidir memory pins are initialized with value of ZERO. TZQINIT_MAXCNT
//                        are set to 8 for LPDDR,DDR and DDR2 interface .
//                        Keep the UICMDEN in assertion state when SM is in RST_DELAY state so that MCB will not start doing
//                        Premable detection until the second deassertion of MCB_SYSRST. 
//                        
// End Revision
//**********************************************************************************


`timescale 1ps/1ps

module mcb_soft_calibration # (
  parameter       C_MEM_TZQINIT_MAXCNT  = 10'd512,  // DDR3 Minimum delay between resets
  parameter       C_MC_CALIBRATION_MODE = "CALIBRATION", // if set to CALIBRATION will reset DQS IDELAY to DQS_NUMERATOR/DQS_DENOMINATOR local_param values
                                                         // if set to NOCALIBRATION then defaults to hard cal blocks setting of C_MC_CALBRATION_DELAY (Quarter, etc)
  parameter       C_SIMULATION          = "FALSE",  // Tells us whether the design is being simulated or implemented
  parameter       SKIP_IN_TERM_CAL      = 1'b0,     // provides option to skip the input termination calibration
  parameter       SKIP_DYNAMIC_CAL      = 1'b0,     // provides option to skip the dynamic delay calibration
  parameter       SKIP_DYN_IN_TERM      = 1'b1,      // provides option to skip the input termination calibration
  parameter       C_MEM_TYPE = "DDR"            // provides the memory device used for the design
  
  )
  (
  input   wire            UI_CLK,                   // main clock input for logic and IODRP CLK pins.  At top level, this should also connect to IODRP2_MCB CLK pins
  input   wire            RST,                      // main system reset for both this Soft Calibration block - also will act as a passthrough to MCB's SYSRST
  (* IOB = "FALSE" *) output  reg            DONE_SOFTANDHARD_CAL,
                                                    // active high flag signals soft calibration of input delays is complete and MCB_UODONECAL is high (MCB hard calib complete)
  input   wire            PLL_LOCK,                 // Lock signal from PLL
  input   wire            SELFREFRESH_REQ,     
  input   wire            SELFREFRESH_MCB_MODE,
  output  reg             SELFREFRESH_MCB_REQ ,
  output  reg             SELFREFRESH_MODE,    
  output  wire            IODRP_ADD,                // IODRP ADD port
  output  wire            IODRP_SDI,                // IODRP SDI port
  input   wire            RZQ_IN,                   // RZQ pin from board - expected to have a 2*R resistor to ground
  input   wire            RZQ_IODRP_SDO,            // RZQ IODRP's SDO port
  output  reg             RZQ_IODRP_CS      = 1'b0, // RZQ IODRP's CS port
  input   wire            ZIO_IN,                   // Z-stated IO pin - garanteed not to be driven externally
  input   wire            ZIO_IODRP_SDO,            // ZIO IODRP's SDO port
  output  reg             ZIO_IODRP_CS      = 1'b0, // ZIO IODRP's CS port
  output  wire            MCB_UIADD,                // to MCB's UIADD port
  output  wire            MCB_UISDI,                // to MCB's UISDI port
  input   wire            MCB_UOSDO,                // from MCB's UOSDO port (User output SDO)
  input   wire            MCB_UODONECAL,            // indicates when MCB hard calibration process is complete
  input   wire            MCB_UOREFRSHFLAG,         //  high during refresh cycle and time when MCB is innactive
  output  wire            MCB_UICS,                 // to MCB's UICS port (User Input CS)
  output  reg             MCB_UIDRPUPDATE   = 1'b1, // MCB's UIDRPUPDATE port (gets passed to IODRP2_MCB's MEMUPDATE port: this controls shadow latch used during IODRP2_MCB writes).  Currently just trasnparent
  output  wire            MCB_UIBROADCAST,          // only to MCB's UIBROADCAST port (User Input BROADCAST - gets passed to IODRP2_MCB's BKST port)
  output  reg   [4:0]     MCB_UIADDR        = 5'b0, //  to MCB's UIADDR port (gets passed to IODRP2_MCB's AUXADDR port
  output  reg             MCB_UICMDEN       = 1'b1, //  set to 1 to take control of UI interface - removes control from internal calib block
  output  reg             MCB_UIDONECAL     = 1'b0, //  set to 0 to "tell" controller that it's still in a calibrate state
  output               MCB_UIDQLOWERDEC ,
  output               MCB_UIDQLOWERINC ,
  output               MCB_UIDQUPPERDEC ,
  output               MCB_UIDQUPPERINC ,
  output  reg             MCB_UILDQSDEC     = 1'b0,
  output  reg             MCB_UILDQSINC     = 1'b0,
  output  wire            MCB_UIREAD,               //  enables read w/o writing by turning on a SDO->SDI loopback inside the IODRP2_MCBs (doesn't exist in regular IODRP2).  IODRPCTRLR_R_WB becomes don't-care.
  output  reg             MCB_UIUDQSDEC     = 1'b0,
  output  reg             MCB_UIUDQSINC     = 1'b0,
  output                  MCB_RECAL         , //  future hook to drive MCB's RECAL pin - initiates a hard re-calibration sequence when high
  output  reg             MCB_UICMD,
  output  reg             MCB_UICMDIN,
  output  reg   [3:0]     MCB_UIDQCOUNT,
  input   wire  [7:0]     MCB_UODATA,
  input   wire            MCB_UODATAVALID,
  input   wire            MCB_UOCMDREADY,
  input   wire            MCB_UO_CAL_START,
  output  wire            MCB_SYSRST,               //  drives the MCB's SYSRST pin - the main reset for MCB
  output  reg   [7:0]     Max_Value,
  output  reg            CKE_Train
  );


localparam [4:0]
          IOI_DQ0       = {4'h0, 1'b1},
          IOI_DQ1       = {4'h0, 1'b0},
          IOI_DQ2       = {4'h1, 1'b1},
          IOI_DQ3       = {4'h1, 1'b0},
          IOI_DQ4       = {4'h2, 1'b1},
          IOI_DQ5       = {4'h2, 1'b0},
          IOI_DQ6       = {4'h3, 1'b1},
          IOI_DQ7       = {4'h3, 1'b0},
          IOI_DQ8       = {4'h4, 1'b1},
          IOI_DQ9       = {4'h4, 1'b0},
          IOI_DQ10      = {4'h5, 1'b1},
          IOI_DQ11      = {4'h5, 1'b0},
          IOI_DQ12      = {4'h6, 1'b1},
          IOI_DQ13      = {4'h6, 1'b0},
          IOI_DQ14      = {4'h7, 1'b1},
          IOI_DQ15      = {4'h7, 1'b0},
          IOI_UDM       = {4'h8, 1'b1},
          IOI_LDM       = {4'h8, 1'b0},
          IOI_CK_P      = {4'h9, 1'b1},
          IOI_CK_N      = {4'h9, 1'b0},
          IOI_RESET     = {4'hA, 1'b1},
          IOI_A11       = {4'hA, 1'b0},
          IOI_WE        = {4'hB, 1'b1},
          IOI_BA2       = {4'hB, 1'b0},
          IOI_BA0       = {4'hC, 1'b1},
          IOI_BA1       = {4'hC, 1'b0},
          IOI_RASN      = {4'hD, 1'b1},
          IOI_CASN      = {4'hD, 1'b0},
          IOI_UDQS_CLK  = {4'hE, 1'b1},
          IOI_UDQS_PIN  = {4'hE, 1'b0},
          IOI_LDQS_CLK  = {4'hF, 1'b1},
          IOI_LDQS_PIN  = {4'hF, 1'b0};

localparam  [5:0]   START                     = 6'h00,
                    LOAD_RZQ_NTERM            = 6'h01,
                    WAIT1                     = 6'h02,
                    LOAD_RZQ_PTERM            = 6'h03,
                    WAIT2                     = 6'h04,
                    INC_PTERM                 = 6'h05,
                    MULTIPLY_DIVIDE           = 6'h06,
                    LOAD_ZIO_PTERM            = 6'h07,
                    WAIT3                     = 6'h08,
                    LOAD_ZIO_NTERM            = 6'h09,
                    WAIT4                     = 6'h0A,
                    INC_NTERM                 = 6'h0B,
                    SKEW                      = 6'h0C,
                    WAIT_FOR_START_BROADCAST  = 6'h0D,
                    BROADCAST_PTERM           = 6'h0E,
                    WAIT5                     = 6'h0F,
                    BROADCAST_NTERM           = 6'h10,
                    WAIT6                     = 6'h11,
                    LDQS_CLK_WRITE_P_TERM     = 6'h12,
                    LDQS_CLK_P_TERM_WAIT      = 6'h13,
                    LDQS_CLK_WRITE_N_TERM     = 6'h14,
                    LDQS_CLK_N_TERM_WAIT      = 6'h15,
                    LDQS_PIN_WRITE_P_TERM     = 6'h16,
                    LDQS_PIN_P_TERM_WAIT      = 6'h17,
                    LDQS_PIN_WRITE_N_TERM     = 6'h18,
                    LDQS_PIN_N_TERM_WAIT      = 6'h19,
                    UDQS_CLK_WRITE_P_TERM     = 6'h1A,
                    UDQS_CLK_P_TERM_WAIT      = 6'h1B,
                    UDQS_CLK_WRITE_N_TERM     = 6'h1C,
                    UDQS_CLK_N_TERM_WAIT      = 6'h1D,
                    UDQS_PIN_WRITE_P_TERM     = 6'h1E,
                    UDQS_PIN_P_TERM_WAIT      = 6'h1F,
                    UDQS_PIN_WRITE_N_TERM     = 6'h20,
                    UDQS_PIN_N_TERM_WAIT      = 6'h21,
                    OFF_RZQ_PTERM             = 6'h22,
                    WAIT7                     = 6'h23,
                    OFF_ZIO_NTERM             = 6'h24,
                    WAIT8                     = 6'h25,
                    RST_DELAY                 = 6'h26,
                    START_DYN_CAL_PRE         = 6'h27,
                    WAIT_FOR_UODONE           = 6'h28,
                    LDQS_WRITE_POS_INDELAY    = 6'h29,
                    LDQS_WAIT1                = 6'h2A,
                    LDQS_WRITE_NEG_INDELAY    = 6'h2B,
                    LDQS_WAIT2                = 6'h2C,
                    UDQS_WRITE_POS_INDELAY    = 6'h2D,
                    UDQS_WAIT1                = 6'h2E,
                    UDQS_WRITE_NEG_INDELAY    = 6'h2F,
                    UDQS_WAIT2                = 6'h30,
                    START_DYN_CAL             = 6'h31,
                    WRITE_CALIBRATE           = 6'h32,
                    WAIT9                     = 6'h33,
                    READ_MAX_VALUE            = 6'h34,
                    WAIT10                    = 6'h35,
                    ANALYZE_MAX_VALUE         = 6'h36,
                    FIRST_DYN_CAL             = 6'h37,
                    INCREMENT                 = 6'h38,
                    DECREMENT                 = 6'h39,
                    DONE                      = 6'h3A;

localparam  [1:0]   RZQ           = 2'b00,
                    ZIO           = 2'b01,
                    MCB_PORT      = 2'b11;
localparam          WRITE_MODE    = 1'b0;
localparam          READ_MODE     = 1'b1;

// IOI Registers
localparam  [7:0]   NoOp          = 8'h00,
                    DelayControl  = 8'h01,
                    PosEdgeInDly  = 8'h02,
                    NegEdgeInDly  = 8'h03,
                    PosEdgeOutDly = 8'h04,
                    NegEdgeOutDly = 8'h05,
                    MiscCtl1      = 8'h06,
                    MiscCtl2      = 8'h07,
                    MaxValue      = 8'h08;

// IOB Registers
localparam  [7:0]   PDrive        = 8'h80,
                    PTerm         = 8'h81,
                    NDrive        = 8'h82,
                    NTerm         = 8'h83,
                    SlewRateCtl   = 8'h84,
                    LVDSControl   = 8'h85,
                    MiscControl   = 8'h86,
                    InputControl  = 8'h87,
                    TestReadback  = 8'h88;

// No multi/divide is required when a 55 ohm resister is used on RZQ
//localparam          MULT          = 1;
//localparam          DIV           = 1;
// use 7/4 scaling factor when the 100 ohm RZQ is used
localparam          MULT          = 7;
localparam          DIV           = 4;

localparam          PNSKEW        = 1'b1; //Default is 1'b1. Change to 1'b0 if PSKEW and NSKEW are not required
localparam          PNSKEWDQS     = 1'b1; 
localparam          MULT_S    = 9;
localparam          DIV_S     = 8;
localparam          MULT_W    = 7;
localparam          DIV_W     = 8;

localparam          DQS_NUMERATOR   = 3;
localparam          DQS_DENOMINATOR = 8;
localparam          INCDEC_THRESHOLD= 8'h03; // parameter for the threshold which triggers an inc/dec to occur.  2 for half, 4 for quarter, 3 for three eighths


                                                         
reg   [5:0]   P_Term       /* synthesis syn_preserve = 1 */;
reg   [6:0]   N_Term       /* synthesis syn_preserve = 1 */;
reg   [5:0]   P_Term_s     /* synthesis syn_preserve = 1 */;
reg   [6:0]   N_Term_s     /* synthesis syn_preserve = 1 */;
reg   [5:0]   P_Term_w     /* synthesis syn_preserve = 1 */;
reg   [6:0]   N_Term_w     /* synthesis syn_preserve = 1 */;
reg   [5:0]   P_Term_Prev  /* synthesis syn_preserve = 1 */;
reg   [6:0]   N_Term_Prev  /* synthesis syn_preserve = 1 */;
//(* FSM_ENCODING="USER" *) reg [5:0] STATE = START;   //XST does not pick up "BINARY" - use COMPACT instead if binary is desired
reg [5:0] STATE ;
reg   [7:0]   IODRPCTRLR_MEMCELL_ADDR /* synthesis syn_preserve = 1 */;
reg   [7:0]   IODRPCTRLR_WRITE_DATA /* synthesis syn_preserve = 1 */;
reg   [1:0]   Active_IODRP /* synthesis syn_maxfan = 1 */;
// synthesis attribute max_fanout of Active_IODRP is 1
reg           IODRPCTRLR_R_WB = 1'b0;
reg           IODRPCTRLR_CMD_VALID = 1'b0;
reg           IODRPCTRLR_USE_BKST = 1'b0;
reg           MCB_CMD_VALID = 1'b0;
reg           MCB_USE_BKST = 1'b0;
reg           Pre_SYSRST = 1'b1 /* synthesis syn_maxfan = 5 */; //internally generated reset which will OR with RST input to drive MCB's SYSRST pin (MCB_SYSRST)
// synthesis attribute max_fanout of Pre_SYSRST is 5
reg           IODRP_SDO;
reg   [7:0]   Max_Value_Previous  = 8'b0 /* synthesis syn_preserve = 1 */;
reg   [5:0]   count = 6'd0;               //counter for adding 18 extra clock cycles after setting Calibrate bit
reg           counter_en  = 1'b0;         //counter enable for "count"
reg           First_Dyn_Cal_Done = 1'b0;  //flag - high after the very first dynamic calibration is done
wire          START_BROADCAST ;     // Trigger to start Broadcast to IODRP2_MCBs to set Input Impedance - state machine will wait for this to be high
reg   [7:0]   DQS_DELAY_INITIAL   = 8'b0 /* synthesis syn_preserve = 1 */;
reg   [7:0]   DQS_DELAY ;        // contains the latest values written to LDQS and UDQS Input Delays
reg   [7:0]   TARGET_DQS_DELAY;  // used to track the target for DQS input delays - only gets updated if the Max Value changes by more than the threshold
reg   [7:0]   counter_inc;       // used to delay Inc signal by several ui_clk cycles (to deal with latency on UOREFRSHFLAG)
reg   [7:0]   counter_dec;       // used to delay Dec signal by several ui_clk cycles (to deal with latency on UOREFRSHFLAG)

wire  [7:0]   IODRPCTRLR_READ_DATA;
wire          IODRPCTRLR_RDY_BUSY_N;
wire          IODRP_CS;
wire  [7:0]   MCB_READ_DATA;

reg           RST_reg;
reg           Block_Reset;

reg           MCB_UODATAVALID_U;

wire  [2:0]   Inc_Dec_REFRSH_Flag;  // 3-bit flag to show:Inc is needed, Dec needed, refresh cycle taking place
wire  [7:0]   Max_Value_Delta_Up;   // tracks amount latest Max Value has gone up from previous Max Value read
wire  [7:0]   Half_MV_DU;           // half of Max_Value_Delta_Up
wire  [7:0]   Max_Value_Delta_Dn;   // tracks amount latest Max Value has gone down from previous Max Value read
wire  [7:0]   Half_MV_DD;           // half of Max_Value_Delta_Dn

reg   [9:0]   RstCounter = 10'h0;
wire          rst_tmp;
reg           LastPass_DynCal;
reg           First_In_Term_Done;
wire          Inc_Flag;               // flag to increment Dynamic Delay
wire          Dec_Flag;               // flag to decrement Dynamic Delay
                                                   
wire          CALMODE_EQ_CALIBRATION; // will calculate and set the DQS input delays if C_MC_CALIBRATION_MODE parameter = "CALIBRATION"
wire  [7:0]   DQS_DELAY_LOWER_LIMIT;  // Lower limit for DQS input delays 
wire  [7:0]   DQS_DELAY_UPPER_LIMIT;  // Upper limit for DQS input delays
wire          SKIP_DYN_IN_TERMINATION;//wire to allow skipping dynamic input termination if either the one-time or dynamic parameters are 1
wire          SKIP_DYNAMIC_DQS_CAL;   //wire allowing skipping dynamic DQS delay calibration if either SKIP_DYNIMIC_CAL=1, or if C_MC_CALIBRATION_MODE=NOCALIBRATION
wire  [7:0]   Quarter_Max_Value;
wire  [7:0]   Half_Max_Value;
reg           PLL_LOCK_R1;
reg           PLL_LOCK_R2;      

reg           SELFREFRESH_REQ_R1;
reg           SELFREFRESH_REQ_R2;
reg           SELFREFRESH_REQ_R3;
reg           SELFREFRESH_MCB_MODE_R1;
reg           SELFREFRESH_MCB_MODE_R2;
reg           SELFREFRESH_MCB_MODE_R3;

reg           WAIT_SELFREFRESH_EXIT_DQS_CAL;
reg           PERFORM_START_DYN_CAL_AFTER_SELFREFRESH;
reg           START_DYN_CAL_STATE_R1;
reg           PERFORM_START_DYN_CAL_AFTER_SELFREFRESH_R1;
reg           Rst_condition1;
wire          non_violating_rst;
reg [15:0]    WAIT_200us_COUNTER;
reg [7:0]     WaitTimer;
reg           WarmEnough;

wire   pre_sysrst_minpulse_width_ok;
reg [3:0] pre_sysrst_cnt;
// move the default assignment here to make FORMALITY happy.
assign START_BROADCAST = 1'b1;
assign MCB_RECAL = 1'b0;
assign MCB_UIDQLOWERDEC = 1'b0;
assign MCB_UIDQLOWERINC = 1'b0;
assign MCB_UIDQUPPERDEC = 1'b0;
assign MCB_UIDQUPPERINC = 1'b0;

// 'defines for which pass of the interleaved dynamic algorythm is taking place
`define IN_TERM_PASS  1'b0
`define DYN_CAL_PASS  1'b1

assign  Inc_Dec_REFRSH_Flag     = {Inc_Flag,Dec_Flag,MCB_UOREFRSHFLAG};
assign  Max_Value_Delta_Up      = Max_Value - Max_Value_Previous;
assign  Half_MV_DU              = {1'b0,Max_Value_Delta_Up[7:1]};
assign  Max_Value_Delta_Dn      = Max_Value_Previous - Max_Value;
assign  Half_MV_DD              = {1'b0,Max_Value_Delta_Dn[7:1]};
assign  CALMODE_EQ_CALIBRATION  = (C_MC_CALIBRATION_MODE == "CALIBRATION") ? 1'b1 : 1'b0; // will calculate and set the DQS input delays if = 1'b1
assign  Half_Max_Value          = Max_Value >> 1;
assign  Quarter_Max_Value       = Max_Value >> 2;
assign  DQS_DELAY_LOWER_LIMIT   = Quarter_Max_Value;  // limit for DQS_DELAY for decrements; could optionally be assigned to any 8-bit hex value here
assign  DQS_DELAY_UPPER_LIMIT   = Half_Max_Value;     // limit for DQS_DELAY for increments; could optionally be assigned to any 8-bit hex value here
assign  SKIP_DYN_IN_TERMINATION = SKIP_DYN_IN_TERM || SKIP_IN_TERM_CAL; //skip dynamic input termination if either the one-time or dynamic parameters are 1
assign  SKIP_DYNAMIC_DQS_CAL    = ~CALMODE_EQ_CALIBRATION || SKIP_DYNAMIC_CAL; //skip dynamic DQS delay calibration if either SKIP_DYNAMIC_CAL=1, or if C_MC_CALIBRATION_MODE=NOCALIBRATION

always @ (posedge UI_CLK)
     DONE_SOFTANDHARD_CAL    <= ((DQS_DELAY_INITIAL != 8'h00) || (STATE == DONE)) && MCB_UODONECAL;  //high when either DQS input delays initialized, or STATE=DONE and UODONECAL high


iodrp_controller iodrp_controller(
  .memcell_address  (IODRPCTRLR_MEMCELL_ADDR),
  .write_data       (IODRPCTRLR_WRITE_DATA),
  .read_data        (IODRPCTRLR_READ_DATA),
  .rd_not_write     (IODRPCTRLR_R_WB),
  .cmd_valid        (IODRPCTRLR_CMD_VALID),
  .rdy_busy_n       (IODRPCTRLR_RDY_BUSY_N),
  .use_broadcast    (1'b0),
  .sync_rst         (RST_reg),
  .DRP_CLK          (UI_CLK),
  .DRP_CS           (IODRP_CS),
  .DRP_SDI          (IODRP_SDI),
  .DRP_ADD          (IODRP_ADD),
  .DRP_SDO          (IODRP_SDO),
  .DRP_BKST         ()
  );

iodrp_mcb_controller iodrp_mcb_controller(
  .memcell_address  (IODRPCTRLR_MEMCELL_ADDR),
  .write_data       (IODRPCTRLR_WRITE_DATA),
  .read_data        (MCB_READ_DATA),
  .rd_not_write     (IODRPCTRLR_R_WB),
  .cmd_valid        (MCB_CMD_VALID),
  .rdy_busy_n       (MCB_RDY_BUSY_N),
  .use_broadcast    (MCB_USE_BKST),
  .drp_ioi_addr     (MCB_UIADDR),
  .sync_rst         (RST_reg),
  .DRP_CLK          (UI_CLK),
  .DRP_CS           (MCB_UICS),
  .DRP_SDI          (MCB_UISDI),
  .DRP_ADD          (MCB_UIADD),
  .DRP_BKST         (MCB_UIBROADCAST),
  .DRP_SDO          (MCB_UOSDO),
  .MCB_UIREAD       (MCB_UIREAD)
  );


//******************************************************************************************
// Mult_Divide Function - multiplies by a constant MULT and then divides by the DIV constant
//******************************************************************************************
function [7:0] Mult_Divide;
input   [7:0]   Input;
input   [7:0]   Mult;
input   [7:0]   Div;
reg     [3:0]   count;
reg     [15:0]   Result;
begin
  Result  = 0;
  for (count = 0; count < Mult; count = count+1) begin
    Result    = Result + Input;
  end
  Result      = Result / Div;
  Mult_Divide = Result[7:0];
end
endfunction

 always @ (posedge UI_CLK, posedge RST)
  begin
   if (RST)
     WAIT_200us_COUNTER <= (C_SIMULATION == "TRUE") ? 16'h7FF0 : 16'h0;
   else 
      if (WAIT_200us_COUNTER[15])  // UI_CLK maximum is up to 100 MHz.
        WAIT_200us_COUNTER <= WAIT_200us_COUNTER                        ;
      else
        WAIT_200us_COUNTER <= WAIT_200us_COUNTER + 1'b1;
  end 
    
    
generate
if( C_MEM_TYPE == "DDR2") begin : gen_cketrain_a


always @ ( posedge UI_CLK, posedge RST)
begin 
if (RST)
   CKE_Train <= 1'b0;
else 
  if (STATE == WAIT_FOR_UODONE && MCB_UODONECAL)
   CKE_Train <= 1'b0;
  else if (WAIT_200us_COUNTER[15] && ~MCB_UODONECAL)
   CKE_Train <= 1'b1;
  else
   CKE_Train <= 1'b0;
  
end
end
endgenerate


generate
if( C_MEM_TYPE != "DDR2") begin : gen_cketrain_b
always @ (RST)
   CKE_Train <= 1'b0;
end 
endgenerate

//********************************************
//PLL_LOCK and Reset signals
//********************************************
localparam  RST_CNT         = 10'h010;          //defines pulse-width for reset
localparam  TZQINIT_MAXCNT  = (C_MEM_TYPE == "DDR3") ? C_MEM_TZQINIT_MAXCNT + RST_CNT : 8 + RST_CNT;  
assign rst_tmp    = (~PLL_LOCK_R2 && ~SELFREFRESH_MODE); //rst_tmp becomes 1 if you lose PLL lock (registered twice for metastblty) and the device is not in SUSPEND

// Rst_contidtion1 is to make sure RESET will not happen again within TZQINIT_MAXCNT
assign non_violating_rst = RST & Rst_condition1;         //non_violating_rst is when the user-reset RST occurs and TZQINIT (min time between resets for DDR3) is not being violated


assign MCB_SYSRST = (Pre_SYSRST );

always @ (posedge UI_CLK or posedge RST ) begin  
  if (RST) begin         
    Block_Reset <= 1'b0;
    RstCounter  <= 10'b0;
end
  else begin
    Block_Reset <= 1'b0;                   //default to allow STATE to move out of RST_DELAY state
    if (Pre_SYSRST)
      RstCounter  <= RST_CNT;              //whenever STATE wants to reset the MCB, set RstCounter to h10
    else begin
      if (RstCounter < TZQINIT_MAXCNT) begin //if RstCounter is less than d512 than this will execute
        Block_Reset <= 1'b1;               //STATE won't exit RST_DELAY state
        RstCounter  <= RstCounter + 1'b1;  //and Rst_Counter increments
      end
    end
  end
end



always @ (posedge UI_CLK ) begin  
if (RstCounter >= TZQINIT_MAXCNT) 
    Rst_condition1 <= 1'b1;
else
    Rst_condition1 <= 1'b0;

end


// -- non_violating_rst asserts whenever (system-level reset) RST is asserted but must be after TZQINIT_MAXCNT is reached (min-time between resets for DDR3)
// -- After power stablizes, we will hold MCB in reset state for at least 200us before beginning initialization  process.   
// -- If the PLL loses lock during normal operation, no ui_clk will be present because mcb_drp_clk is from a BUFGCE which
//    is gated by pll's lock signal.   When the PLL locks again, the RST_reg stays asserted for at least 200 us which
//    will cause MCB to reset and reinitialize the memory afterwards.
// -- During SUSPEND operation, the PLL will lose lock but non_violating_rst remains low (de-asserted) and WAIT_200us_COUNTER stays at 
//    its terminal count.  The PLL_LOCK input does not come direct from PLL, rather it is driven by gated_pll_lock from mcb_raw_wrapper module
//    The gated_pll_lock in the mcb_raw_wrapper does not de-assert during SUSPEND operation, hence PLL_LOCK will not de-assert, and the soft calibration 
//    state machine will not reset during SUSPEND.
// -- RST_reg is the control signal that resets the mcb_soft_calibration's State Machine. The MCB_SYSRST is now equal to 
//    Pre_SYSRST. When State Machine is performing "INPUT Termination Calibration", it holds the MCB in reset by assertign MCB_SYSRST. 
//    It will deassert the MCB_SYSRST so that it can grab the bus to broadcast the P and N term value to all of the DQ pins. Once the calibrated INPUT 
//    termination is set, the State Machine will issue another short MCB_SYSRST so that MCB will use the tuned input termination during DQS preamble calibration.



always @ (posedge UI_CLK or posedge non_violating_rst ) begin  
  if (non_violating_rst)          
    RST_reg <= 1'b1;                                       
  else if (~WAIT_200us_COUNTER[15])
    RST_reg <= 1'b1;         
  else 
    RST_reg     <= rst_tmp; 
    
end


//********************************************
// stretching the pre_sysrst to satisfy the minimum pusle width

always @ (posedge UI_CLK )begin
  if (STATE == START_DYN_CAL_PRE)
     pre_sysrst_cnt <= pre_sysrst_cnt + 1;
  else
     pre_sysrst_cnt <= 4'b0;
end

assign pre_sysrst_minpulse_width_ok = pre_sysrst_cnt[3];

//********************************************
// SUSPEND Logic
//********************************************

always @ ( posedge UI_CLK, posedge RST) begin
  //SELFREFRESH_MCB_MODE is clocked by sysclk_2x_180
  if (RST)
    begin
      SELFREFRESH_MCB_MODE_R1 <= 1'b0;
      SELFREFRESH_MCB_MODE_R2 <= 1'b0;
      SELFREFRESH_MCB_MODE_R3 <= 1'b0;
      SELFREFRESH_REQ_R1      <= 1'b0;
      SELFREFRESH_REQ_R2      <= 1'b0;
      SELFREFRESH_REQ_R3      <= 1'b0;
      PLL_LOCK_R1             <= 1'b0;
      PLL_LOCK_R2             <= 1'b0;
    end
  else 
    begin
      SELFREFRESH_MCB_MODE_R1 <= SELFREFRESH_MCB_MODE;
      SELFREFRESH_MCB_MODE_R2 <= SELFREFRESH_MCB_MODE_R1;
      SELFREFRESH_MCB_MODE_R3 <= SELFREFRESH_MCB_MODE_R2;
      SELFREFRESH_REQ_R1      <= SELFREFRESH_REQ;
      SELFREFRESH_REQ_R2      <= SELFREFRESH_REQ_R1;
      SELFREFRESH_REQ_R3      <= SELFREFRESH_REQ_R2;
      PLL_LOCK_R1             <= PLL_LOCK;
      PLL_LOCK_R2             <= PLL_LOCK_R1;
    end
 end 

// SELFREFRESH should only be deasserted after PLL_LOCK is asserted.
// This is to make sure MCB get a locked sys_2x_clk before exiting
// SELFREFRESH mode.

always @ ( posedge UI_CLK) begin
  if (RST)
    SELFREFRESH_MCB_REQ <= 1'b0;
  else if (PLL_LOCK_R2 && ~SELFREFRESH_REQ_R3 )// 

    SELFREFRESH_MCB_REQ <=  1'b0;
  else if (STATE == START_DYN_CAL && SELFREFRESH_REQ_R3)  
    SELFREFRESH_MCB_REQ <= 1'b1;
end



always @ (posedge UI_CLK) begin
  if (RST)
    WAIT_SELFREFRESH_EXIT_DQS_CAL <= 1'b0;
  else if (~SELFREFRESH_MCB_MODE_R3 && SELFREFRESH_MCB_MODE_R2)  

    WAIT_SELFREFRESH_EXIT_DQS_CAL <= 1'b1;
  else if (WAIT_SELFREFRESH_EXIT_DQS_CAL && ~SELFREFRESH_REQ_R3 && PERFORM_START_DYN_CAL_AFTER_SELFREFRESH) // START_DYN_CAL is next state
    WAIT_SELFREFRESH_EXIT_DQS_CAL <= 1'b0;
end   

//Need to detect when SM entering START_DYN_CAL
always @ (posedge UI_CLK) begin
  if (RST) begin
    PERFORM_START_DYN_CAL_AFTER_SELFREFRESH  <= 1'b0;
    START_DYN_CAL_STATE_R1 <= 1'b0;
  end 
  else begin
    // register PERFORM_START_DYN_CAL_AFTER_SELFREFRESH to detect end of cycle
    PERFORM_START_DYN_CAL_AFTER_SELFREFRESH_R1 <= PERFORM_START_DYN_CAL_AFTER_SELFREFRESH;
    if (STATE == START_DYN_CAL)
      START_DYN_CAL_STATE_R1 <= 1'b1;
    else
      START_DYN_CAL_STATE_R1 <= 1'b0;
      if (WAIT_SELFREFRESH_EXIT_DQS_CAL && STATE != START_DYN_CAL && START_DYN_CAL_STATE_R1 )
        PERFORM_START_DYN_CAL_AFTER_SELFREFRESH <= 1'b1;
      else if (STATE == START_DYN_CAL && ~SELFREFRESH_MCB_MODE_R3)
        PERFORM_START_DYN_CAL_AFTER_SELFREFRESH <= 1'b0;
      end
  end
// SELFREFRESH_MCB_MODE deasserted status is hold off
// until Soft_Calib has at least done one loop of DQS update.
// New logic WarmeEnough is added to make sure PLL_Lock is lockec and all IOs stable before 
// deassert the status of MCB's SELFREFRESH_MODE.  This is to ensure all IOs are stable before
// user logic sending new commands to MCB.

always @ (posedge UI_CLK) begin
  if (RST)
    SELFREFRESH_MODE <= 1'b0;
  else if (SELFREFRESH_MCB_MODE_R2)  
    SELFREFRESH_MODE <= 1'b1;
    else if (WarmEnough)
     SELFREFRESH_MODE <= 1'b0;
end

reg WaitCountEnable;

always @ (posedge UI_CLK) begin
  if (RST)
    WaitCountEnable <= 1'b0;
  else if (~SELFREFRESH_REQ_R2 && SELFREFRESH_REQ_R1)  
    WaitCountEnable <= 1'b0;
    
  else if (!PERFORM_START_DYN_CAL_AFTER_SELFREFRESH && PERFORM_START_DYN_CAL_AFTER_SELFREFRESH_R1)
    WaitCountEnable <= 1'b1;
  else
    WaitCountEnable <=  WaitCountEnable;
end
reg State_Start_DynCal_R1 ;
reg State_Start_DynCal;
always @ (posedge UI_CLK)
begin
if (RST)
   State_Start_DynCal <= 1'b0;
else if (STATE == START_DYN_CAL)   
   State_Start_DynCal <= 1'b1;
else
   State_Start_DynCal <= 1'b0;
end

always @ (posedge UI_CLK)
begin
if (RST)
   State_Start_DynCal_R1 <= 1'b0;
else 
   State_Start_DynCal_R1 <= State_Start_DynCal;
end


always @ (posedge UI_CLK) begin
   if (RST) 
    begin
       WaitTimer <= 'b0;
       WarmEnough <= 1'b1;
    end       
  else if (~SELFREFRESH_REQ_R2 && SELFREFRESH_REQ_R1)  
    begin
       WaitTimer <= 'b0;
       WarmEnough <= 1'b0;
    end       
  else if (WaitTimer == 8'h4)
    begin
       WaitTimer <= WaitTimer ;
       WarmEnough <= 1'b1;
    end       
  else if (WaitCountEnable)
       WaitTimer <= WaitTimer + 1;
  else
       WaitTimer <= WaitTimer ;
  
end  



//********************************************
//Comparitors for Dynamic Calibration circuit
//********************************************
assign Dec_Flag = (TARGET_DQS_DELAY < DQS_DELAY);
assign Inc_Flag = (TARGET_DQS_DELAY > DQS_DELAY);


//*********************************************************************************************
//Counter for extra clock cycles injected after setting Calibrate bit in IODRP2 for Dynamic Cal
//*********************************************************************************************
 always @(posedge UI_CLK)
  begin
    if (RST_reg)
        count <= 6'd0;
    else if (counter_en)
        count <= count + 1'b1;
    else
        count <= 6'd0;
  end

//*********************************************************************************************
// Capture narrow MCB_UODATAVALID pulse - only one sysclk90 cycle wide
//*********************************************************************************************
 always @(posedge UI_CLK or posedge MCB_UODATAVALID)
  begin
    if (MCB_UODATAVALID)
        MCB_UODATAVALID_U <= 1'b1;
    else
        MCB_UODATAVALID_U <= MCB_UODATAVALID;
  end

  //**************************************************************************************************************
  //Always block to mux SDI, SDO, CS, and ADD depending on which IODRP is active: RZQ, ZIO or MCB's UI port (to IODRP2_MCBs)
  //**************************************************************************************************************
  always @(*) begin: ACTIVE_IODRP
    case (Active_IODRP)
      RZQ:      begin
        RZQ_IODRP_CS  = IODRP_CS;
        ZIO_IODRP_CS  = 1'b0;
        IODRP_SDO     = RZQ_IODRP_SDO;
      end
      ZIO:      begin
        RZQ_IODRP_CS  = 1'b0;
        ZIO_IODRP_CS  = IODRP_CS;
        IODRP_SDO     = ZIO_IODRP_SDO;
      end
      MCB_PORT: begin
        RZQ_IODRP_CS  = 1'b0;
        ZIO_IODRP_CS  = 1'b0;
        IODRP_SDO     = 1'b0;
      end
      default:  begin
        RZQ_IODRP_CS  = 1'b0;
        ZIO_IODRP_CS  = 1'b0;
        IODRP_SDO     = 1'b0;
      end
    endcase
  end

//******************************************************************
//State Machine's Always block / Case statement for Next State Logic
//
//The WAIT1,2,etc states were required after every state where the
//DRP controller was used to do a write to the IODRPs - this is because
//there's a clock cycle latency on IODRPCTRLR_RDY_BUSY_N whenever the DRP controller
//sees IODRPCTRLR_CMD_VALID go high.  OFF_RZQ_PTERM and OFF_ZIO_NTERM were added
//soley for the purpose of reducing power, particularly on RZQ as
//that pin is expected to have a permanent external resistor to gnd.
//******************************************************************
  always @(posedge UI_CLK) begin: NEXT_STATE_LOGIC
    if (RST_reg) begin                      // Synchronous reset
      MCB_CMD_VALID           <= 1'b0;
      MCB_UIADDR              <= 5'b0;
      MCB_UICMDEN             <= 1'b1;      // take control of UI/UO port
      MCB_UIDONECAL           <= 1'b0;      // tells MCB that it is in Soft Cal.
      MCB_USE_BKST            <= 1'b0;
      MCB_UIDRPUPDATE         <= 1'b1;
      Pre_SYSRST              <= 1'b1;      // keeps MCB in reset
      IODRPCTRLR_CMD_VALID    <= 1'b0;
      IODRPCTRLR_MEMCELL_ADDR <= NoOp;
      IODRPCTRLR_WRITE_DATA   <= 1'b0;
      IODRPCTRLR_R_WB         <= WRITE_MODE;
      IODRPCTRLR_USE_BKST     <= 1'b0;
      P_Term                  <= 6'b0;
      N_Term                  <= 7'b0;
      P_Term_s                <= 6'b0;
      N_Term_w                <= 7'b0;
      P_Term_w                <= 6'b0;
      N_Term_s                <= 7'b0;
      P_Term_Prev             <= 6'b0;
      N_Term_Prev             <= 7'b0;
      Active_IODRP            <= RZQ;
      MCB_UILDQSINC           <= 1'b0;      //no inc or dec
      MCB_UIUDQSINC           <= 1'b0;      //no inc or dec
      MCB_UILDQSDEC           <= 1'b0;      //no inc or dec
      MCB_UIUDQSDEC           <= 1'b0;      //no inc or dec
      counter_en              <= 1'b0;
      First_Dyn_Cal_Done      <= 1'b0;      //flag that the First Dynamic Calibration completed
      Max_Value               <= 8'b0;
      Max_Value_Previous      <= 8'b0;
      STATE                   <= START;
      DQS_DELAY               <= 8'h0; //tracks the cumulative incrementing/decrementing that has been done
      DQS_DELAY_INITIAL       <= 8'h0;
      TARGET_DQS_DELAY        <= 8'h0;
      LastPass_DynCal         <= `IN_TERM_PASS;
      First_In_Term_Done      <= 1'b0;
      MCB_UICMD               <= 1'b0;
      MCB_UICMDIN             <= 1'b0;
      MCB_UIDQCOUNT           <= 4'h0;
      counter_inc             <= 8'h0;
      counter_dec             <= 8'h0;
    end
    else begin
      counter_en              <= 1'b0;
      IODRPCTRLR_CMD_VALID    <= 1'b0;
      IODRPCTRLR_MEMCELL_ADDR <= NoOp;
      IODRPCTRLR_R_WB         <= READ_MODE;
      IODRPCTRLR_USE_BKST     <= 1'b0;
      MCB_CMD_VALID           <= 1'b0;
      MCB_UILDQSINC           <= 1'b0;            //no inc or dec
      MCB_UIUDQSINC           <= 1'b0;            //no inc or dec
      MCB_UILDQSDEC           <= 1'b0;            //no inc or dec
      MCB_UIUDQSDEC           <= 1'b0;            //no inc or dec
      MCB_USE_BKST            <= 1'b0;
      MCB_UICMDIN             <= 1'b0;
      DQS_DELAY               <= DQS_DELAY;
      TARGET_DQS_DELAY        <= TARGET_DQS_DELAY;
      case (STATE)
        START:  begin   //h00
          MCB_UICMDEN     <= 1'b1;        // take control of UI/UO port
          MCB_UIDONECAL   <= 1'b0;        // tells MCB that it is in Soft Cal.
          P_Term          <= 6'b0;
          N_Term          <= 7'b0;
          Pre_SYSRST      <= 1'b1;        // keeps MCB in reset
          LastPass_DynCal <= `IN_TERM_PASS;
          if (SKIP_IN_TERM_CAL) begin
               STATE <= WAIT_FOR_START_BROADCAST;
               P_Term <= 'b0;
               N_Term <= 'b0;
            end
          else if (IODRPCTRLR_RDY_BUSY_N)
            STATE  <= LOAD_RZQ_NTERM;
          else
            STATE  <= START;
        end
//***************************
// IOB INPUT TERMINATION CAL
//***************************
        LOAD_RZQ_NTERM: begin   //h01
          Active_IODRP            <= RZQ;
          IODRPCTRLR_CMD_VALID    <= 1'b1;
          IODRPCTRLR_MEMCELL_ADDR <= NTerm;
          IODRPCTRLR_WRITE_DATA   <= {1'b0,N_Term};
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          if (IODRPCTRLR_RDY_BUSY_N)
            STATE <= LOAD_RZQ_NTERM;
          else
            STATE <= WAIT1;
        end
        WAIT1:  begin   //h02
          if (!IODRPCTRLR_RDY_BUSY_N)
            STATE <= WAIT1;
          else
            STATE <= LOAD_RZQ_PTERM;
        end
        LOAD_RZQ_PTERM: begin //h03
          IODRPCTRLR_CMD_VALID    <= 1'b1;
          IODRPCTRLR_MEMCELL_ADDR <= PTerm;
          IODRPCTRLR_WRITE_DATA   <= {2'b00,P_Term};
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          if (IODRPCTRLR_RDY_BUSY_N)
            STATE <= LOAD_RZQ_PTERM;
          else
            STATE <= WAIT2;
        end
        WAIT2:  begin   //h04
          if (!IODRPCTRLR_RDY_BUSY_N)
            STATE <= WAIT2;
          else if ((RZQ_IN)||(P_Term == 6'b111111)) begin
            STATE <= MULTIPLY_DIVIDE;//LOAD_ZIO_PTERM;
          end
          else
            STATE <= INC_PTERM;
        end
        INC_PTERM: begin    //h05
          P_Term  <= P_Term + 1;
          STATE   <= LOAD_RZQ_PTERM;
        end
        MULTIPLY_DIVIDE: begin //06
           P_Term  <= Mult_Divide(P_Term-1, MULT, DIV);  //4/13/2011 compensate the added sync FF
           STATE <= LOAD_ZIO_PTERM;
        end
        LOAD_ZIO_PTERM: begin   //h07
          Active_IODRP            <= ZIO;
          IODRPCTRLR_CMD_VALID    <= 1'b1;
          IODRPCTRLR_MEMCELL_ADDR <= PTerm;
          IODRPCTRLR_WRITE_DATA   <= {2'b00,P_Term};
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          if (IODRPCTRLR_RDY_BUSY_N)
            STATE <= LOAD_ZIO_PTERM;
          else
            STATE <= WAIT3;
        end
        WAIT3:  begin   //h08
          if (!IODRPCTRLR_RDY_BUSY_N)
            STATE <= WAIT3;
          else begin
            STATE   <= LOAD_ZIO_NTERM;
          end
        end
        LOAD_ZIO_NTERM: begin   //h09
          Active_IODRP            <= ZIO;
          IODRPCTRLR_CMD_VALID    <= 1'b1;
          IODRPCTRLR_MEMCELL_ADDR <= NTerm;
          IODRPCTRLR_WRITE_DATA   <= {1'b0,N_Term};
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          if (IODRPCTRLR_RDY_BUSY_N)
            STATE <= LOAD_ZIO_NTERM;
          else
            STATE <= WAIT4;
        end
        WAIT4:  begin   //h0A
          if (!IODRPCTRLR_RDY_BUSY_N)
            STATE <= WAIT4;
          else if ((!ZIO_IN)||(N_Term == 7'b1111111)) begin
            if (PNSKEW) begin
              STATE    <= SKEW;
            end
            else 
            STATE <= WAIT_FOR_START_BROADCAST;
          end
          else
            STATE <= INC_NTERM;
        end
        INC_NTERM: begin    //h0B
          N_Term  <= N_Term + 1;
          STATE   <= LOAD_ZIO_NTERM;
        end
        SKEW : begin //0C
            P_Term_s <= Mult_Divide(P_Term, MULT_S, DIV_S);
            N_Term_w <= Mult_Divide(N_Term-1, MULT_W, DIV_W);
            P_Term_w <= Mult_Divide(P_Term, MULT_W, DIV_W);
            N_Term_s <= Mult_Divide(N_Term-1, MULT_S, DIV_S);
            P_Term   <= Mult_Divide(P_Term, MULT_S, DIV_S);
            N_Term   <= Mult_Divide(N_Term-1, MULT_W, DIV_W);
            STATE  <= WAIT_FOR_START_BROADCAST;
        end
        WAIT_FOR_START_BROADCAST: begin   //h0D
          Pre_SYSRST    <= 1'b0;      //release SYSRST, but keep UICMDEN=1 and UIDONECAL=0. This is needed to do Broadcast through UI interface, while keeping the MCB in calibration mode
          Active_IODRP  <= MCB_PORT;
          if (START_BROADCAST && IODRPCTRLR_RDY_BUSY_N) begin
            if (P_Term != P_Term_Prev || SKIP_IN_TERM_CAL   ) begin
              STATE       <= BROADCAST_PTERM;
              P_Term_Prev <= P_Term;
            end
            else if (N_Term != N_Term_Prev) begin
              N_Term_Prev <= N_Term;
              STATE       <= BROADCAST_NTERM;
            end
            else
              STATE <= OFF_RZQ_PTERM;
          end
          else
            STATE   <= WAIT_FOR_START_BROADCAST;
        end
        BROADCAST_PTERM:  begin    //h0E
//SBS redundant?          MCB_UICMDEN             <= 1'b1;        // take control of UI/UO port for reentrant use of dynamic In Term tuning
          IODRPCTRLR_MEMCELL_ADDR <= PTerm;
          IODRPCTRLR_WRITE_DATA   <= {2'b00,P_Term};
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          MCB_CMD_VALID           <= 1'b1;
          MCB_UIDRPUPDATE         <= ~First_In_Term_Done; // Set the update flag if this is the first time through
          MCB_USE_BKST            <= 1'b1;
          if (MCB_RDY_BUSY_N)
            STATE <= BROADCAST_PTERM;
          else
            STATE <= WAIT5;
        end
        WAIT5:  begin   //h0F
          if (!MCB_RDY_BUSY_N)
            STATE <= WAIT5;
          else if (First_In_Term_Done) begin  // If first time through is already set, then this must be dynamic in term
            if (MCB_UOREFRSHFLAG) begin
              MCB_UIDRPUPDATE <= 1'b1;
              if (N_Term != N_Term_Prev) begin
                N_Term_Prev <= N_Term;
                STATE       <= BROADCAST_NTERM;
              end
              else
                STATE <= OFF_RZQ_PTERM;
            end
            else
              STATE <= WAIT5;   // wait for a Refresh cycle
          end
          else begin
            N_Term_Prev <= N_Term;
            STATE <= BROADCAST_NTERM;
          end
        end
        BROADCAST_NTERM:  begin    //h10
          IODRPCTRLR_MEMCELL_ADDR <= NTerm;
          IODRPCTRLR_WRITE_DATA   <= {2'b00,N_Term};
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          MCB_CMD_VALID           <= 1'b1;
          MCB_USE_BKST            <= 1'b1;
          MCB_UIDRPUPDATE         <= ~First_In_Term_Done; // Set the update flag if this is the first time through
          if (MCB_RDY_BUSY_N)
            STATE <= BROADCAST_NTERM;
          else
            STATE <= WAIT6;
        end
        WAIT6:  begin             // 7'h11
          if (!MCB_RDY_BUSY_N)
            STATE <= WAIT6;
          else if (First_In_Term_Done) begin  // If first time through is already set, then this must be dynamic in term
            if (MCB_UOREFRSHFLAG) begin
              MCB_UIDRPUPDATE <= 1'b1;
              STATE           <= OFF_RZQ_PTERM;
            end
            else
              STATE <= WAIT6;   // wait for a Refresh cycle
          end
          else
               STATE <= LDQS_CLK_WRITE_P_TERM;
        end
          LDQS_CLK_WRITE_P_TERM:  begin   //7'h12
          IODRPCTRLR_MEMCELL_ADDR <= PTerm;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          IODRPCTRLR_WRITE_DATA   <= {2'b00, P_Term_w};
          MCB_UIADDR              <= IOI_LDQS_CLK;
          MCB_CMD_VALID           <= 1'b1;
          if (MCB_RDY_BUSY_N)
            STATE <= LDQS_CLK_WRITE_P_TERM;
          else
            STATE <= LDQS_CLK_P_TERM_WAIT;
        end
        LDQS_CLK_P_TERM_WAIT:  begin     //7'h13  
          if (!MCB_RDY_BUSY_N)
            STATE <= LDQS_CLK_P_TERM_WAIT;
          else begin
            STATE           <= LDQS_CLK_WRITE_N_TERM;
          end
        end
        LDQS_CLK_WRITE_N_TERM:  begin   //7'h14
          IODRPCTRLR_MEMCELL_ADDR <= NTerm;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          IODRPCTRLR_WRITE_DATA   <= {1'b0, N_Term_s};
          MCB_UIADDR              <= IOI_LDQS_CLK;
          MCB_CMD_VALID           <= 1'b1;
          if (MCB_RDY_BUSY_N)
            STATE <= LDQS_CLK_WRITE_N_TERM;
          else
            STATE <= LDQS_CLK_N_TERM_WAIT;
        end
        LDQS_CLK_N_TERM_WAIT:  begin   //7'h15
          if (!MCB_RDY_BUSY_N)
            STATE <= LDQS_CLK_N_TERM_WAIT;
          else begin
            STATE           <= LDQS_PIN_WRITE_P_TERM;
          end
        end
         LDQS_PIN_WRITE_P_TERM:  begin //7'h16
          IODRPCTRLR_MEMCELL_ADDR <= PTerm;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          IODRPCTRLR_WRITE_DATA   <= {2'b00, P_Term_s};
          MCB_UIADDR              <= IOI_LDQS_PIN;
          MCB_CMD_VALID           <= 1'b1;
          if (MCB_RDY_BUSY_N)
            STATE <= LDQS_PIN_WRITE_P_TERM;
          else
            STATE <= LDQS_PIN_P_TERM_WAIT;
        end
        LDQS_PIN_P_TERM_WAIT:  begin   //7'h17
          if (!MCB_RDY_BUSY_N)
            STATE <= LDQS_PIN_P_TERM_WAIT;
          else begin
            STATE           <= LDQS_PIN_WRITE_N_TERM;
          end
        end
         LDQS_PIN_WRITE_N_TERM:  begin //7'h18
          IODRPCTRLR_MEMCELL_ADDR <= NTerm;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          IODRPCTRLR_WRITE_DATA   <= {1'b0, N_Term_w};
          MCB_UIADDR              <= IOI_LDQS_PIN;
          MCB_CMD_VALID           <= 1'b1;
          if (MCB_RDY_BUSY_N)
            STATE <= LDQS_PIN_WRITE_N_TERM;
          else
            STATE <= LDQS_PIN_N_TERM_WAIT;
        end
        LDQS_PIN_N_TERM_WAIT:  begin  //7'h19
          if (!MCB_RDY_BUSY_N)
            STATE <= LDQS_PIN_N_TERM_WAIT;
          else begin
            STATE           <= UDQS_CLK_WRITE_P_TERM;
          end
        end
        UDQS_CLK_WRITE_P_TERM:  begin //7'h1A
          IODRPCTRLR_MEMCELL_ADDR <= PTerm;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          IODRPCTRLR_WRITE_DATA   <= {2'b00, P_Term_w};
          MCB_UIADDR              <= IOI_UDQS_CLK;
          MCB_CMD_VALID           <= 1'b1;
          if (MCB_RDY_BUSY_N)
            STATE <= UDQS_CLK_WRITE_P_TERM;
          else
            STATE <= UDQS_CLK_P_TERM_WAIT;
        end
        UDQS_CLK_P_TERM_WAIT:  begin //7'h1B
          if (!MCB_RDY_BUSY_N)
            STATE <= UDQS_CLK_P_TERM_WAIT;
          else begin
            STATE           <= UDQS_CLK_WRITE_N_TERM;
          end
        end
        UDQS_CLK_WRITE_N_TERM:  begin //7'h1C
          IODRPCTRLR_MEMCELL_ADDR <= NTerm;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          IODRPCTRLR_WRITE_DATA   <= {1'b0, N_Term_s};
          MCB_UIADDR              <= IOI_UDQS_CLK;
          MCB_CMD_VALID           <= 1'b1;
          if (MCB_RDY_BUSY_N)
            STATE <= UDQS_CLK_WRITE_N_TERM;
          else
            STATE <= UDQS_CLK_N_TERM_WAIT;
        end
        UDQS_CLK_N_TERM_WAIT:  begin //7'h1D
          if (!MCB_RDY_BUSY_N)
            STATE <= UDQS_CLK_N_TERM_WAIT;
          else begin
            STATE           <= UDQS_PIN_WRITE_P_TERM;
          end
        end
         UDQS_PIN_WRITE_P_TERM:  begin //7'h1E
          IODRPCTRLR_MEMCELL_ADDR <= PTerm;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          IODRPCTRLR_WRITE_DATA   <= {2'b00, P_Term_s};
          MCB_UIADDR              <= IOI_UDQS_PIN;
          MCB_CMD_VALID           <= 1'b1;
          if (MCB_RDY_BUSY_N)
            STATE <= UDQS_PIN_WRITE_P_TERM;
          else
            STATE <= UDQS_PIN_P_TERM_WAIT;
        end
        UDQS_PIN_P_TERM_WAIT:  begin  //7'h1F
          if (!MCB_RDY_BUSY_N)
            STATE <= UDQS_PIN_P_TERM_WAIT;
          else begin
            STATE           <= UDQS_PIN_WRITE_N_TERM;
          end
        end
         UDQS_PIN_WRITE_N_TERM:  begin  //7'h20
          IODRPCTRLR_MEMCELL_ADDR <= NTerm;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          IODRPCTRLR_WRITE_DATA   <= {1'b0, N_Term_w};
          MCB_UIADDR              <= IOI_UDQS_PIN;
          MCB_CMD_VALID           <= 1'b1;
          if (MCB_RDY_BUSY_N)
            STATE <= UDQS_PIN_WRITE_N_TERM;
          else
            STATE <= UDQS_PIN_N_TERM_WAIT;
        end
        UDQS_PIN_N_TERM_WAIT:  begin   //7'h21
          if (!MCB_RDY_BUSY_N)
            STATE <= UDQS_PIN_N_TERM_WAIT;
          else begin
            STATE           <= OFF_RZQ_PTERM;
          end
        end
        OFF_RZQ_PTERM:  begin        // 7'h22
          Active_IODRP            <= RZQ;
          IODRPCTRLR_CMD_VALID    <= 1'b1;
          IODRPCTRLR_MEMCELL_ADDR <= PTerm;
          IODRPCTRLR_WRITE_DATA   <= 8'b00;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          P_Term                  <= 6'b0;
          N_Term                  <= 5'b0;
          MCB_UIDRPUPDATE         <= ~First_In_Term_Done; // Set the update flag if this is the first time through
          if (IODRPCTRLR_RDY_BUSY_N)
            STATE <= OFF_RZQ_PTERM;
          else
            STATE <= WAIT7;
        end
        WAIT7:  begin             // 7'h23
          if (!IODRPCTRLR_RDY_BUSY_N)
            STATE <= WAIT7;
          else
            STATE <= OFF_ZIO_NTERM;
        end
        OFF_ZIO_NTERM:  begin     // 7'h24
          Active_IODRP            <= ZIO;
          IODRPCTRLR_CMD_VALID    <= 1'b1;
          IODRPCTRLR_MEMCELL_ADDR <= NTerm;
          IODRPCTRLR_WRITE_DATA   <= 8'b00;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          if (IODRPCTRLR_RDY_BUSY_N)
            STATE <= OFF_ZIO_NTERM;
          else
            STATE <= WAIT8;
        end
        WAIT8:  begin             // 7'h25
          if (!IODRPCTRLR_RDY_BUSY_N)
            STATE <= WAIT8;
          else begin
            if (First_In_Term_Done) begin
              STATE               <= START_DYN_CAL; // No need to reset the MCB if we are in InTerm tuning
            end
            else begin
              STATE               <= WRITE_CALIBRATE; // go read the first Max_Value from RZQ
            end
          end
        end
        RST_DELAY:  begin     // 7'h26
          if (Block_Reset) begin  // this ensures that more than 512 clock cycles occur since the last reset after MCB_WRITE_CALIBRATE ???
            STATE       <= RST_DELAY;
          end			 
          else begin
            STATE <= START_DYN_CAL_PRE;
          end
        end
       
//****************************
// DYNAMIC CALIBRATION PORTION
//****************************
        START_DYN_CAL_PRE:  begin   // 7'h27
          LastPass_DynCal <= `IN_TERM_PASS;
          MCB_UICMDEN     <= 1'b0;    // release UICMDEN
          MCB_UIDONECAL   <= 1'b1;    // release UIDONECAL - MCB will now initialize.
          Pre_SYSRST      <= 1'b1;    // SYSRST pulse
          if (~CALMODE_EQ_CALIBRATION)      // if C_MC_CALIBRATION_MODE is set to NOCALIBRATION
            STATE       <= START_DYN_CAL;  // we'll skip setting the DQS delays manually
          else if (pre_sysrst_minpulse_width_ok)   
            STATE       <= WAIT_FOR_UODONE;
          end
        WAIT_FOR_UODONE:  begin  //7'h28
          Pre_SYSRST      <= 1'b0;    // SYSRST pulse
          if (IODRPCTRLR_RDY_BUSY_N && MCB_UODONECAL) begin //IODRP Controller needs to be ready, & MCB needs to be done with hard calibration
            MCB_UICMDEN <= 1'b1;    // grab UICMDEN
            DQS_DELAY_INITIAL <= Mult_Divide(Max_Value, DQS_NUMERATOR, DQS_DENOMINATOR);
            STATE       <= LDQS_WRITE_POS_INDELAY;
          end
          else
            STATE       <= WAIT_FOR_UODONE;
        end
        LDQS_WRITE_POS_INDELAY:  begin// 7'h29
          IODRPCTRLR_MEMCELL_ADDR <= PosEdgeInDly;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          IODRPCTRLR_WRITE_DATA   <= DQS_DELAY_INITIAL;
          MCB_UIADDR              <= IOI_LDQS_CLK;
          MCB_CMD_VALID           <= 1'b1;
          if (MCB_RDY_BUSY_N)
            STATE <= LDQS_WRITE_POS_INDELAY;
          else
            STATE <= LDQS_WAIT1;
        end
        LDQS_WAIT1:  begin           // 7'h2A
          if (!MCB_RDY_BUSY_N)
            STATE <= LDQS_WAIT1;
          else begin
            STATE           <= LDQS_WRITE_NEG_INDELAY;
          end
        end
        LDQS_WRITE_NEG_INDELAY:  begin// 7'h2B
          IODRPCTRLR_MEMCELL_ADDR <= NegEdgeInDly;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          IODRPCTRLR_WRITE_DATA   <= DQS_DELAY_INITIAL;
          MCB_UIADDR              <= IOI_LDQS_CLK;
          MCB_CMD_VALID           <= 1'b1;
          if (MCB_RDY_BUSY_N)
            STATE <= LDQS_WRITE_NEG_INDELAY;
          else
            STATE <= LDQS_WAIT2;
        end
        LDQS_WAIT2:  begin           // 7'h2C
          if (!MCB_RDY_BUSY_N)
            STATE <= LDQS_WAIT2;
          else begin
            STATE <= UDQS_WRITE_POS_INDELAY;
          end
        end
        UDQS_WRITE_POS_INDELAY:  begin// 7'h2D
          IODRPCTRLR_MEMCELL_ADDR <= PosEdgeInDly;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          IODRPCTRLR_WRITE_DATA   <= DQS_DELAY_INITIAL;
          MCB_UIADDR              <= IOI_UDQS_CLK;
          MCB_CMD_VALID           <= 1'b1;
          if (MCB_RDY_BUSY_N)
            STATE <= UDQS_WRITE_POS_INDELAY;
          else
            STATE <= UDQS_WAIT1;
        end
        UDQS_WAIT1:  begin           // 7'h2E
          if (!MCB_RDY_BUSY_N)
            STATE <= UDQS_WAIT1;
          else begin
            STATE           <= UDQS_WRITE_NEG_INDELAY;
          end
        end
        UDQS_WRITE_NEG_INDELAY:  begin// 7'h2F
          IODRPCTRLR_MEMCELL_ADDR <= NegEdgeInDly;
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          IODRPCTRLR_WRITE_DATA   <= DQS_DELAY_INITIAL;
          MCB_UIADDR              <= IOI_UDQS_CLK;
          MCB_CMD_VALID           <= 1'b1;
          if (MCB_RDY_BUSY_N)
            STATE <= UDQS_WRITE_NEG_INDELAY;
          else
            STATE <= UDQS_WAIT2;
        end
        UDQS_WAIT2:  begin           // 7'h30
          if (!MCB_RDY_BUSY_N)
            STATE <= UDQS_WAIT2;
          else begin
            DQS_DELAY         <= DQS_DELAY_INITIAL;
            TARGET_DQS_DELAY  <= DQS_DELAY_INITIAL;
            STATE             <= START_DYN_CAL;
          end
        end
//**************************************************************************************
        START_DYN_CAL:  begin       // 7'h31
          Pre_SYSRST        <= 1'b0;      // SYSRST not driven
          counter_inc       <= 8'b0;
          counter_dec       <= 8'b0;
          if (SKIP_DYNAMIC_DQS_CAL & SKIP_DYN_IN_TERMINATION)
            STATE <= DONE;  //if we're skipping both dynamic algorythms, go directly to DONE
          else
          if (IODRPCTRLR_RDY_BUSY_N && MCB_UODONECAL && ~SELFREFRESH_REQ_R1 ) begin  //IODRP Controller needs to be ready, & MCB needs to be done with hard calibration

            // Alternate between Dynamic Input Termination and Dynamic Tuning routines
            if (~SKIP_DYN_IN_TERMINATION & (LastPass_DynCal == `DYN_CAL_PASS)) begin
              LastPass_DynCal <= `IN_TERM_PASS;
              STATE           <= LOAD_RZQ_NTERM;
            end
            else begin
              LastPass_DynCal <= `DYN_CAL_PASS;
              STATE           <= WRITE_CALIBRATE;
            end
          end
          else
            STATE     <= START_DYN_CAL;
        end
        WRITE_CALIBRATE:  begin   // 7'h32
          Pre_SYSRST              <= 1'b0; // SYSRST not driven
          IODRPCTRLR_CMD_VALID    <= 1'b1;
          IODRPCTRLR_MEMCELL_ADDR <= DelayControl;
          IODRPCTRLR_WRITE_DATA   <= 8'h20; // Set calibrate bit
          IODRPCTRLR_R_WB         <= WRITE_MODE;
          Active_IODRP            <= RZQ;
          if (IODRPCTRLR_RDY_BUSY_N)
            STATE <= WRITE_CALIBRATE;
          else
            STATE <= WAIT9;
        end
        WAIT9:  begin     // 7'h33
          counter_en  <= 1'b1;
          if (count < 6'd38)  //this adds approximately 22 extra clock cycles after WRITE_CALIBRATE
            STATE     <= WAIT9;
          else
            STATE     <= READ_MAX_VALUE;
        end
        READ_MAX_VALUE: begin     // 7'h34
          IODRPCTRLR_CMD_VALID    <= 1'b1;
          IODRPCTRLR_MEMCELL_ADDR <= MaxValue;
          IODRPCTRLR_R_WB         <= READ_MODE;
          Max_Value_Previous      <= Max_Value;
          if (IODRPCTRLR_RDY_BUSY_N)
            STATE <= READ_MAX_VALUE;
          else
            STATE <= WAIT10;
        end
        WAIT10:  begin    // 7'h35
          if (!IODRPCTRLR_RDY_BUSY_N)
            STATE <= WAIT10;
          else begin
            Max_Value           <= IODRPCTRLR_READ_DATA;  //record the Max_Value from the IODRP controller
            if (~First_In_Term_Done) begin
              STATE               <= RST_DELAY;
              First_In_Term_Done  <= 1'b1;
            end
            else
              STATE               <= ANALYZE_MAX_VALUE;
          end
        end
        ANALYZE_MAX_VALUE:  begin // 7'h36   only do a Inc or Dec during a REFRESH cycle.
          if (!First_Dyn_Cal_Done)
            STATE <= FIRST_DYN_CAL;
          else
            if ((Max_Value<Max_Value_Previous)&&(Max_Value_Delta_Dn>=INCDEC_THRESHOLD)) begin
              STATE <= DECREMENT;         //May need to Decrement
              TARGET_DQS_DELAY   <= Mult_Divide(Max_Value, DQS_NUMERATOR, DQS_DENOMINATOR);
            end
          else
            if ((Max_Value>Max_Value_Previous)&&(Max_Value_Delta_Up>=INCDEC_THRESHOLD)) begin
              STATE <= INCREMENT;         //May need to Increment
              TARGET_DQS_DELAY   <= Mult_Divide(Max_Value, DQS_NUMERATOR, DQS_DENOMINATOR);
            end
          else begin
            Max_Value           <= Max_Value_Previous;
            STATE <= START_DYN_CAL;
          end
        end
        FIRST_DYN_CAL:  begin // 7'h37
          First_Dyn_Cal_Done  <= 1'b1;          //set flag that the First Dynamic Calibration has been completed
          STATE               <= START_DYN_CAL;
        end
        INCREMENT: begin      // 7'h38
          STATE               <= START_DYN_CAL; // Default case: Inc is not high or no longer in REFRSH
          MCB_UILDQSINC       <= 1'b0;          // Default case: no inc or dec
          MCB_UIUDQSINC       <= 1'b0;          // Default case: no inc or dec
          MCB_UILDQSDEC       <= 1'b0;          // Default case: no inc or dec
          MCB_UIUDQSDEC       <= 1'b0;          // Default case: no inc or dec
          case (Inc_Dec_REFRSH_Flag)            // {Increment_Flag,Decrement_Flag,MCB_UOREFRSHFLAG},
            3'b101: begin
              counter_inc <= counter_inc + 1'b1;
                STATE               <= INCREMENT; //Increment is still high, still in REFRSH cycle
              if (DQS_DELAY < DQS_DELAY_UPPER_LIMIT && counter_inc >= 8'h04) begin //if not at the upper limit yet, and you've waited 4 clks, increment
                MCB_UILDQSINC       <= 1'b1;      //increment
                MCB_UIUDQSINC       <= 1'b1;      //increment
                DQS_DELAY           <= DQS_DELAY + 1'b1;
              end
            end
            3'b100: begin
              if (DQS_DELAY < DQS_DELAY_UPPER_LIMIT)
                STATE                <= INCREMENT; //Increment is still high, REFRESH ended - wait for next REFRESH
              end
            default:  
                STATE               <= START_DYN_CAL; // Default case
          endcase
        end
        DECREMENT: begin      // 7'h39
          STATE               <= START_DYN_CAL; // Default case: Dec is not high or no longer in REFRSH
          MCB_UILDQSINC       <= 1'b0;          // Default case: no inc or dec
          MCB_UIUDQSINC       <= 1'b0;          // Default case: no inc or dec
          MCB_UILDQSDEC       <= 1'b0;          // Default case: no inc or dec
          MCB_UIUDQSDEC       <= 1'b0;          // Default case: no inc or dec
          if (DQS_DELAY != 8'h00) begin
            case (Inc_Dec_REFRSH_Flag)            // {Increment_Flag,Decrement_Flag,MCB_UOREFRSHFLAG},
              3'b011: begin
                counter_dec <= counter_dec + 1'b1;
                  STATE               <= DECREMENT; // Decrement is still high, still in REFRESH cycle
                if (DQS_DELAY > DQS_DELAY_LOWER_LIMIT  && counter_dec >= 8'h04) begin //if not at the lower limit, and you've waited 4 clks, decrement
                  MCB_UILDQSDEC       <= 1'b1;      // decrement
                  MCB_UIUDQSDEC       <= 1'b1;      // decrement
                  DQS_DELAY           <= DQS_DELAY - 1'b1; //SBS
                end
              end
              3'b010: begin
                if (DQS_DELAY > DQS_DELAY_LOWER_LIMIT) //if not at the lower limit, decrement
                  STATE                 <= DECREMENT; //Decrement is still high, REFRESH ended - wait for next REFRESH
                end
              default: begin
                  STATE               <= START_DYN_CAL; // Default case
              end
            endcase
          end
        end
        DONE: begin           // 7'h3A
          Pre_SYSRST              <= 1'b0;    // SYSRST cleared
          MCB_UICMDEN             <= 1'b0;  // release UICMDEN
          STATE <= DONE;
        end
        default:        begin
          MCB_UICMDEN             <= 1'b0;  // release UICMDEN
          MCB_UIDONECAL           <= 1'b1;  // release UIDONECAL - MCB will now initialize.
          Pre_SYSRST              <= 1'b0;  // SYSRST not driven
          IODRPCTRLR_CMD_VALID    <= 1'b0;
          IODRPCTRLR_MEMCELL_ADDR <= 8'h00;
          IODRPCTRLR_WRITE_DATA   <= 8'h00;
          IODRPCTRLR_R_WB         <= 1'b0;
          IODRPCTRLR_USE_BKST     <= 1'b0;
          P_Term                  <= 6'b0;
          N_Term                  <= 5'b0;
          Active_IODRP            <= ZIO;
          Max_Value_Previous      <= 8'b0;
          MCB_UILDQSINC           <= 1'b0;  // no inc or dec
          MCB_UIUDQSINC           <= 1'b0;  // no inc or dec
          MCB_UILDQSDEC           <= 1'b0;  // no inc or dec
          MCB_UIUDQSDEC           <= 1'b0;  // no inc or dec
          counter_en              <= 1'b0;
          First_Dyn_Cal_Done      <= 1'b0;  // flag that the First Dynamic Calibration completed
          Max_Value               <= Max_Value;
          STATE                   <= START;
        end
      endcase
    end
  end

endmodule
