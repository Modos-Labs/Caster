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
//  /   /         Filename: mcb_raw_wrapper.v
// /___/   /\     Date Last Modified: $Date: 2011/06/02 07:17:24 $
// \   \  /  \    Date Created: Thu June 24 2008
//  \___\/\___\
//
//Device: Spartan6
//Design Name: DDR/DDR2/DDR3/LPDDR 
//Purpose:
//Reference:
//   This module is the intialization control logic of the memory interface.
//   All commands are issued from here acoording to the burst, CAS Latency and
//   the user commands.
//   
// Revised History:  
//    Rev 1.1 - added port_enable assignment for all configurations  and rearrange 
//              assignment siganls according to port number
//            - added timescale directive  -SN 7-28-08
//            - added C_ARB_NUM_TIME_SLOTS and removed the slot 12 through 
//              15 -SN 7-28-08
//            - changed C_MEM_DDR2_WRT_RECOVERY = (C_MEM_TWR /C_MEMCLK_PERIOD) -SN 7-28-08
//            - removed ghighb, gpwrdnb, gsr, gwe in port declaration. 
//              For now tb need to force the signals inside the MCB and Wrapper
//              until a glbl.v is ready.  Not sure how to do this in NCVerilog 
//              flow. -SN 7-28-08
//
//    Rev 1.2 -- removed p*_cmd_error signals -SN 8-05-08
//    Rev 1.3 -- Added gate logic for data port rd_en and wr_en in Config 3,4,5   - SN 8-8-08
//    Rev 1.4 -- update changes that required by MCB core.  - SN 9-11-09
//    Rev 1.5 -- update. CMD delays has been removed in Sept 26 database. -- SN 9-28-08
//               delay_cas_90,delay_ras_90,delay_cke_90,delay_odt_90,delay_rst_90 
//               delay_we_90 ,delay_address,delay_ba_90 =
//               --removed :assign #50 delay_dqnum = dqnum;
//               --removed :assign #50 delay_dqpum = dqpum;
//               --removed :assign #50 delay_dqnlm = dqnlm;
//               --removed :assign #50 delay_dqplm = dqplm;
//               --removed : delay_dqsIO_w_en_90_n
//               --removed : delay_dqsIO_w_en_90_p              
//               --removed : delay_dqsIO_w_en_0     
//               -- corrected spelling error: C_MEM_RTRAS
//    Rev 1.6 -- update IODRP2 and OSERDES connection and was updated by Chip.  1-12-09              
//                 -- rename the memc_wrapper.v to mcb_raw_wrapper.v
//    Rev 1.7   -- .READEN    is removed in IODRP2_MCB 1-28-09
//              -- connection has been updated                            
//    Rev 1.8   -- update memory parameter equations.    1-30_2009
//              -- added portion of Soft IP               
//              -- CAL_CLK_DIV is not used but MCB still has it
//    Rev  1.9  -- added Error checking for Invalid command to unidirectional port   
//    Rev  1.10 -- changed the backend connection so that Simulation will work while
//                 sw tools try to fix the model issues.                  2-3-2009      
//                 sysclk_2x_90 name is changed to sysclk_2x_180 . It created confusions.
//                 It is acutally 180 degree difference.
//    Rev  1.11 -- Added soft_calibration_top. 
//    Rev  1.12 -- fixed ui_clk connection to MCB when soft_calib_ip is on. 5-14-2009   
//    Rev  1.13 -- Added PULLUP/PULLDN for DQS/DQSN, UDQS/UDQSN lines.
//    Rev  1.14 -- Added minium condition for tRTP valud/                        
//    REv  1.15 -- Bring the SKIP_IN_TERM_CAL and SKIP_DYNAMIC_CAL from calib_ip to top.  6-16-2009
//    Rev  1.16 -- Fixed the WTR for DDR. 6-23-2009
//    Rev  1.17 -- Fixed width mismatch for px_cmd_ra,px_cmd_ca,px_cmd_ba 7-02-2009
//    Rev  1.18 -- Added lumpdelay parameters for 1.0 silicon support to bypass Calibration 7-10-2010
//    Rev  1.19 -- Added soft fix to support refresh command. 7-15-2009.
//    Rev  1.20 -- Turned on the CALIB_SOFT_IP and C_MC_CALIBRATION_MODE is used to enable/disable
//                 Dynamic DQS calibration in Soft Calibration module.
//    Rev  1.21 -- Added extra generate mcbx_dram_odt pin condition. It will not be generated if
//                 RTT value is set to "disabled"
//              -- Corrected the UIUDQSDEC connection between soft_calib and MCB.
//              -- PLL_LOCK pin to MCB tie high. Soft Calib module asserts MCB_RST when pll_lock is deasserted. 1-19-2010                
//    Rev  1.22 -- Added DDR2 Initialization fix to meet 400 ns wait as outlined in step d) of JEDEC DDR2 spec .
//    Rev  1.23 -- Added DDR2 Initialization fix when C_CALIB_SOFT_IP set to "FALSE" 
//    Rev  1.24 -- Fixed reset problem when MCB exits from SUSPEND SELFREFRESH mode.
//    Rev  1.25 -- Added a new parameter C_USR_INTERFACE_MODE for AXI interface application. Axi DDRx controller
//                 never assert wr_en  or rd_en when wr_full or rd_empty is asserted. 
//    Rev  1.26 -- Synchronize sys_rst before connecting to mcb_soft_calibration module to fix
//                 CDC static timing issue.
//*************************************************************************************************************************
`define DEBUG
`timescale 1ps / 1ps

module mcb_raw_wrapper #
 
 (

parameter  C_MEMCLK_PERIOD          = 2500,       // /Mem clk period (in ps)
parameter  C_PORT_ENABLE            = 6'b111111,    //  config1 : 6b'111111,  config2: 4'b1111. config3 : 3'b111, config4: 2'b11, config5 1'b1
                                                  //  C_PORT_ENABLE[5] => User port 5,  ...,C_PORT_ENABLE[0] => User port 0
// Should the C_MEM_ADDR_ORDER made available to user ??
parameter  C_MEM_ADDR_ORDER             = "BANK_ROW_COLUMN" , //RowBankCol//ADDR_ORDER_MC : 0: Bank Row Col 1: Row Bank Col. User Address mapping oreder


parameter C_USR_INTERFACE_MODE       = "NATIVE", // Option is "NATIVE", "AXI"
                                               // This should default to "NATIVE" and only AXI interface
                                               // can set to "AXI"
////////////////////////////////////////////////////////////////////////////////////////////////
//  The parameter belows are not exposed to non-embedded users.

// for now this arb_time_slot_x attributes will not exposed to user and will be generated from MIG tool 
// to translate the logical port to physical port. For advance user, translate the logical port
// to physical port before passing them to this wrapper.
// MIG need to save the user setting in project file.
parameter  C_ARB_NUM_TIME_SLOTS     = 12,                      // For advance mode, allow user to either choose 10 or 12
parameter  C_ARB_TIME_SLOT_0        = 18'o012345,               // Config 1: "B32_B32_X32_X32_X32_X32"
parameter  C_ARB_TIME_SLOT_1        = 18'o123450,               //            User port 0 --->MCB port 0,User port 1 --->MCB port 1 
parameter  C_ARB_TIME_SLOT_2        = 18'o234501,               //            User port 2 --->MCB port 2,User port 3 --->MCB port 3
parameter  C_ARB_TIME_SLOT_3        = 18'o345012,               //            User port 4 --->MCB port 4,User port 5 --->MCB port 5
parameter  C_ARB_TIME_SLOT_4        = 18'o450123,               // Config 2: "B32_B32_B32_B32"  
parameter  C_ARB_TIME_SLOT_5        = 18'o501234,             //            User port 0     --->  MCB port 0
parameter  C_ARB_TIME_SLOT_6        = 18'o012345,             //            User port 1     --->  MCB port 1
parameter  C_ARB_TIME_SLOT_7        = 18'o123450,             //            User port 2     --->  MCB port 2
parameter  C_ARB_TIME_SLOT_8        = 18'o234501,             //            User port 3     --->  MCB port 4
parameter  C_ARB_TIME_SLOT_9        = 18'o345012,             // Config 3: "B64_B32_B3"   
parameter  C_ARB_TIME_SLOT_10       = 18'o450123,             //            User port 0     --->  MCB port 0
parameter  C_ARB_TIME_SLOT_11       = 18'o501234,             //            User port 1     --->  MCB port 2
                                                               //            User port 2     --->  MCB port 4
                                                               // Config 4: "B64_B64"              
                                                               //            User port 0     --->  MCB port 0
                                                               //            User port 1     --->  MCB port 2
                                                               // Config 5  "B128"              
                                                               //            User port 0     --->  MCB port 0
parameter  C_PORT_CONFIG               =  "B128",     



// Memory Timings
parameter  C_MEM_TRAS              =   45000,            //CEIL (tRAS/tCK)
parameter  C_MEM_TRCD               =   12500,            //CEIL (tRCD/tCK)
parameter  C_MEM_TREFI              =   7800,             //CEIL (tREFI/tCK) number of clocks
parameter  C_MEM_TRFC               =   127500,           //CEIL (tRFC/tCK)
parameter  C_MEM_TRP                =   12500,            //CEIL (tRP/tCK)
parameter  C_MEM_TWR                =   15000,            //CEIL (tWR/tCK)
parameter  C_MEM_TRTP               =   7500,             //CEIL (tRTP/tCK)
parameter  C_MEM_TWTR               =   7500,

parameter  C_NUM_DQ_PINS               =  8,                   
parameter  C_MEM_TYPE                  =  "DDR3",  
parameter  C_MEM_DENSITY               =  "512M",
parameter  C_MEM_BURST_LEN             =  8,       // MIG Rules for setting this parameter
                                                   // For DDR3  this one always set to 8; 
                                                   // For DDR2  Config 1 : MemWidth x8,x16:=> 4; MemWidth  x4     => 8
                                                   //           Config 2 : MemWidth x8,x16:=> 4; MemWidth  x4     => 8
                                                   //           Config 3 : Data Port Width: 32   MemWidth x8,x16:=> 4; MemWidth  x4     => 8
                                                   //                      Data Port Width: 64   MemWidth x16   :=> 4; MemWidth  x8,x4     => 8
                                                   //           Config 4 : Data Port Width: 64   MemWidth x16   :=> 4; MemWidth  x4,x8, => 8    
                                                   //           Config 5 : Data Port Width: 128  MemWidth x4, x8,x16: => 8
                                                                                           
                                               
                                                              
parameter  C_MEM_CAS_LATENCY           =  4,
parameter  C_MEM_ADDR_WIDTH            =  13,    // extracted from selected Memory part
parameter  C_MEM_BANKADDR_WIDTH        =  3,     // extracted from selected Memory part
parameter  C_MEM_NUM_COL_BITS          =  11,    // extracted from selected Memory part

parameter  C_MEM_DDR3_CAS_LATENCY      = 7,   
parameter  C_MEM_MOBILE_PA_SR          = "FULL",  //"FULL", "HALF" Mobile DDR Partial Array Self-Refresh 
parameter  C_MEM_DDR1_2_ODS            = "FULL",  //"FULL"  :REDUCED" 
parameter  C_MEM_DDR3_ODS              = "DIV6",   
parameter  C_MEM_DDR2_RTT              = "50OHMS",    
parameter  C_MEM_DDR3_RTT              =  "DIV2",  
parameter  C_MEM_MDDR_ODS              =  "FULL",   

parameter  C_MEM_DDR2_DIFF_DQS_EN      =  "YES", 
parameter  C_MEM_DDR2_3_PA_SR          =  "OFF",  
parameter  C_MEM_DDR3_CAS_WR_LATENCY   =   5,        // this parameter is hardcoded  by MIG tool which depends on the memory clock frequency
                                                     //C_MEMCLK_PERIOD ave = 2.5ns to < 3.3 ns, CWL = 5 
                                                     //C_MEMCLK_PERIOD ave = 1.875ns to < 2.5 ns, CWL = 6 
                                                     //C_MEMCLK_PERIOD ave = 1.5ns to <1.875ns, CSL = 7 
                                                     //C_MEMCLK_PERIOD avg = 1.25ns to < 1.5ns , CWL = 8

parameter  C_MEM_DDR3_AUTO_SR         =  "ENABLED",
parameter  C_MEM_DDR2_3_HIGH_TEMP_SR  =  "NORMAL",
parameter  C_MEM_DDR3_DYN_WRT_ODT     =  "OFF",
parameter  C_MEM_TZQINIT_MAXCNT       = 10'd512,  // DDR3 Minimum delay between resets

//Calibration 
parameter  C_MC_CALIB_BYPASS        = "NO",
parameter  C_MC_CALIBRATION_RA      = 15'h0000,
parameter  C_MC_CALIBRATION_BA      = 3'h0,

parameter C_CALIB_SOFT_IP           = "TRUE",
parameter C_SKIP_IN_TERM_CAL = 1'b0,     //provides option to skip the input termination calibration
parameter C_SKIP_DYNAMIC_CAL = 1'b0,     //provides option to skip the dynamic delay calibration
parameter C_SKIP_DYN_IN_TERM = 1'b1,     // provides option to skip the input termination calibration
parameter C_SIMULATION       = "FALSE",  // Tells us whether the design is being simulated or implemented

////////////////LUMP DELAY Params ////////////////////////////
/// ADDED for 1.0 silicon support to bypass Calibration //////
/// 07-10-09 chipl
//////////////////////////////////////////////////////////////
parameter LDQSP_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter UDQSP_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter LDQSN_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter UDQSN_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter DQ0_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter DQ1_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter DQ2_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter DQ3_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter DQ4_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter DQ5_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter DQ6_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter DQ7_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter DQ8_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter DQ9_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
parameter DQ10_TAP_DELAY_VAL = 0,  // 0 to 255 inclusive
parameter DQ11_TAP_DELAY_VAL = 0,  // 0 to 255 inclusive
parameter DQ12_TAP_DELAY_VAL = 0,  // 0 to 255 inclusive
parameter DQ13_TAP_DELAY_VAL = 0,  // 0 to 255 inclusive
parameter DQ14_TAP_DELAY_VAL = 0,  // 0 to 255 inclusive
parameter DQ15_TAP_DELAY_VAL = 0,  // 0 to 255 inclusive
//*************
// MIG tool need to do DRC on this parameter to make sure this is valid Column address to avoid boundary crossing for the current Burst Size setting.
parameter  C_MC_CALIBRATION_CA      = 12'h000,
parameter  C_MC_CALIBRATION_CLK_DIV     = 1,
parameter  C_MC_CALIBRATION_MODE    = "CALIBRATION"     ,   // "CALIBRATION", "NOCALIBRATION"
parameter  C_MC_CALIBRATION_DELAY   = "HALF",   // "QUARTER", "HALF","THREEQUARTER", "FULL"

parameter C_P0_MASK_SIZE           = 4,
parameter C_P0_DATA_PORT_SIZE      = 32,
parameter C_P1_MASK_SIZE           = 4,
parameter C_P1_DATA_PORT_SIZE         = 32

    )
  (
  
      // high-speed PLL clock interface
      
      input sysclk_2x,                         
      input sysclk_2x_180,                      
      input pll_ce_0,
      input pll_ce_90,
      input pll_lock,                          
      input sys_rst,                         
      // Not needed as ioi netlist are not used
//***********************************************************************************
//  Below User Port siganls needs to be customized when generating codes from MIG tool
//  The corresponding internal codes that directly use the commented out port signals 
//  needs to be removed when gernerating wrapper outputs.
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      //User Port0 Interface Signals
      // p0_xxxx signals  shows up in Config 1 , Config 2 , Config 3, Config4 and Config 5
      // cmd port 0 signals

      input             p0_arb_en,
      input             p0_cmd_clk,
      input             p0_cmd_en,
      input [2:0]       p0_cmd_instr,
      input [5:0]       p0_cmd_bl,
      input [29:0]      p0_cmd_byte_addr,
      output            p0_cmd_empty,
      output            p0_cmd_full,

      // Data Wr Port signals
      // p0_wr_xx signals  shows up in Config 1 
      // p0_wr_xx signals  shows up in Config 2
      // p0_wr_xx signals  shows up in Config 3
      // p0_wr_xx signals  shows up in Config 4
      // p0_wr_xx signals  shows up in Config 5
      
      input             p0_wr_clk,
      input             p0_wr_en,
      input [C_P0_MASK_SIZE - 1:0]      p0_wr_mask,
      input [C_P0_DATA_PORT_SIZE - 1:0] p0_wr_data,
      output            p0_wr_full,        //
      output            p0_wr_empty,//
      output [6:0]      p0_wr_count,//
      output            p0_wr_underrun,//
      output            p0_wr_error,//

      //Data Rd Port signals
      // p0_rd_xx signals  shows up in Config 1 
      // p0_rd_xx signals  shows up in Config 2
      // p0_rd_xx signals  shows up in Config 3
      // p0_rd_xx signals  shows up in Config 4
      // p0_rd_xx signals  shows up in Config 5
      
      input             p0_rd_clk,
      input             p0_rd_en,
      output [C_P0_DATA_PORT_SIZE - 1:0]        p0_rd_data,
      output            p0_rd_full,//
      output            p0_rd_empty,//
      output [6:0]      p0_rd_count,
      output            p0_rd_overflow,//
      output            p0_rd_error,//

      
      //****************************
      //User Port1 Interface Signals
      // This group of signals only appear on Config 1,2,3,4 when generated from MIG tool

      input             p1_arb_en,
      input             p1_cmd_clk,
      input             p1_cmd_en,
      input [2:0]       p1_cmd_instr,
      input [5:0]       p1_cmd_bl,
      input [29:0]      p1_cmd_byte_addr,
      output            p1_cmd_empty,
      output            p1_cmd_full,

      // Data Wr Port signals
      input             p1_wr_clk,
      input             p1_wr_en,
      input [C_P1_MASK_SIZE - 1:0]      p1_wr_mask,
      input [C_P1_DATA_PORT_SIZE - 1:0] p1_wr_data,
      output            p1_wr_full,
      output            p1_wr_empty,
      output [6:0]      p1_wr_count,
      output            p1_wr_underrun,
      output            p1_wr_error,

      //Data Rd Port signals
      input             p1_rd_clk,
      input             p1_rd_en,
      output [C_P1_DATA_PORT_SIZE - 1:0]        p1_rd_data,
      output            p1_rd_full,
      output            p1_rd_empty,
      output [6:0]      p1_rd_count,
      output            p1_rd_overflow,
      output            p1_rd_error,

      
      //****************************
      //User Port2 Interface Signals
      // This group of signals only appear on Config 1,2,3 when generated from MIG tool
      // p2_xxxx signals  shows up in Config 1 , Config 2 and Config 3
      // p_cmd port 2 signals

      input             p2_arb_en,
      input             p2_cmd_clk,
      input             p2_cmd_en,
      input [2:0]       p2_cmd_instr,
      input [5:0]       p2_cmd_bl,
      input [29:0]      p2_cmd_byte_addr,
      output            p2_cmd_empty,
      output            p2_cmd_full,

      // Data Wr Port signals
      // p2_wr_xx signals  shows up in Config 1 and Wr Dir  
      // p2_wr_xx signals  shows up in Config 2
      // p2_wr_xx signals  shows up in Config 3
      
      input             p2_wr_clk,
      input             p2_wr_en,
      input [3:0]       p2_wr_mask,
      input [31:0]      p2_wr_data,
      output            p2_wr_full,
      output            p2_wr_empty,
      output [6:0]      p2_wr_count,
      output            p2_wr_underrun,
      output            p2_wr_error,

      //Data Rd Port signals
      // p2_rd_xx signals  shows up in Config 1 and Rd Dir
      // p2_rd_xx signals  shows up in Config 2
      // p2_rd_xx signals  shows up in Config 3
      
      input             p2_rd_clk,
      input             p2_rd_en,
      output [31:0]     p2_rd_data,
      output            p2_rd_full,
      output            p2_rd_empty,
      output [6:0]      p2_rd_count,
      output            p2_rd_overflow,
      output            p2_rd_error,

      
      //****************************
      //User Port3 Interface Signals
      // This group of signals only appear on Config 1,2 when generated from MIG tool

      input             p3_arb_en,
      input             p3_cmd_clk,
      input             p3_cmd_en,
      input [2:0]       p3_cmd_instr,
      input [5:0]       p3_cmd_bl,
      input [29:0]      p3_cmd_byte_addr,
      output            p3_cmd_empty,
      output            p3_cmd_full,

      // Data Wr Port signals
      // p3_wr_xx signals  shows up in Config 1 and Wr Dir
      // p3_wr_xx signals  shows up in Config 2
      
      input             p3_wr_clk,
      input             p3_wr_en,
      input [3:0]       p3_wr_mask,
      input [31:0]      p3_wr_data,
      output            p3_wr_full,
      output            p3_wr_empty,
      output [6:0]      p3_wr_count,
      output            p3_wr_underrun,
      output            p3_wr_error,

      //Data Rd Port signals
      // p3_rd_xx signals  shows up in Config 1 and Rd Dir when generated from MIG ttols
      // p3_rd_xx signals  shows up in Config 2 
      
      input             p3_rd_clk,
      input             p3_rd_en,
      output [31:0]     p3_rd_data,
      output            p3_rd_full,
      output            p3_rd_empty,
      output [6:0]      p3_rd_count,
      output            p3_rd_overflow,
      output            p3_rd_error,
      //****************************
      //User Port4 Interface Signals
      // This group of signals only appear on Config 1,2,3,4 when generated from MIG tool
      // p4_xxxx signals only shows up in Config 1

      input             p4_arb_en,
      input             p4_cmd_clk,
      input             p4_cmd_en,
      input [2:0]       p4_cmd_instr,
      input [5:0]       p4_cmd_bl,
      input [29:0]      p4_cmd_byte_addr,
      output            p4_cmd_empty,
      output            p4_cmd_full,

      // Data Wr Port signals
      // p4_wr_xx signals only shows up in Config 1 and Wr Dir
      
      input             p4_wr_clk,
      input             p4_wr_en,
      input [3:0]       p4_wr_mask,
      input [31:0]      p4_wr_data,
      output            p4_wr_full,
      output            p4_wr_empty,
      output [6:0]      p4_wr_count,
      output            p4_wr_underrun,
      output            p4_wr_error,

      //Data Rd Port signals
      // p4_rd_xx signals only shows up in Config 1 and Rd Dir
      
      input             p4_rd_clk,
      input             p4_rd_en,
      output [31:0]     p4_rd_data,
      output            p4_rd_full,
      output            p4_rd_empty,
      output [6:0]      p4_rd_count,
      output            p4_rd_overflow,
      output            p4_rd_error,


      //****************************
      //User Port5 Interface Signals
      // p5_xxxx signals only shows up in Config 1; p5_wr_xx or p5_rd_xx depends on the user port settings

      input             p5_arb_en,
      input             p5_cmd_clk,
      input             p5_cmd_en,
      input [2:0]       p5_cmd_instr,
      input [5:0]       p5_cmd_bl,
      input [29:0]      p5_cmd_byte_addr,
      output            p5_cmd_empty,
      output            p5_cmd_full,

      // Data Wr Port signals
      input             p5_wr_clk,
      input             p5_wr_en,
      input [3:0]       p5_wr_mask,
      input [31:0]      p5_wr_data,
      output            p5_wr_full,
      output            p5_wr_empty,
      output [6:0]      p5_wr_count,
      output            p5_wr_underrun,
      output            p5_wr_error,

      //Data Rd Port signals
      input             p5_rd_clk,
      input             p5_rd_en,
      output [31:0]     p5_rd_data,
      output            p5_rd_full,
      output            p5_rd_empty,
      output [6:0]      p5_rd_count,
      output            p5_rd_overflow,
      output            p5_rd_error,
      
//*****************************************************
      // memory interface signals    
      output [C_MEM_ADDR_WIDTH-1:0]     mcbx_dram_addr,  
      output [C_MEM_BANKADDR_WIDTH-1:0] mcbx_dram_ba,
      output                            mcbx_dram_ras_n,                        
      output                            mcbx_dram_cas_n,                        
      output                            mcbx_dram_we_n,                         
                                      
      output                            mcbx_dram_cke,                          
      output                            mcbx_dram_clk,                          
      output                            mcbx_dram_clk_n,                        
      inout [C_NUM_DQ_PINS-1:0]         mcbx_dram_dq,              
      inout                             mcbx_dram_dqs,                          
      inout                             mcbx_dram_dqs_n,                        
      inout                             mcbx_dram_udqs,                         
      inout                             mcbx_dram_udqs_n,                       
      
      output                            mcbx_dram_udm,                          
      output                            mcbx_dram_ldm,                          
      output                            mcbx_dram_odt,                          
      output                            mcbx_dram_ddr3_rst,                     
      // Calibration signals
      input calib_recal,              // Input signal to trigger calibration
     // output calib_done,        // 0=calibration not done or is in progress.  
                                // 1=calibration is complete.  Also a MEM_READY indicator
                                
   //Input - RZQ pin from board - expected to have a 2*R resistor to ground
   //Input - Z-stated IO pin - either unbonded IO, or IO garanteed not to be driven externally
                                
      inout                             rzq,           // RZQ pin from board - expected to have a 2*R resistor to ground
      inout                             zio,           // Z-stated IO pin - either unbonded IO, or IO garanteed not to be driven externally
      // new added signals *********************************
      // these signals are for dynamic Calibration IP
      input                             ui_read,
      input                             ui_add,
      input                             ui_cs,
      input                             ui_clk,
      input                             ui_sdi,
      input     [4:0]                   ui_addr,
      input                             ui_broadcast,
      input                             ui_drp_update,
      input                             ui_done_cal,
      input                             ui_cmd,
      input                             ui_cmd_in,
      input                             ui_cmd_en,
      input     [3:0]                   ui_dqcount,
      input                             ui_dq_lower_dec,
      input                             ui_dq_lower_inc,
      input                             ui_dq_upper_dec,
      input                             ui_dq_upper_inc,
      input                             ui_udqs_inc,
      input                             ui_udqs_dec,
      input                             ui_ldqs_inc,
      input                             ui_ldqs_dec,
      output     [7:0]                  uo_data,
      output                            uo_data_valid,
      output                            uo_done_cal,
      output                            uo_cmd_ready_in,
      output                            uo_refrsh_flag,
      output                            uo_cal_start,
      output                            uo_sdo,
      output   [31:0]                   status,
      input                             selfrefresh_enter,              
      output                            selfrefresh_mode
         );
  function integer cdiv (input integer num,
                         input integer div); // ceiling divide
    begin
      cdiv = (num/div) + (((num%div)>0) ? 1 : 0);
    end
  endfunction // cdiv

// parameters added by AM for OSERDES2 12/09/2008, these parameters may not have to change 
localparam C_OSERDES2_DATA_RATE_OQ = "SDR";           //SDR, DDR
localparam C_OSERDES2_DATA_RATE_OT = "SDR";           //SDR, DDR
localparam C_OSERDES2_SERDES_MODE_MASTER  = "MASTER";        //MASTER, SLAVE
localparam C_OSERDES2_SERDES_MODE_SLAVE   = "SLAVE";        //MASTER, SLAVE
localparam C_OSERDES2_OUTPUT_MODE_SE      = "SINGLE_ENDED";   //SINGLE_ENDED, DIFFERENTIAL
localparam C_OSERDES2_OUTPUT_MODE_DIFF    = "DIFFERENTIAL";
 
localparam C_BUFPLL_0_LOCK_SRC       = "LOCK_TO_0";

localparam C_DQ_IODRP2_DATA_RATE             = "SDR";
localparam C_DQ_IODRP2_SERDES_MODE_MASTER    = "MASTER";
localparam C_DQ_IODRP2_SERDES_MODE_SLAVE     = "SLAVE";

localparam C_DQS_IODRP2_DATA_RATE             = "SDR";
localparam C_DQS_IODRP2_SERDES_MODE_MASTER    = "MASTER";
localparam C_DQS_IODRP2_SERDES_MODE_SLAVE     = "SLAVE";



     


// MIG always set the below ADD_LATENCY to zero
localparam  C_MEM_DDR3_ADD_LATENCY      =  "OFF";
localparam  C_MEM_DDR2_ADD_LATENCY      =  0; 
localparam  C_MEM_MOBILE_TC_SR          =  0; // not supported

     
//////////////////////////////////////////////////////////////////////////////////
                                              // Attribute Declarations
                                              // Attributes set from GUI
                                              //
                                         //
   // the local param for the time slot varis according to User Port Configuration  
   // This section also needs to be customized when gernerating wrapper outputs.
   //*****************************************************************************


// For Configuration 1  and this section will be used in RAW file
localparam arbtimeslot0   = {C_ARB_TIME_SLOT_0   };
localparam arbtimeslot1   = {C_ARB_TIME_SLOT_1   };
localparam arbtimeslot2   = {C_ARB_TIME_SLOT_2   };
localparam arbtimeslot3   = {C_ARB_TIME_SLOT_3   };
localparam arbtimeslot4   = {C_ARB_TIME_SLOT_4   };
localparam arbtimeslot5   = {C_ARB_TIME_SLOT_5   };
localparam arbtimeslot6   = {C_ARB_TIME_SLOT_6   };
localparam arbtimeslot7   = {C_ARB_TIME_SLOT_7   };
localparam arbtimeslot8   = {C_ARB_TIME_SLOT_8   };
localparam arbtimeslot9   = {C_ARB_TIME_SLOT_9   };
localparam arbtimeslot10  = {C_ARB_TIME_SLOT_10  };
localparam arbtimeslot11  = {C_ARB_TIME_SLOT_11  };


// convert the memory timing to memory clock units. I
localparam MEM_RAS_VAL  = ((C_MEM_TRAS + C_MEMCLK_PERIOD -1) /C_MEMCLK_PERIOD);
localparam MEM_RCD_VAL  = ((C_MEM_TRCD  + C_MEMCLK_PERIOD -1) /C_MEMCLK_PERIOD);
localparam MEM_REFI_VAL = ((C_MEM_TREFI + C_MEMCLK_PERIOD -1) /C_MEMCLK_PERIOD) - 25;
localparam MEM_RFC_VAL  = ((C_MEM_TRFC  + C_MEMCLK_PERIOD -1) /C_MEMCLK_PERIOD);
localparam MEM_RP_VAL   = ((C_MEM_TRP   + C_MEMCLK_PERIOD -1) /C_MEMCLK_PERIOD);
localparam MEM_WR_VAL   = ((C_MEM_TWR   + C_MEMCLK_PERIOD -1) /C_MEMCLK_PERIOD);
localparam MEM_RTP_CK    = cdiv(C_MEM_TRTP,C_MEMCLK_PERIOD);
localparam MEM_RTP_VAL = (C_MEM_TYPE == "DDR3") ? (MEM_RTP_CK < 4) ? 4 : MEM_RTP_CK
                                               : (MEM_RTP_CK < 2) ? 2 : MEM_RTP_CK;
localparam MEM_WTR_VAL  = (C_MEM_TYPE == "DDR")   ? 2 :
                          (C_MEM_TYPE == "DDR3")  ? 4 : 
                          (C_MEM_TYPE == "MDDR")  ? C_MEM_TWTR : 
                          (C_MEM_TYPE == "LPDDR")  ? C_MEM_TWTR : 
                          ((C_MEM_TYPE == "DDR2") && (((C_MEM_TWTR  + C_MEMCLK_PERIOD -1) /C_MEMCLK_PERIOD) > 2)) ? ((C_MEM_TWTR  + C_MEMCLK_PERIOD -1) /C_MEMCLK_PERIOD) : 
                          (C_MEM_TYPE == "DDR2")  ? 2 
                                                  : 3 ;
localparam  C_MEM_DDR2_WRT_RECOVERY = (C_MEM_TYPE != "DDR2") ? 5: ((C_MEM_TWR   + C_MEMCLK_PERIOD -1) /C_MEMCLK_PERIOD);
localparam  C_MEM_DDR3_WRT_RECOVERY = (C_MEM_TYPE != "DDR3") ? 5: ((C_MEM_TWR   + C_MEMCLK_PERIOD -1) /C_MEMCLK_PERIOD);
//localparam MEM_TYPE = (C_MEM_TYPE == "LPDDR") ? "MDDR": C_MEM_TYPE;



////////////////////////////////////////////////////////////////////////////
// wire Declarations
////////////////////////////////////////////////////////////////////////////





wire [31:0]  addr_in0;
reg [127:0]  allzero = 0;


// UNISIM Model <-> IOI
//dqs clock network interface
wire       dqs_out_p;              
wire       dqs_out_n;              

wire       dqs_sys_p;              //from dqs_gen to IOclk network
wire       dqs_sys_n;              //from dqs_gen to IOclk network
wire       udqs_sys_p;
wire       udqs_sys_n;

wire       dqs_p;                  // open net now ?
wire       dqs_n;                  // open net now ?



// IOI and IOB enable/tristate interface
wire dqIO_w_en_0;                //enable DQ pads
wire dqsIO_w_en_90_p;            //enable p side of DQS
wire dqsIO_w_en_90_n;            //enable n side of DQS


//memory chip control interface
wire [14:0]   address_90;
wire [2:0]    ba_90;     
wire          ras_90;
wire          cas_90;
wire          we_90 ;
wire          cke_90;
wire          odt_90;
wire          rst_90;

// calibration IDELAY control  signals
wire          ioi_drp_clk;          //DRP interface - synchronous clock output
wire  [4:0]   ioi_drp_addr;         //DRP interface - IOI selection
wire          ioi_drp_sdo;          //DRP interface - serial output for commmands
wire          ioi_drp_sdi;          //DRP interface - serial input for commands
wire          ioi_drp_cs;           //DRP interface - chip select doubles as DONE signal
wire          ioi_drp_add;          //DRP interface - serial address signal
wire          ioi_drp_broadcast;  
wire          ioi_drp_train;    


   // Calibration datacapture siganls
   
wire  [3:0]dqdonecount; //select signal for the datacapture 16 to 1 mux
wire  dq_in_p;          //positive signal sent to calibration logic
wire  dq_in_n;          //negative signal sent to calibration logic
wire  cal_done;   
   

//DQS calibration interface
wire       udqs_n;
wire       udqs_p;


wire            udqs_dqocal_p;
wire            udqs_dqocal_n;


// MUI enable interface
wire df_en_n90  ;

//INTERNAL SIGNAL FOR DRP chain
// IOI <-> MUI
wire ioi_int_tmp;

wire [15:0]dqo_n;  
wire [15:0]dqo_p;  
wire dqnlm;      
wire dqplm;      
wire dqnum;      
wire dqpum;      


// IOI <-> IOB   routes
wire  [C_MEM_ADDR_WIDTH-1:0]ioi_addr; 
wire  [C_MEM_BANKADDR_WIDTH-1:0]ioi_ba;    
wire  ioi_cas;   
wire  ioi_ck;    
wire  ioi_ckn;    
wire  ioi_cke;   
wire  [C_NUM_DQ_PINS-1:0]ioi_dq; 
wire  ioi_dqs;   
wire  ioi_dqsn;
wire  ioi_udqs;
wire  ioi_udqsn;   
wire  ioi_odt;   
wire  ioi_ras;   
wire  ioi_rst;   
wire  ioi_we;   
wire  ioi_udm;
wire  ioi_ldm;

wire  [15:0] in_dq;
wire  [C_NUM_DQ_PINS-1:0] in_pre_dq;



wire            in_dqs;     
wire            in_pre_dqsp;
wire            in_pre_dqsn;
wire            in_pre_udqsp;
wire            in_pre_udqsn;
wire            in_udqs;
     // Memory tri-state control signals
wire  [C_MEM_ADDR_WIDTH-1:0]t_addr; 
wire  [C_MEM_BANKADDR_WIDTH-1:0]t_ba;    
wire  t_cas;
wire  t_ck ;
wire  t_ckn;
wire  t_cke;
wire  [C_NUM_DQ_PINS-1:0]t_dq;
wire  t_dqs;     
wire  t_dqsn;
wire  t_udqs;
wire  t_udqsn;
wire  t_odt;     
wire  t_ras;     
wire  t_rst;     
wire  t_we ;     


wire  t_udm  ;
wire  t_ldm  ;



wire             idelay_dqs_ioi_s;
wire             idelay_dqs_ioi_m;
wire             idelay_udqs_ioi_s;
wire             idelay_udqs_ioi_m;


wire  dqs_pin;
wire  udqs_pin;

// USER Interface signals


// translated memory addresses
wire [14:0]p0_cmd_ra;
wire [2:0]p0_cmd_ba; 
wire [11:0]p0_cmd_ca;
wire [14:0]p1_cmd_ra;
wire [2:0]p1_cmd_ba; 
wire [11:0]p1_cmd_ca;
wire [14:0]p2_cmd_ra;
wire [2:0]p2_cmd_ba; 
wire [11:0]p2_cmd_ca;
wire [14:0]p3_cmd_ra;
wire [2:0]p3_cmd_ba; 
wire [11:0]p3_cmd_ca;
wire [14:0]p4_cmd_ra;
wire [2:0]p4_cmd_ba; 
wire [11:0]p4_cmd_ca;
wire [14:0]p5_cmd_ra;
wire [2:0]p5_cmd_ba; 
wire [11:0]p5_cmd_ca;

   // user command wires mapped from logical ports to physical ports
wire        mig_p0_arb_en;   
wire        mig_p0_cmd_clk;    
wire        mig_p0_cmd_en;     
wire [14:0] mig_p0_cmd_ra;     
wire [2:0]  mig_p0_cmd_ba;     
wire [11:0] mig_p0_cmd_ca;     

wire [2:0]  mig_p0_cmd_instr;   
wire [5:0]  mig_p0_cmd_bl;      
wire        mig_p0_cmd_empty;   
wire        mig_p0_cmd_full;    


wire        mig_p1_arb_en;   
wire        mig_p1_cmd_clk;    
wire        mig_p1_cmd_en;     
wire [14:0] mig_p1_cmd_ra;     
wire [2:0] mig_p1_cmd_ba;     
wire [11:0] mig_p1_cmd_ca;     

wire [2:0]  mig_p1_cmd_instr;   
wire [5:0]  mig_p1_cmd_bl;      
wire        mig_p1_cmd_empty;   
wire        mig_p1_cmd_full;    

wire        mig_p2_arb_en;   
wire        mig_p2_cmd_clk;    
wire        mig_p2_cmd_en;     
wire [14:0] mig_p2_cmd_ra;     
wire [2:0] mig_p2_cmd_ba;     
wire [11:0] mig_p2_cmd_ca;     
                  
wire [2:0]  mig_p2_cmd_instr;   
wire [5:0]  mig_p2_cmd_bl;      
wire        mig_p2_cmd_empty;   
wire        mig_p2_cmd_full;    

wire        mig_p3_arb_en;   
wire        mig_p3_cmd_clk;    
wire        mig_p3_cmd_en;     
wire [14:0] mig_p3_cmd_ra;     
wire [2:0] mig_p3_cmd_ba;     
wire [11:0] mig_p3_cmd_ca;     

wire [2:0]  mig_p3_cmd_instr;   
wire [5:0]  mig_p3_cmd_bl;      
wire        mig_p3_cmd_empty;   
wire        mig_p3_cmd_full;    

wire        mig_p4_arb_en;   
wire        mig_p4_cmd_clk;    
wire        mig_p4_cmd_en;     
wire [14:0] mig_p4_cmd_ra;     
wire [2:0] mig_p4_cmd_ba;     
wire [11:0] mig_p4_cmd_ca;     

wire [2:0]  mig_p4_cmd_instr;   
wire [5:0]  mig_p4_cmd_bl;      
wire        mig_p4_cmd_empty;   
wire        mig_p4_cmd_full;    

wire        mig_p5_arb_en;   
wire        mig_p5_cmd_clk;    
wire        mig_p5_cmd_en;     
wire [14:0] mig_p5_cmd_ra;     
wire [2:0] mig_p5_cmd_ba;     
wire [11:0] mig_p5_cmd_ca;     

wire [2:0]  mig_p5_cmd_instr;   
wire [5:0]  mig_p5_cmd_bl;      
wire        mig_p5_cmd_empty;   
wire        mig_p5_cmd_full;    

wire        mig_p0_wr_clk;
wire        mig_p0_rd_clk;
wire        mig_p1_wr_clk;
wire        mig_p1_rd_clk;
wire        mig_p2_clk;
wire        mig_p3_clk;
wire        mig_p4_clk;
wire        mig_p5_clk;

wire       mig_p0_wr_en;
wire       mig_p0_rd_en;
wire       mig_p1_wr_en;
wire       mig_p1_rd_en;
wire       mig_p2_en;
wire       mig_p3_en; 
wire       mig_p4_en; 
wire       mig_p5_en; 


wire [31:0]mig_p0_wr_data;
wire [31:0]mig_p1_wr_data;
wire [31:0]mig_p2_wr_data;
wire [31:0]mig_p3_wr_data;
wire [31:0]mig_p4_wr_data;
wire [31:0]mig_p5_wr_data;


wire  [C_P0_MASK_SIZE-1:0]mig_p0_wr_mask;
wire  [C_P1_MASK_SIZE-1:0]mig_p1_wr_mask;
wire  [3:0]mig_p2_wr_mask;
wire  [3:0]mig_p3_wr_mask;
wire  [3:0]mig_p4_wr_mask;
wire  [3:0]mig_p5_wr_mask;


wire  [31:0]mig_p0_rd_data; 
wire  [31:0]mig_p1_rd_data; 
wire  [31:0]mig_p2_rd_data; 
wire  [31:0]mig_p3_rd_data; 
wire  [31:0]mig_p4_rd_data; 
wire  [31:0]mig_p5_rd_data; 

wire  mig_p0_rd_overflow;
wire  mig_p1_rd_overflow;
wire  mig_p2_overflow;
wire  mig_p3_overflow;

wire  mig_p4_overflow;
wire  mig_p5_overflow;

wire  mig_p0_wr_underrun;
wire  mig_p1_wr_underrun;
wire  mig_p2_underrun;  
wire  mig_p3_underrun;  
wire  mig_p4_underrun;  
wire  mig_p5_underrun;  

wire       mig_p0_rd_error;
wire       mig_p0_wr_error;
wire       mig_p1_rd_error;
wire       mig_p1_wr_error;
wire       mig_p2_error;    
wire       mig_p3_error;    
wire       mig_p4_error;    
wire       mig_p5_error;    


wire  [6:0]mig_p0_wr_count;
wire  [6:0]mig_p1_wr_count;
wire  [6:0]mig_p0_rd_count;
wire  [6:0]mig_p1_rd_count;

wire  [6:0]mig_p2_count;
wire  [6:0]mig_p3_count;
wire  [6:0]mig_p4_count;
wire  [6:0]mig_p5_count;

wire  mig_p0_wr_full;
wire  mig_p1_wr_full;

wire mig_p0_rd_empty;
wire mig_p1_rd_empty;
wire mig_p0_wr_empty;
wire mig_p1_wr_empty;
wire mig_p0_rd_full;
wire mig_p1_rd_full;
wire mig_p2_full;
wire mig_p3_full;
wire mig_p4_full;
wire mig_p5_full;
wire mig_p2_empty;
wire mig_p3_empty;
wire mig_p4_empty;
wire mig_p5_empty;

// SELFREESH control signal for suspend feature
wire selfrefresh_mcb_enter;
wire selfrefresh_mcb_mode ;
// Testing Interface signals
wire           tst_cmd_test_en;
wire   [7:0]   tst_sel;
wire   [15:0]  tst_in;
wire           tst_scan_clk;
wire           tst_scan_rst;
wire           tst_scan_set;
wire           tst_scan_en;
wire           tst_scan_in;
wire           tst_scan_mode;

wire           p0w_tst_en;
wire           p0r_tst_en;
wire           p1w_tst_en;
wire           p1r_tst_en;
wire           p2_tst_en;
wire           p3_tst_en;
wire           p4_tst_en;
wire           p5_tst_en;

wire           p0_tst_wr_clk_en;
wire           p0_tst_rd_clk_en;
wire           p1_tst_wr_clk_en;
wire           p1_tst_rd_clk_en;
wire           p2_tst_clk_en;
wire           p3_tst_clk_en;
wire           p4_tst_clk_en;
wire           p5_tst_clk_en;

wire   [3:0]   p0w_tst_wr_mode;
wire   [3:0]   p0r_tst_mode;
wire   [3:0]   p1w_tst_wr_mode;
wire   [3:0]   p1r_tst_mode;
wire   [3:0]   p2_tst_mode;
wire   [3:0]   p3_tst_mode;
wire   [3:0]   p4_tst_mode;
wire   [3:0]   p5_tst_mode;

wire           p0r_tst_pin_en;
wire           p0w_tst_pin_en;
wire           p1r_tst_pin_en;
wire           p1w_tst_pin_en;
wire           p2_tst_pin_en;
wire           p3_tst_pin_en;
wire           p4_tst_pin_en;
wire           p5_tst_pin_en;
wire           p0w_tst_overflow;
wire           p1w_tst_overflow;

wire  [3:0]   p0r_tst_mask_o;
wire  [3:0]   p0w_tst_mask_o;
wire  [3:0]   p1r_tst_mask_o;
wire  [3:0]   p1w_tst_mask_o;
wire  [3:0]   p2_tst_mask_o;
wire  [3:0]   p3_tst_mask_o;
wire  [3:0]   p4_tst_mask_o;
wire  [3:0]   p5_tst_mask_o;
wire  [3:0]   p0r_tst_wr_mask;

wire  [3:0]   p1r_tst_wr_mask;
wire [31:0]  p1r_tst_wr_data;
wire [31:0]  p0r_tst_wr_data;
wire [31:0]   p0w_tst_rd_data;
wire [31:0]   p1w_tst_rd_data;

wire  [38:0]  tst_cmd_out;
wire           MCB_SYSRST;
wire ioclk0;
wire ioclk90;
wire mcb_ui_clk;                               
wire hard_done_cal;                                
wire cke_train;
//testing
wire       ioi_drp_update;
wire [7:0] aux_sdi_sdo;

wire [4:0] mcb_ui_addr;
wire [3:0] mcb_ui_dqcount;
reg  syn_uiclk_pll_lock;
reg syn1_sys_rst, syn2_sys_rst;

wire int_sys_rst /* synthesis syn_maxfan = 1 */;
// synthesis attribute max_fanout of int_sys_rst is 1

reg selfrefresh_enter_r1,selfrefresh_enter_r2,selfrefresh_enter_r3;
reg gated_pll_lock;	   
reg soft_cal_selfrefresh_req;
reg [15:0]    wait_200us_counter;
reg           cke_train_reg;        
reg           wait_200us_done_r1,wait_200us_done_r2;
reg normal_operation_window;

assign ioclk0 = sysclk_2x;
assign ioclk90 = sysclk_2x_180;



// logic to determine if Memory  is SELFREFRESH mode operation or NORMAL  mode.
always @ (posedge ui_clk)
begin 
if (sys_rst)   
   normal_operation_window <= 1'b1;
else if (selfrefresh_enter_r2 || selfrefresh_mode)
   normal_operation_window <= 1'b0;
else if (~selfrefresh_enter_r2 && ~selfrefresh_mode)
   normal_operation_window <= 1'b1;
else
   normal_operation_window <= normal_operation_window;

end   


always @ (*)
begin
if (normal_operation_window)
   gated_pll_lock = pll_lock;
else
   gated_pll_lock = syn_uiclk_pll_lock;
end


//assign int_sys_rst =  sys_rst | ~gated_pll_lock;
always @ (posedge ui_clk)
begin 
  if (~selfrefresh_enter && ~selfrefresh_mode)
   syn_uiclk_pll_lock <= pll_lock;
   
end   

// int_sys_rst will be asserted if pll lose lock during normal operation.
// It uses the syn_uiclk_pll_lock version when it is entering suspend window , hence
// reset will not be generated.   
assign int_sys_rst =  sys_rst | ~gated_pll_lock;



// synchronize the selfrefresh_enter 
always @ (posedge ui_clk)
if (sys_rst)
   begin
      selfrefresh_enter_r1 <= 1'b0;
      selfrefresh_enter_r2 <= 1'b0;
      selfrefresh_enter_r3 <= 1'b0;
   end
else
   begin
      selfrefresh_enter_r1 <= selfrefresh_enter;
      selfrefresh_enter_r2 <= selfrefresh_enter_r1;
      selfrefresh_enter_r3 <= selfrefresh_enter_r2;
   end



// The soft_cal_selfrefresh siganl is conditioned before connect to mcb_soft_calibration module.
// It will not deassert selfrefresh_mcb_enter to MCB until input pll_lock reestablished in system.
// This is to ensure the IOI stables before issued a selfrefresh exit command to dram.
always @ (posedge ui_clk)
begin 
  if (sys_rst)
   soft_cal_selfrefresh_req <= 1'b0;
  else if (selfrefresh_enter_r3)
     soft_cal_selfrefresh_req <= 1'b1;
  else if (~selfrefresh_enter_r3 && pll_lock)
     soft_cal_selfrefresh_req <= 1'b0;
  else
     soft_cal_selfrefresh_req <= soft_cal_selfrefresh_req;
  
end   


//Address Remapping
// Byte Address remapping
// 
// Bank Address[x:0] & Row Address[x:0]  & Column Address[x:0]
// column address remap for port 0
 generate //  port bus remapping sections for CONFIG 2   15,3,12

if(C_NUM_DQ_PINS == 16) begin : x16_Addr
           if (C_MEM_ADDR_ORDER == "ROW_BANK_COLUMN") begin  // C_MEM_ADDR_ORDER = 0 : Bank Row  Column
                 // port 0 address remapping
                
                
                if (C_MEM_ADDR_WIDTH == 15)   //Row        
                       assign p0_cmd_ra = p0_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS + 1];                         
                else
                       assign p0_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] ,  p0_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS   :C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS + 1]};                         


                if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                       assign p0_cmd_ba = p0_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS   :  C_MEM_NUM_COL_BITS + 1];
                else
                       assign p0_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH] , p0_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +   C_MEM_NUM_COL_BITS   :  C_MEM_NUM_COL_BITS + 1]};
                
                if (C_MEM_NUM_COL_BITS == 12)  //Column
                       assign p0_cmd_ca = p0_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1];
                else
                       assign p0_cmd_ca = {allzero[12:C_MEM_NUM_COL_BITS + 1], p0_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1]};

                
                 // port 1 address remapping
                
                
                if (C_MEM_ADDR_WIDTH == 15)   //Row        
                       assign p1_cmd_ra = p1_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS + 1];                         
                else
                       assign p1_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] ,  p1_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS   :C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS + 1]};                         


                if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                       assign p1_cmd_ba = p1_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS   :  C_MEM_NUM_COL_BITS + 1];
                else
                       assign p1_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH] , p1_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +   C_MEM_NUM_COL_BITS   :  C_MEM_NUM_COL_BITS + 1]};
                
                if (C_MEM_NUM_COL_BITS == 12)  //Column
                       assign p1_cmd_ca = p1_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1];
                else
                       assign p1_cmd_ca = {allzero[12:C_MEM_NUM_COL_BITS  + 1], p1_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1]};

                 // port 2 address remapping
                
                
                if (C_MEM_ADDR_WIDTH == 15)   //Row        
                       assign p2_cmd_ra = p2_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS + 1];                         
                else
                       assign p2_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] ,  p2_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS   :C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS + 1]};                         


                if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                       assign p2_cmd_ba = p2_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS   :  C_MEM_NUM_COL_BITS + 1];
                else
                       assign p2_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH] , p2_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +   C_MEM_NUM_COL_BITS   :  C_MEM_NUM_COL_BITS + 1]};
                
                if (C_MEM_NUM_COL_BITS == 12)  //Column
                       assign p2_cmd_ca = p2_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1];
                else
                       assign p2_cmd_ca = {allzero[12:C_MEM_NUM_COL_BITS + 1], p2_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1]};

                 // port 3 address remapping
                
                
                if (C_MEM_ADDR_WIDTH == 15)   //Row        
                       assign p3_cmd_ra = p3_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS + 1];                         
                else
                       assign p3_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] ,  p3_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS   :C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS + 1]};                         


                if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                       assign p3_cmd_ba = p3_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS   :  C_MEM_NUM_COL_BITS + 1];
                else
                       assign p3_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH] , p3_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +   C_MEM_NUM_COL_BITS   :  C_MEM_NUM_COL_BITS + 1]};
                
                if (C_MEM_NUM_COL_BITS == 12)  //Column
                       assign p3_cmd_ca = p3_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1];
                else
                       assign p3_cmd_ca = {allzero[12:C_MEM_NUM_COL_BITS + 1], p3_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1]};

                 // port 4 address remapping
                
                
                if (C_MEM_ADDR_WIDTH == 15)   //Row        
                       assign p4_cmd_ra = p4_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS + 1];                         
                else
                       assign p4_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] ,  p4_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS   :C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS + 1]};                         


                if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                       assign p4_cmd_ba = p4_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS   :  C_MEM_NUM_COL_BITS + 1];
                else
                       assign p4_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH] , p4_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +   C_MEM_NUM_COL_BITS   :  C_MEM_NUM_COL_BITS + 1]};
                
                if (C_MEM_NUM_COL_BITS == 12)  //Column
                       assign p4_cmd_ca = p4_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1];
                else
                       assign p4_cmd_ca = {allzero[12:C_MEM_NUM_COL_BITS + 1], p4_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1]};

                 // port 5 address remapping
                
                
                if (C_MEM_ADDR_WIDTH == 15)   //Row        
                       assign p5_cmd_ra = p5_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS + 1];                         
                else
                       assign p5_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] ,  p5_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS   :C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS + 1]};                         


                if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                       assign p5_cmd_ba = p5_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS   :  C_MEM_NUM_COL_BITS + 1];
                else
                       assign p5_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH] , p5_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +   C_MEM_NUM_COL_BITS   :  C_MEM_NUM_COL_BITS + 1]};
                
                if (C_MEM_NUM_COL_BITS == 12)  //Column
                       assign p5_cmd_ca = p5_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1];
                else
                       assign p5_cmd_ca = {allzero[12:C_MEM_NUM_COL_BITS + 1], p5_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1]};


                
                
                end
                
          else  // ***************C_MEM_ADDR_ORDER = 1 :  Row Bank Column
              begin
                 // port 0 address remapping

                if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                       assign p0_cmd_ba = p0_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS  : C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS + 1];
                else
                       assign p0_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH] , p0_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS  : C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS + 1]};
                
                
                if (C_MEM_ADDR_WIDTH == 15)           
                       assign p0_cmd_ra = p0_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_NUM_COL_BITS + 1];                         
                else
                       assign p0_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] ,  p0_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_NUM_COL_BITS + 1]};                         
                
                if (C_MEM_NUM_COL_BITS == 12)  //Column
                       assign p0_cmd_ca = p0_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1];
                else
                       assign p0_cmd_ca = {allzero[12:C_MEM_NUM_COL_BITS + 1], p0_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1]};


                 // port 1 address remapping

                if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                       assign p1_cmd_ba = p1_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS  : C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS + 1];
                else
                       assign p1_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH] , p1_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS  : C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS + 1]};
                
                
                if (C_MEM_ADDR_WIDTH == 15)           
                       assign p1_cmd_ra = p1_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_NUM_COL_BITS + 1];                         
                else
                       assign p1_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] ,  p1_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_NUM_COL_BITS + 1]};                         
                
                if (C_MEM_NUM_COL_BITS == 12)  //Column
                       assign p1_cmd_ca = p1_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1];
                else
                       assign p1_cmd_ca = {allzero[12:C_MEM_NUM_COL_BITS + 1], p1_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1]};

                 // port 2 address remapping

                if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                       assign p2_cmd_ba = p2_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS  : C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS + 1];
                else
                       assign p2_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH] , p2_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS  : C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS + 1]};
                
                
                if (C_MEM_ADDR_WIDTH == 15)           
                       assign p2_cmd_ra = p2_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_NUM_COL_BITS + 1];                         
                else
                       assign p2_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] ,  p2_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_NUM_COL_BITS + 1]};                         
                
                if (C_MEM_NUM_COL_BITS == 12)  //Column
                       assign p2_cmd_ca = p2_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1];
                else
                       assign p2_cmd_ca = {allzero[12:C_MEM_NUM_COL_BITS + 1], p2_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1]};

                 // port 3 address remapping

                if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                       assign p3_cmd_ba = p3_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS  : C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS + 1];
                else
                       assign p3_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH] , p3_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS  : C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS + 1]};
                
                
                if (C_MEM_ADDR_WIDTH == 15)           
                       assign p3_cmd_ra = p3_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_NUM_COL_BITS + 1];                         
                else
                       assign p3_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] ,  p3_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_NUM_COL_BITS + 1]};                         
                
                if (C_MEM_NUM_COL_BITS == 12)  //Column
                       assign p3_cmd_ca = p3_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1];
                else
                       assign p3_cmd_ca = {allzero[12:C_MEM_NUM_COL_BITS + 1], p3_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1]};

                 // port 4 address remapping

                if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                       assign p4_cmd_ba = p4_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS  : C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS + 1];
                else
                       assign p4_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH] , p4_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS  : C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS + 1]};
                
                
                if (C_MEM_ADDR_WIDTH == 15)           
                       assign p4_cmd_ra = p4_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_NUM_COL_BITS + 1];                         
                else
                       assign p4_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] ,  p4_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_NUM_COL_BITS + 1]};                         
                
                if (C_MEM_NUM_COL_BITS == 12)  //Column
                       assign p4_cmd_ca = p4_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1];
                else
                       assign p4_cmd_ca = {allzero[12:C_MEM_NUM_COL_BITS + 1], p4_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1]};

                 // port 5 address remapping

                if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                       assign p5_cmd_ba = p5_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS  : C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS + 1];
                else
                       assign p5_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH] , p5_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS  : C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS + 1]};
                
                
                if (C_MEM_ADDR_WIDTH == 15)           
                       assign p5_cmd_ra = p5_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_NUM_COL_BITS + 1];                         
                else
                       assign p5_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] ,  p5_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_NUM_COL_BITS   : C_MEM_NUM_COL_BITS + 1]};                         
                
                if (C_MEM_NUM_COL_BITS == 12)  //Column
                       assign p5_cmd_ca = p5_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1];
                else
                       assign p5_cmd_ca = {allzero[12:C_MEM_NUM_COL_BITS + 1], p5_cmd_byte_addr[C_MEM_NUM_COL_BITS : 1]};

         
              end
       
end else if(C_NUM_DQ_PINS == 8) begin : x8_Addr
           if (C_MEM_ADDR_ORDER == "ROW_BANK_COLUMN") begin  // C_MEM_ADDR_ORDER = 1 : Bank Row Column
                 // port 0 address remapping

                 if (C_MEM_ADDR_WIDTH == 15)  //Row
                          assign p0_cmd_ra = p0_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1  : C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS ];
                 else
                          assign p0_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] , p0_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1  : C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS ]};


                 if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                          assign p0_cmd_ba = p0_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 :  C_MEM_NUM_COL_BITS ];  //14,3,10
                 else
                          assign p0_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH],  
                                   p0_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_NUM_COL_BITS ]};  //14,3,10
                 
                 
                 if (C_MEM_NUM_COL_BITS == 12)  //Column
                          assign p0_cmd_ca[11:0] = p0_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0];
                 else
                          assign p0_cmd_ca[11:0] = {allzero[11 : C_MEM_NUM_COL_BITS] , p0_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0]};
                 
                 
                // port 1 address remapping
                 if (C_MEM_ADDR_WIDTH == 15)  //Row
                          assign p1_cmd_ra = p1_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1  : C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS ];
                 else
                          assign p1_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] , p1_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1  : C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS ]};


                 if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                          assign p1_cmd_ba = p1_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 :  C_MEM_NUM_COL_BITS ];  //14,3,10
                 else
                          assign p1_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH],  
                                   p1_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_NUM_COL_BITS ]};  //14,3,10
                 
                 
                 if (C_MEM_NUM_COL_BITS == 12)  //Column
                          assign p1_cmd_ca[11:0] = p1_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0];
                 else
                          assign p1_cmd_ca[11:0] = {allzero[11 : C_MEM_NUM_COL_BITS] , p1_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0]};
                 
                
                // port 2 address remapping
                 if (C_MEM_ADDR_WIDTH == 15)  //Row
                          assign p2_cmd_ra = p2_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1  : C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS ];
                 else
                          assign p2_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] , p2_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1  : C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS ]};


                 if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                          assign p2_cmd_ba = p2_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 :  C_MEM_NUM_COL_BITS ];  //14,3,10
                 else
                          assign p2_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH],  
                                   p2_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_NUM_COL_BITS ]};  //14,2,10  ***
                 
                 
                 if (C_MEM_NUM_COL_BITS == 12)  //Column
                          assign p2_cmd_ca[11:0] = p2_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0];
                 else
                          assign p2_cmd_ca[11:0] = {allzero[11 : C_MEM_NUM_COL_BITS] , p2_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0]};
                 


              //   port 3 address remapping
                 if (C_MEM_ADDR_WIDTH == 15)  //Row
                          assign p3_cmd_ra = p3_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1  : C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS ];
                 else
                          assign p3_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] , p3_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1  : C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS ]};


                 if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                          assign p3_cmd_ba = p3_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 :  C_MEM_NUM_COL_BITS ];  //14,3,10
                 else
                          assign p3_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH],  
                                   p3_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_NUM_COL_BITS ]};  //14,3,10
                 
                 
                 if (C_MEM_NUM_COL_BITS == 12)  //Column
                          assign p3_cmd_ca[11:0] = p3_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0];
                 else
                          assign p3_cmd_ca[11:0] = {allzero[11 : C_MEM_NUM_COL_BITS] , p3_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0]};
                 
                
              //   port 4 address remapping
                 if (C_MEM_ADDR_WIDTH == 15)  //Row
                          assign p4_cmd_ra = p4_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1  : C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS ];
                 else
                          assign p4_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] , p4_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1  : C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS ]};


                 if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                          assign p4_cmd_ba = p4_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 :  C_MEM_NUM_COL_BITS ];  //14,3,10
                 else
                          assign p4_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH],  
                                   p4_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_NUM_COL_BITS ]};  //14,3,10
                 
                 
                 if (C_MEM_NUM_COL_BITS == 12)  //Column
                          assign p4_cmd_ca[11:0] = p4_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0];
                 else
                          assign p4_cmd_ca[11:0] = {allzero[11 : C_MEM_NUM_COL_BITS] , p4_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0]};
                 

              //   port 5 address remapping
              
                 if (C_MEM_ADDR_WIDTH == 15)  //Row
                          assign p5_cmd_ra = p5_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1  : C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS ];
                 else
                          assign p5_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] , p5_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1  : C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS ]};


                 if (C_MEM_BANKADDR_WIDTH  == 3 )  //Bank
                          assign p5_cmd_ba = p5_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 :  C_MEM_NUM_COL_BITS ];  //14,3,10
                 else
                          assign p5_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH],  
                                   p5_cmd_byte_addr[C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_NUM_COL_BITS ]};  //14,3,10
                 
                 
                 if (C_MEM_NUM_COL_BITS == 12)  //Column
                          assign p5_cmd_ca[11:0] = p5_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0];
                 else
                          assign p5_cmd_ca[11:0] = {allzero[11 : C_MEM_NUM_COL_BITS] , p5_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0]};
                 
                end
               
            else  //  x8 ***************C_MEM_ADDR_ORDER = 0 : Bank Row Column
              begin
                 // port 0 address remapping
                 if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                          assign p0_cmd_ba = p0_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS ];  
                 else
                          assign p0_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH],  
                                   p0_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS ]};  


                 if (C_MEM_ADDR_WIDTH == 15) //Row
                          assign p0_cmd_ra = p0_cmd_byte_addr[C_MEM_ADDR_WIDTH  + C_MEM_NUM_COL_BITS - 1  :  C_MEM_NUM_COL_BITS ];
                 else
                          assign p0_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] , p0_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS - 1  : C_MEM_NUM_COL_BITS ]};                
                                   
                 
                 if (C_MEM_NUM_COL_BITS == 12) //Column
                          assign p0_cmd_ca[11:0] = p0_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0];
                 else
                          assign p0_cmd_ca[11:0] = {allzero[11 : C_MEM_NUM_COL_BITS] , p0_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0]};


                // port 1 address remapping
                 if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                          assign p1_cmd_ba = p1_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS ];  
                 else
                          assign p1_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH],  
                                   p1_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS ]};  
                                   
                 if (C_MEM_ADDR_WIDTH == 15) //Row
                          assign p1_cmd_ra = p1_cmd_byte_addr[C_MEM_ADDR_WIDTH  + C_MEM_NUM_COL_BITS - 1  :  C_MEM_NUM_COL_BITS ];
                 else
                          assign p1_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] , p1_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS - 1  : C_MEM_NUM_COL_BITS ]};
                 
                 if (C_MEM_NUM_COL_BITS == 12) //Column
                          assign p1_cmd_ca[11:0] = p1_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0];
                 else
                          assign p1_cmd_ca[11:0] = {allzero[11 : C_MEM_NUM_COL_BITS] , p1_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0]};
                
               //port 2 address remapping
                if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank    2,13,10    24,23
                       assign p2_cmd_ba = p2_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS ];  
                else
                       assign p2_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH],  
                                        p2_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS  ]};  
      
                 if (C_MEM_ADDR_WIDTH == 15) //Row
                          assign p2_cmd_ra = p2_cmd_byte_addr[C_MEM_ADDR_WIDTH  + C_MEM_NUM_COL_BITS - 1  :  C_MEM_NUM_COL_BITS ];
                 else
                          assign p2_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] , p2_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS - 1  : C_MEM_NUM_COL_BITS ]};
                 
                 if (C_MEM_NUM_COL_BITS == 12) //Column
                          assign p2_cmd_ca[11:0] = p2_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0];
                 else
                          assign p2_cmd_ca[11:0] = {allzero[11 : C_MEM_NUM_COL_BITS] , p2_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0]};

              // port 3 address remapping
                 if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                          assign p3_cmd_ba = p3_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS ];  
                 else
                          assign p3_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH],  
                                   p3_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS ]};  
                                   
                 if (C_MEM_ADDR_WIDTH == 15) //Row
                          assign p3_cmd_ra = p3_cmd_byte_addr[C_MEM_ADDR_WIDTH  + C_MEM_NUM_COL_BITS - 1  :  C_MEM_NUM_COL_BITS ];
                 else
                          assign p3_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] , p3_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS - 1  : C_MEM_NUM_COL_BITS ]};
                 
                 if (C_MEM_NUM_COL_BITS == 12) //Column
                          assign p3_cmd_ca[11:0] = p3_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0];
                 else
                          assign p3_cmd_ca[11:0] = {allzero[11 : C_MEM_NUM_COL_BITS] , p3_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0]};
   
   
                 //   port 4 address remapping
                 if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                          assign p4_cmd_ba = p4_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS ];  
                 else
                          assign p4_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH],  
                                   p4_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS ]};  
                                   
                 if (C_MEM_ADDR_WIDTH == 15) //Row
                          assign p4_cmd_ra = p4_cmd_byte_addr[C_MEM_ADDR_WIDTH  + C_MEM_NUM_COL_BITS - 1  :  C_MEM_NUM_COL_BITS ];
                 else
                          assign p4_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] , p4_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS - 1  : C_MEM_NUM_COL_BITS ]};
                 
                 if (C_MEM_NUM_COL_BITS == 12) //Column
                          assign p4_cmd_ca[11:0] = p4_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0];
                 else
                          assign p4_cmd_ca[11:0] = {allzero[11 : C_MEM_NUM_COL_BITS] , p4_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0]};

                 //   port 5 address remapping
   
                 if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                          assign p5_cmd_ba = p5_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS ];  
                 else
                          assign p5_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH],  
                                   p5_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1 : C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS ]};  
                                   
                 if (C_MEM_ADDR_WIDTH == 15) //Row
                          assign p5_cmd_ra = p5_cmd_byte_addr[C_MEM_ADDR_WIDTH  + C_MEM_NUM_COL_BITS - 1  :  C_MEM_NUM_COL_BITS ];
                 else
                          assign p5_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH] , p5_cmd_byte_addr[C_MEM_ADDR_WIDTH  +  C_MEM_NUM_COL_BITS - 1  : C_MEM_NUM_COL_BITS ]};
                 
                 if (C_MEM_NUM_COL_BITS == 12) //Column
                          assign p5_cmd_ca[11:0] = p5_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0];
                 else
                          assign p5_cmd_ca[11:0] = {allzero[11 : C_MEM_NUM_COL_BITS] , p5_cmd_byte_addr[C_MEM_NUM_COL_BITS - 1 : 0]};
             
            end

              //

end else if(C_NUM_DQ_PINS == 4) begin : x4_Addr

           if (C_MEM_ADDR_ORDER == "ROW_BANK_COLUMN") begin  // C_MEM_ADDR_ORDER = 1 :  Row Bank Column

               //   port 0 address remapping
               
               
               if (C_MEM_ADDR_WIDTH == 15) //Row
                     assign p0_cmd_ra = p0_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 1];
               else         
                     assign p0_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH ] , p0_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 1]};
                        

               if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                      assign p0_cmd_ba =  p0_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 :  C_MEM_NUM_COL_BITS - 1];
               else
                      assign p0_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH ] , p0_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 :  C_MEM_NUM_COL_BITS - 1]};

                        
               if (C_MEM_NUM_COL_BITS == 12) //Column
                     assign p0_cmd_ca = {p0_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};                                //14,3,11
               else
                     assign p0_cmd_ca = {allzero[11 : C_MEM_NUM_COL_BITS ] ,  p0_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};

           
              //   port 1 address remapping
               if (C_MEM_ADDR_WIDTH == 15) //Row
                     assign p1_cmd_ra = p1_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 1];
               else         
                     assign p1_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH ] , p1_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 1]};
                        

               if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                      assign p1_cmd_ba =  p1_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 :  C_MEM_NUM_COL_BITS - 1];
               else
                      assign p1_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH ] , p1_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 :  C_MEM_NUM_COL_BITS - 1]};

                        
               if (C_MEM_NUM_COL_BITS == 12) //Column
                     assign p1_cmd_ca = {p1_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};                                //14,3,11
               else
                     assign p1_cmd_ca = {allzero[11 : C_MEM_NUM_COL_BITS ] ,  p1_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};

               //   port 2 address remapping
               if (C_MEM_ADDR_WIDTH == 15) //Row
                     assign p2_cmd_ra = p2_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 1];
               else         
                     assign p2_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH ] , p2_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 1]};
                        

               if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                      assign p2_cmd_ba =  p2_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 :  C_MEM_NUM_COL_BITS - 1];
               else
                      assign p2_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH ] , p2_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 :  C_MEM_NUM_COL_BITS - 1]};

                        
               if (C_MEM_NUM_COL_BITS == 12) //Column
                     assign p2_cmd_ca = {p2_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};                                //14,3,11
               else
                     assign p2_cmd_ca = {allzero[11 : C_MEM_NUM_COL_BITS ] ,  p2_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};

              //   port 3 address remapping

               if (C_MEM_ADDR_WIDTH == 15) //Row
                     assign p3_cmd_ra = p3_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 1];
               else         
                     assign p3_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH ] , p3_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 1]};
                        

               if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                      assign p3_cmd_ba =  p3_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 :  C_MEM_NUM_COL_BITS - 1];
               else
                      assign p3_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH ] , p3_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 :  C_MEM_NUM_COL_BITS - 1]};

                        
               if (C_MEM_NUM_COL_BITS == 12) //Column
                     assign p3_cmd_ca = {p3_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};                                //14,3,11
               else
                     assign p3_cmd_ca = {allzero[11 : C_MEM_NUM_COL_BITS ] ,  p3_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};

 

          if(C_PORT_CONFIG == "B32_B32_R32_R32_R32_R32" ||
             C_PORT_CONFIG == "B32_B32_R32_R32_R32_W32" ||
             C_PORT_CONFIG == "B32_B32_R32_R32_W32_R32" ||
             C_PORT_CONFIG == "B32_B32_R32_R32_W32_W32" ||
             C_PORT_CONFIG == "B32_B32_R32_W32_R32_R32" ||
             C_PORT_CONFIG == "B32_B32_R32_W32_R32_W32" ||
             C_PORT_CONFIG == "B32_B32_R32_W32_W32_R32" ||
             C_PORT_CONFIG == "B32_B32_R32_W32_W32_W32" ||
             C_PORT_CONFIG == "B32_B32_W32_R32_R32_R32" ||
             C_PORT_CONFIG == "B32_B32_W32_R32_R32_W32" ||
             C_PORT_CONFIG == "B32_B32_W32_R32_W32_R32" ||
             C_PORT_CONFIG == "B32_B32_W32_R32_W32_W32" ||
             C_PORT_CONFIG == "B32_B32_W32_W32_R32_R32" ||
             C_PORT_CONFIG == "B32_B32_W32_W32_R32_W32" ||
             C_PORT_CONFIG == "B32_B32_W32_W32_W32_R32" ||
             C_PORT_CONFIG == "B32_B32_W32_W32_W32_W32"
             ) //begin : x4_Addr_CFG1_OR_CFG2
               begin
               if (C_MEM_ADDR_WIDTH == 15) //Row
                     assign p4_cmd_ra = p4_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 1];
               else         
                     assign p4_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH ] , p4_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 1]};
                        

               if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                      assign p4_cmd_ba =  p4_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 :  C_MEM_NUM_COL_BITS - 1];
               else
                      assign p4_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH ] , p4_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 :  C_MEM_NUM_COL_BITS - 1]};

                        
               if (C_MEM_NUM_COL_BITS == 12) //Column
                     assign p4_cmd_ca = {p4_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};                                //14,3,11
               else
                     assign p4_cmd_ca = {allzero[11 : C_MEM_NUM_COL_BITS ] ,  p4_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};



               if (C_MEM_ADDR_WIDTH == 15) //Row
                     assign p5_cmd_ra = p5_cmd_byte_addr[C_MEM_ADDR_WIDTH + C_MEM_BANKADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 1];
               else         
                     assign p5_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH ] , p5_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 : C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 1]};
                        

               if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                      assign p5_cmd_ba =  p5_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 :  C_MEM_NUM_COL_BITS - 1];
               else
                      assign p5_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH ] , p5_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_NUM_COL_BITS - 2 :  C_MEM_NUM_COL_BITS - 1]};

                        
               if (C_MEM_NUM_COL_BITS == 12) //Column
                     assign p5_cmd_ca = {p5_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};                                //14,3,11
               else
                     assign p5_cmd_ca = {allzero[11 : C_MEM_NUM_COL_BITS ] ,  p5_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};

              end
              
              
           end
         else   // C_MEM_ADDR_ORDER = 1 :  Row Bank Column
            begin
            
               //   port 0 address remapping
               if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                      assign p0_cmd_ba =  p0_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1];
               else
                      assign p0_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH ] , p0_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1]};
               
               
               if (C_MEM_ADDR_WIDTH == 15) //Row
                     assign p0_cmd_ra = p0_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_NUM_COL_BITS - 1];
               else         
                     assign p0_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH ] , p0_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_NUM_COL_BITS - 1]};
                        
                        
               if (C_MEM_NUM_COL_BITS == 12) //Column
                     assign p0_cmd_ca = {p0_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};
               else
                     assign p0_cmd_ca = {allzero[11 : C_MEM_NUM_COL_BITS ] ,  p0_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};
               
           
              //   port 1 address remapping
               if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                      assign p1_cmd_ba =  p1_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1];
               else
                      assign p1_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH ] , p1_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1]};
               
               
               if (C_MEM_ADDR_WIDTH == 15) //Row
                     assign p1_cmd_ra = p1_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_NUM_COL_BITS - 1];
               else         
                     assign p1_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH ] , p1_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_NUM_COL_BITS - 1]};
                        
                        
               if (C_MEM_NUM_COL_BITS == 12) //Column
                     assign p1_cmd_ca = {p1_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};
               else
                     assign p1_cmd_ca = {allzero[11 : C_MEM_NUM_COL_BITS ] ,  p1_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};
               //   port 2 address remapping
               if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                      assign p2_cmd_ba =  p2_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1];
               else
                      assign p2_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH ] , p2_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1]};
               
             //***  
               if (C_MEM_ADDR_WIDTH == 15) //Row
                     assign p2_cmd_ra = p2_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_NUM_COL_BITS - 1];
               else         
                     assign p2_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH ] , p2_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_NUM_COL_BITS - 1]};
                        
                        
               if (C_MEM_NUM_COL_BITS == 12) //Column
                     assign p2_cmd_ca = {p2_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};
               else
                     assign p2_cmd_ca = {allzero[11 : C_MEM_NUM_COL_BITS ] ,  p2_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};
              //   port 3 address remapping

               if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                      assign p3_cmd_ba =  p3_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1];
               else
                      assign p3_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH ] , p3_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1]};
               
               
               if (C_MEM_ADDR_WIDTH == 15) //Row
                     assign p3_cmd_ra = p3_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_NUM_COL_BITS - 1];
               else         
                     assign p3_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH ] , p3_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_NUM_COL_BITS - 1]};
                        
                        
               if (C_MEM_NUM_COL_BITS == 12) //Column
                     assign p3_cmd_ca = {p3_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};
               else
                     assign p3_cmd_ca = {allzero[11 : C_MEM_NUM_COL_BITS ] ,  p3_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};
 

          if(C_PORT_CONFIG == "B32_B32_R32_R32_R32_R32" ||
             C_PORT_CONFIG == "B32_B32_R32_R32_R32_W32" ||
             C_PORT_CONFIG == "B32_B32_R32_R32_W32_R32" ||
             C_PORT_CONFIG == "B32_B32_R32_R32_W32_W32" ||
             C_PORT_CONFIG == "B32_B32_R32_W32_R32_R32" ||
             C_PORT_CONFIG == "B32_B32_R32_W32_R32_W32" ||
             C_PORT_CONFIG == "B32_B32_R32_W32_W32_R32" ||
             C_PORT_CONFIG == "B32_B32_R32_W32_W32_W32" ||
             C_PORT_CONFIG == "B32_B32_W32_R32_R32_R32" ||
             C_PORT_CONFIG == "B32_B32_W32_R32_R32_W32" ||
             C_PORT_CONFIG == "B32_B32_W32_R32_W32_R32" ||
             C_PORT_CONFIG == "B32_B32_W32_R32_W32_W32" ||
             C_PORT_CONFIG == "B32_B32_W32_W32_R32_R32" ||
             C_PORT_CONFIG == "B32_B32_W32_W32_R32_W32" ||
             C_PORT_CONFIG == "B32_B32_W32_W32_W32_R32" ||
             C_PORT_CONFIG == "B32_B32_W32_W32_W32_W32"
             ) //begin : x4_Addr_CFG1_OR_CFG2
               begin
               if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                      assign p4_cmd_ba =  p4_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1];
               else
                      assign p4_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH ] , p4_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1]};
               
               
               if (C_MEM_ADDR_WIDTH == 15) //Row
                     assign p4_cmd_ra = p4_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_NUM_COL_BITS - 1];
               else         
                     assign p4_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH ] , p4_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_NUM_COL_BITS - 1]};
                        
                        
               if (C_MEM_NUM_COL_BITS == 12) //Column
                     assign p4_cmd_ca = {p4_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};
               else
                     assign p4_cmd_ca = {allzero[11 : C_MEM_NUM_COL_BITS ] ,  p4_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};


               if (C_MEM_BANKADDR_WIDTH  == 3 ) //Bank
                      assign p5_cmd_ba =  p5_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1];
               else
                      assign p5_cmd_ba = {allzero[2 : C_MEM_BANKADDR_WIDTH ] , p5_cmd_byte_addr[C_MEM_BANKADDR_WIDTH + C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 1]};
               
               
               if (C_MEM_ADDR_WIDTH == 15) //Row
                     assign p5_cmd_ra = p5_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_NUM_COL_BITS - 1];
               else         
                     assign p5_cmd_ra = {allzero[14 : C_MEM_ADDR_WIDTH ] , p5_cmd_byte_addr[C_MEM_ADDR_WIDTH +  C_MEM_NUM_COL_BITS - 2 : C_MEM_NUM_COL_BITS - 1]};
                        
                        
               if (C_MEM_NUM_COL_BITS == 12) //Column
                     assign p5_cmd_ca = {p5_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};
               else
                     assign p5_cmd_ca = {allzero[11 : C_MEM_NUM_COL_BITS ] ,  p5_cmd_byte_addr[C_MEM_NUM_COL_BITS - 2 : 0] , 1'b0};
              end
            
            
            
            end
           
end // block: x4_Addr


endgenerate



generate 
   //   if(C_PORT_CONFIG[183:160] == "B32") begin : u_config1_0
   if(C_PORT_CONFIG == "B32_B32_R32_R32_R32_R32" ||
      C_PORT_CONFIG == "B32_B32_R32_R32_R32_W32" ||
      C_PORT_CONFIG == "B32_B32_R32_R32_W32_R32" ||
      C_PORT_CONFIG == "B32_B32_R32_R32_W32_W32" ||
      C_PORT_CONFIG == "B32_B32_R32_W32_R32_R32" ||
      C_PORT_CONFIG == "B32_B32_R32_W32_R32_W32" ||
      C_PORT_CONFIG == "B32_B32_R32_W32_W32_R32" ||
      C_PORT_CONFIG == "B32_B32_R32_W32_W32_W32" ||
      C_PORT_CONFIG == "B32_B32_W32_R32_R32_R32" ||
      C_PORT_CONFIG == "B32_B32_W32_R32_R32_W32" ||
      C_PORT_CONFIG == "B32_B32_W32_R32_W32_R32" ||
      C_PORT_CONFIG == "B32_B32_W32_R32_W32_W32" ||
      C_PORT_CONFIG == "B32_B32_W32_W32_R32_R32" ||
      C_PORT_CONFIG == "B32_B32_W32_W32_R32_W32" ||
      C_PORT_CONFIG == "B32_B32_W32_W32_W32_R32" ||
      C_PORT_CONFIG == "B32_B32_W32_W32_W32_W32"
      ) begin : u_config1_0      

  //synthesis translate_off 
  always @(*)
  begin
    if ( C_PORT_CONFIG[119:96]  == "W32" && p2_cmd_en == 1'b1 
         && p2_cmd_instr[2] == 1'b0 && p2_cmd_instr[0] == 1'b1 )
          begin
           $display("ERROR - Invalid Command for write only port 2");
           $finish;
          end
  end
              
  always @(*)
  begin
    if ( C_PORT_CONFIG[119:96]  == "R32" && p2_cmd_en == 1'b1 
         && p2_cmd_instr[2] == 1'b0 && p2_cmd_instr[0] == 1'b0 )
          begin
           $display("ERROR - Invalid Command for read only port 2");
           $finish;
          end
  end
// Catch Invalid command during simulation for Port 3              
  always @(*)
  begin
    if ( C_PORT_CONFIG[87:64]  == "W32" && p3_cmd_en == 1'b1 
         && p3_cmd_instr[2] == 1'b0 && p3_cmd_instr[0] == 1'b1 )
          begin
           $display("ERROR - Invalid Command for write only port 3");
           $finish;
          end
  end
              
  always @(*)
  begin
    if ( C_PORT_CONFIG[87:64]  == "R32" && p3_cmd_en == 1'b1 
         && p3_cmd_instr[2] == 1'b0  && p3_cmd_instr[0] == 1'b0 )
          begin
           $display("ERROR - Invalid Command for read only port 3");
           $finish;
          end
  end
  
// Catch Invalid command during simulation for Port 4              
  always @(*)
  begin
    if ( C_PORT_CONFIG[55:32]  == "W32" && p4_cmd_en == 1'b1 
         && p4_cmd_instr[2] == 1'b0 && p4_cmd_instr[0] == 1'b1 )
          begin
           $display("ERROR - Invalid Command for write only port 4");
           $finish;
          end
  end
              
  always @(*)
  begin
    if ( C_PORT_CONFIG[55:32]  == "R32" && p4_cmd_en == 1'b1 
         && p4_cmd_instr[2] == 1'b0 && p4_cmd_instr[0] == 1'b0 )
          begin
           $display("ERROR - Invalid Command for read only port 4");
           $finish;
          end
  end
// Catch Invalid command during simulation for Port 5              
  always @(*)
  begin
    if ( C_PORT_CONFIG[23:0]  == "W32" && p5_cmd_en == 1'b1 
         && p5_cmd_instr[2] == 1'b0 && p5_cmd_instr[0] == 1'b1 )
          begin
           $display("ERROR - Invalid Command for write only port 5");
           $finish;
          end
  end
              
  always @(*)
  begin
    if ( C_PORT_CONFIG[23:0]  == "R32" && p5_cmd_en == 1'b1 
         && p5_cmd_instr[2] == 1'b0  && p5_cmd_instr[0] == 1'b0 )
          begin
           $display("ERROR - Invalid Command for read only port 5");
           $finish;
          end
  end  
   //synthesis translate_on 


  // the local declaration of input port signals doesn't work.  The mig_p1_xxx through mig_p5_xxx always ends up
  // high Z even though there are signals on p1_cmd_xxx through p5_cmd_xxxx.
  // The only solutions that I have is to have MIG tool remove the entire internal codes that doesn't belongs to the Configuration..
  //

               // Inputs from Application CMD Port

               if (C_PORT_ENABLE[0] == 1'b1)
               begin

                   assign mig_p0_arb_en      =      p0_arb_en ;
                   assign mig_p0_cmd_clk     =      p0_cmd_clk  ;
                   assign mig_p0_cmd_en      =      p0_cmd_en   ;
                   assign mig_p0_cmd_ra      =      p0_cmd_ra  ;
                   assign mig_p0_cmd_ba      =      p0_cmd_ba   ;
                   assign mig_p0_cmd_ca      =      p0_cmd_ca  ;
                   assign mig_p0_cmd_instr   =      p0_cmd_instr;
                   assign mig_p0_cmd_bl      =      {(p0_cmd_instr[2] | p0_cmd_bl[5]),p0_cmd_bl[4:0]}  ;
                   assign p0_cmd_empty       =      mig_p0_cmd_empty;
                   assign p0_cmd_full        =      mig_p0_cmd_full ;
                   
               end else
               begin
               
                   assign mig_p0_arb_en      =     'b0;
                   assign mig_p0_cmd_clk     =     'b0;
                   assign mig_p0_cmd_en      =     'b0;
                   assign mig_p0_cmd_ra      =     'b0;
                   assign mig_p0_cmd_ba      =     'b0;
                   assign mig_p0_cmd_ca      =     'b0;
                   assign mig_p0_cmd_instr   =     'b0;
                   assign mig_p0_cmd_bl      =     'b0;
                   assign p0_cmd_empty       =     'b0;
                   assign p0_cmd_full        =     'b0;
                   
               end
               

               if (C_PORT_ENABLE[1] == 1'b1)
               begin


                   assign mig_p1_arb_en      =      p1_arb_en ;
                   assign mig_p1_cmd_clk     =      p1_cmd_clk  ;
                   assign mig_p1_cmd_en      =      p1_cmd_en   ;
                   assign mig_p1_cmd_ra      =      p1_cmd_ra  ;
                   assign mig_p1_cmd_ba      =      p1_cmd_ba   ;
                   assign mig_p1_cmd_ca      =      p1_cmd_ca  ;
                   assign mig_p1_cmd_instr   =      p1_cmd_instr;
                   assign mig_p1_cmd_bl      =      {(p1_cmd_instr[2] | p1_cmd_bl[5]),p1_cmd_bl[4:0]}  ;
                   assign p1_cmd_empty       =      mig_p1_cmd_empty;
                   assign p1_cmd_full        =      mig_p1_cmd_full ;
                   
               end else
               begin
                   assign mig_p1_arb_en      =     'b0;
                   assign mig_p1_cmd_clk     =     'b0;
                   assign mig_p1_cmd_en      =     'b0;
                   assign mig_p1_cmd_ra      =     'b0;
                   assign mig_p1_cmd_ba      =     'b0;
                   assign mig_p1_cmd_ca      =     'b0;
                   assign mig_p1_cmd_instr   =     'b0;
                   assign mig_p1_cmd_bl      =     'b0;
                   assign p1_cmd_empty       =      'b0;
                   assign p1_cmd_full        =      'b0;
                   
                   
               end
               

               if (C_PORT_ENABLE[2] == 1'b1)
               begin

                   assign mig_p2_arb_en      =      p2_arb_en ;
                   assign mig_p2_cmd_clk     =      p2_cmd_clk  ;
                   assign mig_p2_cmd_en      =      p2_cmd_en   ;
                   assign mig_p2_cmd_ra      =      p2_cmd_ra  ;
                   assign mig_p2_cmd_ba      =      p2_cmd_ba   ;
                   assign mig_p2_cmd_ca      =      p2_cmd_ca  ;
                   assign mig_p2_cmd_instr   =      p2_cmd_instr;
                   assign mig_p2_cmd_bl      =      {(p2_cmd_instr[2] | p2_cmd_bl[5]),p2_cmd_bl[4:0]}  ;
                   assign p2_cmd_empty   =      mig_p2_cmd_empty;
                   assign p2_cmd_full    =      mig_p2_cmd_full ;
                   
               end else
               begin

                   assign mig_p2_arb_en      =      'b0;
                   assign mig_p2_cmd_clk     =      'b0;
                   assign mig_p2_cmd_en      =      'b0;
                   assign mig_p2_cmd_ra      =      'b0;
                   assign mig_p2_cmd_ba      =      'b0;
                   assign mig_p2_cmd_ca      =      'b0;
                   assign mig_p2_cmd_instr   =      'b0;
                   assign mig_p2_cmd_bl      =      'b0;
                   assign p2_cmd_empty   =       'b0;
                   assign p2_cmd_full    =       'b0;
                   
               end
               
 

               if (C_PORT_ENABLE[3] == 1'b1)
               begin

                   assign mig_p3_arb_en    =        p3_arb_en ;
                   assign mig_p3_cmd_clk     =      p3_cmd_clk  ;
                   assign mig_p3_cmd_en      =      p3_cmd_en   ;
                   assign mig_p3_cmd_ra      =      p3_cmd_ra  ;
                   assign mig_p3_cmd_ba      =      p3_cmd_ba   ;
                   assign mig_p3_cmd_ca      =      p3_cmd_ca  ;
                   assign mig_p3_cmd_instr   =      p3_cmd_instr;
                   assign mig_p3_cmd_bl      =      {(p3_cmd_instr[2] | p3_cmd_bl[5]),p3_cmd_bl[4:0]}  ;
                   assign p3_cmd_empty   =      mig_p3_cmd_empty;
                   assign p3_cmd_full    =      mig_p3_cmd_full ;
                   
               end else
               begin
                   assign mig_p3_arb_en    =       'b0;
                   assign mig_p3_cmd_clk     =     'b0;
                   assign mig_p3_cmd_en      =     'b0;
                   assign mig_p3_cmd_ra      =     'b0;
                   assign mig_p3_cmd_ba      =     'b0;
                   assign mig_p3_cmd_ca      =     'b0;
                   assign mig_p3_cmd_instr   =     'b0;
                   assign mig_p3_cmd_bl      =     'b0;
                   assign p3_cmd_empty   =     'b0;
                   assign p3_cmd_full    =     'b0;
                   
               end
               
               if (C_PORT_ENABLE[4] == 1'b1)
               begin

                   assign mig_p4_arb_en    =        p4_arb_en ;
                   assign mig_p4_cmd_clk     =      p4_cmd_clk  ;
                   assign mig_p4_cmd_en      =      p4_cmd_en   ;
                   assign mig_p4_cmd_ra      =      p4_cmd_ra  ;
                   assign mig_p4_cmd_ba      =      p4_cmd_ba   ;
                   assign mig_p4_cmd_ca      =      p4_cmd_ca  ;
                   assign mig_p4_cmd_instr   =      p4_cmd_instr;
                   assign mig_p4_cmd_bl      =      {(p4_cmd_instr[2] | p4_cmd_bl[5]),p4_cmd_bl[4:0]}  ;
                   assign p4_cmd_empty   =      mig_p4_cmd_empty;
                   assign p4_cmd_full    =      mig_p4_cmd_full ;
                   
               end else
               begin
                   assign mig_p4_arb_en      =      'b0;
                   assign mig_p4_cmd_clk     =      'b0;
                   assign mig_p4_cmd_en      =      'b0;
                   assign mig_p4_cmd_ra      =      'b0;
                   assign mig_p4_cmd_ba      =      'b0;
                   assign mig_p4_cmd_ca      =      'b0;
                   assign mig_p4_cmd_instr   =      'b0;
                   assign mig_p4_cmd_bl      =      'b0;
                   assign p4_cmd_empty   =      'b0;
                   assign p4_cmd_full    =      'b0;
                   


               end

               if (C_PORT_ENABLE[5] == 1'b1)
               begin

                   assign  mig_p5_arb_en    =     p5_arb_en ;
                   assign  mig_p5_cmd_clk   =     p5_cmd_clk  ;
                   assign  mig_p5_cmd_en    =     p5_cmd_en   ;
                   assign  mig_p5_cmd_ra    =     p5_cmd_ra  ;
                   assign  mig_p5_cmd_ba    =     p5_cmd_ba   ;
                   assign  mig_p5_cmd_ca    =     p5_cmd_ca  ;
                   assign mig_p5_cmd_instr  =     p5_cmd_instr;
                   assign mig_p5_cmd_bl     =     {(p5_cmd_instr[2] | p5_cmd_bl[5]),p5_cmd_bl[4:0]}  ;
                   assign p5_cmd_empty   =     mig_p5_cmd_empty;
                   assign p5_cmd_full    =     mig_p5_cmd_full ;
                   
               end else
               begin
                   assign  mig_p5_arb_en     =   'b0;
                   assign  mig_p5_cmd_clk    =   'b0;
                   assign  mig_p5_cmd_en     =   'b0;
                   assign  mig_p5_cmd_ra     =   'b0;
                   assign  mig_p5_cmd_ba     =   'b0;
                   assign  mig_p5_cmd_ca     =   'b0;
                   assign mig_p5_cmd_instr   =   'b0;
                   assign mig_p5_cmd_bl      =   'b0;
                   assign p5_cmd_empty   =     'b0;
                   assign p5_cmd_full    =     'b0;
                   
               
               end




              // Inputs from Application User Port
              
              // Port 0
               if (C_PORT_ENABLE[0] == 1'b1)
               begin
                assign mig_p0_wr_clk   = p0_wr_clk;
                assign mig_p0_rd_clk   = p0_rd_clk;
                assign mig_p0_wr_en    = p0_wr_en;
                assign mig_p0_rd_en    = p0_rd_en;
                assign mig_p0_wr_mask  = p0_wr_mask[3:0];
                assign mig_p0_wr_data  = p0_wr_data[31:0];
                assign p0_rd_data        = mig_p0_rd_data;
                assign p0_rd_full        = mig_p0_rd_full;
                assign p0_rd_empty       = mig_p0_rd_empty;
                assign p0_rd_error       = mig_p0_rd_error;
                assign p0_wr_error       = mig_p0_wr_error;
                assign p0_rd_overflow    = mig_p0_rd_overflow;
                assign p0_wr_underrun    = mig_p0_wr_underrun;
                assign p0_wr_empty       = mig_p0_wr_empty;
                assign p0_wr_full        = mig_p0_wr_full;
                assign p0_wr_count       = mig_p0_wr_count;
                assign p0_rd_count       = mig_p0_rd_count  ; 
                
                
               end
               else
               begin
                assign mig_p0_wr_clk     = 'b0;
                assign mig_p0_rd_clk     = 'b0;
                assign mig_p0_wr_en      = 'b0;
                assign mig_p0_rd_en      = 'b0;
                assign mig_p0_wr_mask    = 'b0;
                assign mig_p0_wr_data    = 'b0;
                assign p0_rd_data        = 'b0;
                assign p0_rd_full        = 'b0;
                assign p0_rd_empty       = 'b0;
                assign p0_rd_error       = 'b0;
                assign p0_wr_error       = 'b0;
                assign p0_rd_overflow    = 'b0;
                assign p0_wr_underrun    = 'b0;
                assign p0_wr_empty       = 'b0;
                assign p0_wr_full        = 'b0;
                assign p0_wr_count       = 'b0;
                assign p0_rd_count       = 'b0;
                
                
               end
              
              
              // Port 1
               if (C_PORT_ENABLE[1] == 1'b1)
               begin
              
                assign mig_p1_wr_clk   = p1_wr_clk;
                assign mig_p1_rd_clk   = p1_rd_clk;                
                assign mig_p1_wr_en    = p1_wr_en;
                assign mig_p1_wr_mask  = p1_wr_mask[3:0];                
                assign mig_p1_wr_data  = p1_wr_data[31:0];
                assign mig_p1_rd_en    = p1_rd_en;
                assign p1_rd_data     = mig_p1_rd_data;
                assign p1_rd_empty    = mig_p1_rd_empty;
                assign p1_rd_full     = mig_p1_rd_full;
                assign p1_rd_error    = mig_p1_rd_error;
                assign p1_wr_error    = mig_p1_wr_error;
                assign p1_rd_overflow = mig_p1_rd_overflow;
                assign p1_wr_underrun    = mig_p1_wr_underrun;
                assign p1_wr_empty    = mig_p1_wr_empty;
                assign p1_wr_full    = mig_p1_wr_full;
                assign p1_wr_count  = mig_p1_wr_count;
                assign p1_rd_count  = mig_p1_rd_count  ; 
                
               end else
               begin
              
                assign mig_p1_wr_clk   = 'b0;
                assign mig_p1_rd_clk   = 'b0;            
                assign mig_p1_wr_en    = 'b0;
                assign mig_p1_wr_mask  = 'b0;          
                assign mig_p1_wr_data  = 'b0;
                assign mig_p1_rd_en    = 'b0;
                assign p1_rd_data     =  'b0;
                assign p1_rd_empty    =  'b0;
                assign p1_rd_full     =  'b0;
                assign p1_rd_error    =  'b0;
                assign p1_wr_error    =  'b0;
                assign p1_rd_overflow =  'b0;
                assign p1_wr_underrun =  'b0;
                assign p1_wr_empty    =  'b0;
                assign p1_wr_full     =  'b0;
                assign p1_wr_count    =  'b0;
                assign p1_rd_count    =  'b0;
                
                
               end
                
                
                


// whenever PORT 2 is in Write mode           
         if(C_PORT_CONFIG[183:160] == "B32" && C_PORT_CONFIG[119:96] == "W32") begin : u_config1_2W
                  if (C_PORT_ENABLE[2] == 1'b1)
                  begin
                       assign mig_p2_clk      = p2_wr_clk;
                       assign mig_p2_wr_data  = p2_wr_data[31:0];
                       assign mig_p2_wr_mask  = p2_wr_mask[3:0];
                       assign mig_p2_en       = p2_wr_en; // this signal will not shown up if the port 5 is for read dir
                       assign p2_wr_error     = mig_p2_error;                       
                       assign p2_wr_full      = mig_p2_full;
                       assign p2_wr_empty     = mig_p2_empty;
                       assign p2_wr_underrun  = mig_p2_underrun;
                       assign p2_wr_count     = mig_p2_count  ; // wr port
                       
                       
                  end else
                  begin
                       assign mig_p2_clk      = 'b0;
                       assign mig_p2_wr_data  = 'b0;
                       assign mig_p2_wr_mask  = 'b0;
                       assign mig_p2_en       = 'b0;
                       assign p2_wr_error     = 'b0;
                       assign p2_wr_full      = 'b0;
                       assign p2_wr_empty     = 'b0;
                       assign p2_wr_underrun  = 'b0;
                       assign p2_wr_count     = 'b0;
                                                
                  end                           
                   assign p2_rd_data        = 'b0;
                   assign p2_rd_overflow    = 'b0;
                   assign p2_rd_error       = 'b0;
                   assign p2_rd_full        = 'b0;
                   assign p2_rd_empty       = 'b0;
                   assign p2_rd_count       = 'b0;
//                   assign p2_rd_error       = 'b0;
                       
                       
                         
         end else if(C_PORT_CONFIG[183:160] == "B32" && C_PORT_CONFIG[119:96] == "R32") begin : u_config1_2R

                  if (C_PORT_ENABLE[2] == 1'b1)
                  begin
                       assign mig_p2_clk        = p2_rd_clk;
                       assign p2_rd_data        = mig_p2_rd_data;
                       assign mig_p2_en         = p2_rd_en;  
                       assign p2_rd_overflow    = mig_p2_overflow;
                       assign p2_rd_error       = mig_p2_error;
                       assign p2_rd_full        = mig_p2_full;
                       assign p2_rd_empty       = mig_p2_empty;
                       assign p2_rd_count       = mig_p2_count  ; // wr port
                       
                  end else       
                  begin
                       assign mig_p2_clk        = 'b0;
                       assign p2_rd_data        = 'b0;
                       assign mig_p2_en         = 'b0;
                       
                       assign p2_rd_overflow    = 'b0;
                       assign p2_rd_error       = 'b0;
                       assign p2_rd_full        = 'b0;
                       assign p2_rd_empty       = 'b0;
                       assign p2_rd_count       = 'b0;
                       
                  end
                  assign mig_p2_wr_data  = 'b0;
                  assign mig_p2_wr_mask  = 'b0;
                  assign p2_wr_error     = 'b0;
                  assign p2_wr_full      = 'b0;
                  assign p2_wr_empty     = 'b0;
                  assign p2_wr_underrun  = 'b0;
                  assign p2_wr_count     = 'b0;
          
          end 
          if(C_PORT_CONFIG[183:160] == "B32" && C_PORT_CONFIG[87:64]  == "W32") begin : u_config1_3W
// whenever PORT 3 is in Write mode         

                  if (C_PORT_ENABLE[3] == 1'b1)
                  begin

                       assign mig_p3_clk   = p3_wr_clk;
                       assign mig_p3_wr_data  = p3_wr_data[31:0];
                       assign mig_p3_wr_mask  = p3_wr_mask[3:0];
                       assign mig_p3_en       = p3_wr_en; 
                       assign p3_wr_full      = mig_p3_full;
                       assign p3_wr_empty     = mig_p3_empty;
                       assign p3_wr_underrun  = mig_p3_underrun;
                       assign p3_wr_count     = mig_p3_count  ; // wr port
                       assign p3_wr_error     = mig_p3_error;
                       
                  end else 
                  begin
                       assign mig_p3_clk      = 'b0;
                       assign mig_p3_wr_data  = 'b0;
                       assign mig_p3_wr_mask  = 'b0;
                       assign mig_p3_en       = 'b0;
                       assign p3_wr_full      = 'b0;
                       assign p3_wr_empty     = 'b0;
                       assign p3_wr_underrun  = 'b0;
                       assign p3_wr_count     = 'b0;
                       assign p3_wr_error     = 'b0;
                                                
                  end
                   assign p3_rd_overflow = 'b0;
                   assign p3_rd_error    = 'b0;
                   assign p3_rd_full     = 'b0;
                   assign p3_rd_empty    = 'b0;
                   assign p3_rd_count    = 'b0;
                   assign p3_rd_data     = 'b0;
       
                       
         end else if(C_PORT_CONFIG[183:160] == "B32" && C_PORT_CONFIG[87:64]  == "R32") begin : u_config1_3R
       
                  if (C_PORT_ENABLE[3] == 1'b1)
                  begin

                       assign mig_p3_clk     = p3_rd_clk;
                       assign p3_rd_data     = mig_p3_rd_data;                
                       assign mig_p3_en      = p3_rd_en;  // this signal will not shown up if the port 5 is for write dir
                       assign p3_rd_overflow = mig_p3_overflow;
                       assign p3_rd_error    = mig_p3_error;
                       assign p3_rd_full     = mig_p3_full;
                       assign p3_rd_empty    = mig_p3_empty;
                       assign p3_rd_count    = mig_p3_count  ; // wr port
                  end else
                  begin 
                       assign mig_p3_clk     = 'b0;
                       assign mig_p3_en      = 'b0;
                       assign p3_rd_overflow = 'b0;
                       assign p3_rd_full     = 'b0;
                       assign p3_rd_empty    = 'b0;
                       assign p3_rd_count    = 'b0;
                       assign p3_rd_error    = 'b0;
                       assign p3_rd_data     = 'b0;
                  end                  
                  assign p3_wr_full      = 'b0;
                  assign p3_wr_empty     = 'b0;
                  assign p3_wr_underrun  = 'b0;
                  assign p3_wr_count     = 'b0;
                  assign p3_wr_error     = 'b0;
                  assign mig_p3_wr_data  = 'b0;
                  assign mig_p3_wr_mask  = 'b0;
         end 
         if(C_PORT_CONFIG[183:160] == "B32" && C_PORT_CONFIG[55:32]  == "W32") begin : u_config1_4W
       // whenever PORT 4 is in Write mode       

                  if (C_PORT_ENABLE[4] == 1'b1)
                  begin
       
                       assign mig_p4_clk      = p4_wr_clk;
                       assign mig_p4_wr_data  = p4_wr_data[31:0];
                       assign mig_p4_wr_mask  = p4_wr_mask[3:0];
                       assign mig_p4_en       = p4_wr_en; // this signal will not shown up if the port 5 is for read dir
                       assign p4_wr_full      = mig_p4_full;
                       assign p4_wr_empty     = mig_p4_empty;
                       assign p4_wr_underrun  = mig_p4_underrun;
                       assign p4_wr_count     = mig_p4_count  ; // wr port
                       assign p4_wr_error     = mig_p4_error;

                  end else
                  begin
                       assign mig_p4_clk      = 'b0;
                       assign mig_p4_wr_data  = 'b0;
                       assign mig_p4_wr_mask  = 'b0;
                       assign mig_p4_en       = 'b0;
                       assign p4_wr_full      = 'b0;
                       assign p4_wr_empty     = 'b0;
                       assign p4_wr_underrun  = 'b0;
                       assign p4_wr_count     = 'b0;
                       assign p4_wr_error     = 'b0;
                  end                           
                   assign p4_rd_overflow    = 'b0;
                   assign p4_rd_error       = 'b0;
                   assign p4_rd_full        = 'b0;
                   assign p4_rd_empty       = 'b0;
                   assign p4_rd_count       = 'b0;
                   assign p4_rd_data        = 'b0;
       
         end else if(C_PORT_CONFIG[183:160] == "B32" && C_PORT_CONFIG[55:32]  == "R32") begin : u_config1_4R
                       
                  if (C_PORT_ENABLE[4] == 1'b1)
                  begin
                       assign mig_p4_clk        = p4_rd_clk;
                       assign p4_rd_data        = mig_p4_rd_data;                
                       assign mig_p4_en         = p4_rd_en;  // this signal will not shown up if the port 5 is for write dir
                       assign p4_rd_overflow    = mig_p4_overflow;
                       assign p4_rd_error       = mig_p4_error;
                       assign p4_rd_full        = mig_p4_full;
                       assign p4_rd_empty       = mig_p4_empty;
                       assign p4_rd_count       = mig_p4_count  ; // wr port
                       
                  end else
                  begin
                       assign mig_p4_clk        = 'b0;
                       assign p4_rd_data        = 'b0;
                       assign mig_p4_en         = 'b0;
                       assign p4_rd_overflow    = 'b0;
                       assign p4_rd_error       = 'b0;
                       assign p4_rd_full        = 'b0;
                       assign p4_rd_empty       = 'b0;
                       assign p4_rd_count       = 'b0;
                  end                  
                  assign p4_wr_full      = 'b0;
                  assign p4_wr_empty     = 'b0;
                  assign p4_wr_underrun  = 'b0;
                  assign p4_wr_count     = 'b0;
                  assign p4_wr_error     = 'b0;
                  assign mig_p4_wr_data  = 'b0;
                  assign mig_p4_wr_mask  = 'b0;


                       
                       
         end 
         
         if(C_PORT_CONFIG[183:160] == "B32" && C_PORT_CONFIG[23:0] == "W32") begin : u_config1_5W
       // whenever PORT 5 is in Write mode           

                       
                  if (C_PORT_ENABLE[5] == 1'b1)
                  begin
                       assign mig_p5_clk   = p5_wr_clk;
                       assign mig_p5_wr_data  = p5_wr_data[31:0];
                       assign mig_p5_wr_mask  = p5_wr_mask[3:0];
                       assign mig_p5_en       = p5_wr_en; 
                       assign p5_wr_full      = mig_p5_full;
                       assign p5_wr_empty     = mig_p5_empty;
                       assign p5_wr_underrun  = mig_p5_underrun;
                       assign p5_wr_count     = mig_p5_count  ; 
                       assign p5_wr_error     = mig_p5_error;
                       
                  end else
                  begin
                       assign mig_p5_clk      = 'b0;
                       assign mig_p5_wr_data  = 'b0;
                       assign mig_p5_wr_mask  = 'b0;
                       assign mig_p5_en       = 'b0;
                       assign p5_wr_full      = 'b0;
                       assign p5_wr_empty     = 'b0;
                       assign p5_wr_underrun  = 'b0;
                       assign p5_wr_count     = 'b0;
                       assign p5_wr_error     = 'b0;
                  end                           
                   assign p5_rd_data        = 'b0;
                   assign p5_rd_overflow    = 'b0;
                   assign p5_rd_error       = 'b0;
                   assign p5_rd_full        = 'b0;
                   assign p5_rd_empty       = 'b0;
                   assign p5_rd_count       = 'b0;
                  
       
                       
                         
         end else if(C_PORT_CONFIG[183:160] == "B32" && C_PORT_CONFIG[23:0] == "R32") begin : u_config1_5R

                  if (C_PORT_ENABLE[5] == 1'b1)
                  begin

                       assign mig_p5_clk        = p5_rd_clk;
                       assign p5_rd_data        = mig_p5_rd_data;                
                       assign mig_p5_en         = p5_rd_en;  
                       assign p5_rd_overflow    = mig_p5_overflow;
                       assign p5_rd_error       = mig_p5_error;
                       assign p5_rd_full        = mig_p5_full;
                       assign p5_rd_empty       = mig_p5_empty;
                       assign p5_rd_count       = mig_p5_count  ; 
                       
                 end else
                 begin
                       assign mig_p5_clk        = 'b0;
                       assign p5_rd_data        = 'b0;           
                       assign mig_p5_en         = 'b0;
                       assign p5_rd_overflow    = 'b0;
                       assign p5_rd_error       = 'b0;
                       assign p5_rd_full        = 'b0;
                       assign p5_rd_empty       = 'b0;
                       assign p5_rd_count       = 'b0;
                 
                 end
                 assign p5_wr_full      = 'b0;
                 assign p5_wr_empty     = 'b0;
                 assign p5_wr_underrun  = 'b0;
                 assign p5_wr_count     = 'b0;
                 assign p5_wr_error     = 'b0;
                 assign mig_p5_wr_data  = 'b0;
                 assign mig_p5_wr_mask  = 'b0;
                       
         end
                
  end else if(C_PORT_CONFIG == "B32_B32_B32_B32" ) begin : u_config_2

           
               // Inputs from Application CMD Port
               // *************  need to hook up rd /wr error outputs
               
                  if (C_PORT_ENABLE[0] == 1'b1)
                  begin
                           // command port signals
                           assign mig_p0_arb_en      =      p0_arb_en ;
                           assign mig_p0_cmd_clk     =      p0_cmd_clk  ;
                           assign mig_p0_cmd_en      =      p0_cmd_en   ;
                           assign mig_p0_cmd_ra      =      p0_cmd_ra  ;
                           assign mig_p0_cmd_ba      =      p0_cmd_ba   ;
                           assign mig_p0_cmd_ca      =      p0_cmd_ca  ;
                           assign mig_p0_cmd_instr   =      p0_cmd_instr;
                           assign mig_p0_cmd_bl      =       {(p0_cmd_instr[2] | p0_cmd_bl[5]),p0_cmd_bl[4:0]}   ;
                           
                           // Data port signals
                           assign mig_p0_rd_en    = p0_rd_en;                            
                           assign mig_p0_wr_clk   = p0_wr_clk;
                           assign mig_p0_rd_clk   = p0_rd_clk;
                           assign mig_p0_wr_en    = p0_wr_en;
                           assign mig_p0_wr_data  = p0_wr_data[31:0]; 
                           assign mig_p0_wr_mask  = p0_wr_mask[3:0];
                           assign p0_wr_count     = mig_p0_wr_count;
                           assign p0_rd_count  = mig_p0_rd_count  ; 

                           
                           
                 end else
                 begin
                           assign mig_p0_arb_en      =       'b0;
                           assign mig_p0_cmd_clk     =       'b0;
                           assign mig_p0_cmd_en      =       'b0;
                           assign mig_p0_cmd_ra      =       'b0;
                           assign mig_p0_cmd_ba      =       'b0;
                           assign mig_p0_cmd_ca      =       'b0;
                           assign mig_p0_cmd_instr   =       'b0;
                           assign mig_p0_cmd_bl      =       'b0;
                           
                           assign mig_p0_rd_en    = 'b0;                    
                           assign mig_p0_wr_clk   = 'b0;
                           assign mig_p0_rd_clk   = 'b0;
                           assign mig_p0_wr_en    = 'b0;
                           assign mig_p0_wr_data  = 'b0; 
                           assign mig_p0_wr_mask  = 'b0;
                           assign p0_wr_count     = 'b0;
                           assign p0_rd_count     = 'b0;

                           
                 end                           
                           
                           assign p0_cmd_empty       =      mig_p0_cmd_empty ;
                           assign p0_cmd_full        =      mig_p0_cmd_full  ;
                           
                           
                  if (C_PORT_ENABLE[1] == 1'b1)
                  begin
                           // command port signals

                           assign mig_p1_arb_en      =      p1_arb_en ;
                           assign mig_p1_cmd_clk     =      p1_cmd_clk  ;
                           assign mig_p1_cmd_en      =      p1_cmd_en   ;
                           assign mig_p1_cmd_ra      =      p1_cmd_ra  ;
                           assign mig_p1_cmd_ba      =      p1_cmd_ba   ;
                           assign mig_p1_cmd_ca      =      p1_cmd_ca  ;
                           assign mig_p1_cmd_instr   =      p1_cmd_instr;
                           assign mig_p1_cmd_bl      =      {(p1_cmd_instr[2] | p1_cmd_bl[5]),p1_cmd_bl[4:0]}  ;
                           // Data port signals
                 
                            assign mig_p1_wr_en    = p1_wr_en;
                            assign mig_p1_wr_clk   = p1_wr_clk;
                            assign mig_p1_rd_en    = p1_rd_en;
                            assign mig_p1_wr_data  = p1_wr_data[31:0];
                            assign mig_p1_wr_mask  = p1_wr_mask[3:0];                
                            assign mig_p1_rd_clk   = p1_rd_clk;
                            assign p1_wr_count     = mig_p1_wr_count;
                            assign p1_rd_count     = mig_p1_rd_count;
                           
                  end else
                  begin

                           assign mig_p1_arb_en      =       'b0;
                           assign mig_p1_cmd_clk     =       'b0;
                           assign mig_p1_cmd_en      =       'b0;
                           assign mig_p1_cmd_ra      =       'b0;
                           assign mig_p1_cmd_ba      =       'b0;
                           assign mig_p1_cmd_ca      =       'b0;
                           assign mig_p1_cmd_instr   =       'b0;
                           assign mig_p1_cmd_bl      =       'b0;
                           // Data port signals
                           assign mig_p1_wr_en    = 'b0; 
                           assign mig_p1_wr_clk   = 'b0;
                           assign mig_p1_rd_en    = 'b0;
                           assign mig_p1_wr_data  = 'b0;
                           assign mig_p1_wr_mask  = 'b0;                
                           assign mig_p1_rd_clk   = 'b0;
                            assign p1_wr_count     = 'b0;
                            assign p1_rd_count     = 'b0;
                  
                  end
                           
                           
                           assign p1_cmd_empty       =      mig_p1_cmd_empty ;
                           assign p1_cmd_full        =      mig_p1_cmd_full  ;
 
                  if (C_PORT_ENABLE[2] == 1'b1)
                  begin   //MCB Physical port               Logical Port
                           assign mig_p2_arb_en      =      p2_arb_en ;
                           assign mig_p2_cmd_clk     =      p2_cmd_clk  ;
                           assign mig_p2_cmd_en      =      p2_cmd_en   ;
                           assign mig_p2_cmd_ra      =      p2_cmd_ra  ;
                           assign mig_p2_cmd_ba      =      p2_cmd_ba   ;
                           assign mig_p2_cmd_ca      =      p2_cmd_ca  ;
                           assign mig_p2_cmd_instr   =      p2_cmd_instr;
                           assign mig_p2_cmd_bl      =      {(p2_cmd_instr[2] | p2_cmd_bl[5]),p2_cmd_bl[4:0]}   ;
                           
                            assign mig_p2_en       = p2_rd_en;
                            assign mig_p2_clk      = p2_rd_clk;
                            assign mig_p3_en       = p2_wr_en;
                            assign mig_p3_clk      = p2_wr_clk;
                            assign mig_p3_wr_data  = p2_wr_data[31:0];
                            assign mig_p3_wr_mask  = p2_wr_mask[3:0];
                            assign p2_wr_count     = mig_p3_count;
                            assign p2_rd_count     = mig_p2_count;
                           
                  end else
                  begin

                           assign mig_p2_arb_en      =      'b0;
                           assign mig_p2_cmd_clk     =      'b0;
                           assign mig_p2_cmd_en      =      'b0;
                           assign mig_p2_cmd_ra      =      'b0;
                           assign mig_p2_cmd_ba      =      'b0;
                           assign mig_p2_cmd_ca      =      'b0;
                           assign mig_p2_cmd_instr   =      'b0;
                           assign mig_p2_cmd_bl      =      'b0;

                            assign mig_p2_en       = 'b0; 
                            assign mig_p2_clk      = 'b0;
                            assign mig_p3_en       = 'b0;
                            assign mig_p3_clk      = 'b0;
                            assign mig_p3_wr_data  = 'b0; 
                            assign mig_p3_wr_mask  = 'b0;
                            assign p2_rd_count     = 'b0;
                            assign p2_wr_count     = 'b0;
                           
                 end                           
                         
                           assign p2_cmd_empty       =      mig_p2_cmd_empty ;
                           assign p2_cmd_full        =      mig_p2_cmd_full  ;
  
                 if (C_PORT_ENABLE[3] == 1'b1)
                  begin   //MCB Physical port               Logical Port
                           assign mig_p4_arb_en      =      p3_arb_en ;
                           assign mig_p4_cmd_clk     =      p3_cmd_clk  ;
                           assign mig_p4_cmd_en      =      p3_cmd_en   ;
                           assign mig_p4_cmd_ra      =      p3_cmd_ra  ;
                           assign mig_p4_cmd_ba      =      p3_cmd_ba   ;
                           assign mig_p4_cmd_ca      =      p3_cmd_ca  ;
                           assign mig_p4_cmd_instr   =      p3_cmd_instr;
                           assign mig_p4_cmd_bl      =      {(p3_cmd_instr[2] | p3_cmd_bl[5]),p3_cmd_bl[4:0]}  ;

                           assign mig_p4_clk      = p3_rd_clk;
                           assign mig_p4_en       = p3_rd_en;                            
                           assign mig_p5_clk      = p3_wr_clk;
                           assign mig_p5_en       = p3_wr_en; 
                           assign mig_p5_wr_data  = p3_wr_data[31:0];
                           assign mig_p5_wr_mask  = p3_wr_mask[3:0];
                           assign p3_rd_count     = mig_p4_count;
                           assign p3_wr_count     = mig_p5_count;
                           
                           
                  end else
                  begin
                           assign mig_p4_arb_en      =     'b0;
                           assign mig_p4_cmd_clk     =     'b0;
                           assign mig_p4_cmd_en      =     'b0;
                           assign mig_p4_cmd_ra      =     'b0;
                           assign mig_p4_cmd_ba      =     'b0;
                           assign mig_p4_cmd_ca      =     'b0;
                           assign mig_p4_cmd_instr   =     'b0;
                           assign mig_p4_cmd_bl      =     'b0;
                           
                            assign mig_p4_clk      = 'b0; 
                            assign mig_p4_en       = 'b0;                   
                            assign mig_p5_clk      = 'b0;
                            assign mig_p5_en       = 'b0;
                            assign mig_p5_wr_data  = 'b0; 
                            assign mig_p5_wr_mask  = 'b0;
                            assign p3_rd_count     = 'b0;
                            assign p3_wr_count     = 'b0;
                           
                          
                           
                  end         
                           
                           assign p3_cmd_empty       =      mig_p4_cmd_empty ;
                           assign p3_cmd_full        =      mig_p4_cmd_full  ;
                           
                           
                            // outputs to Applications User Port
                            assign p0_rd_data     = mig_p0_rd_data;
                            assign p1_rd_data     = mig_p1_rd_data;
                            assign p2_rd_data     = mig_p2_rd_data;
                            assign p3_rd_data     = mig_p4_rd_data;

                            assign p0_rd_empty    = mig_p0_rd_empty;
                            assign p1_rd_empty    = mig_p1_rd_empty;
                            assign p2_rd_empty    = mig_p2_empty;
                            assign p3_rd_empty    = mig_p4_empty;

                            assign p0_rd_full     = mig_p0_rd_full;
                            assign p1_rd_full     = mig_p1_rd_full;
                            assign p2_rd_full     = mig_p2_full;
                            assign p3_rd_full     = mig_p4_full;

                            assign p0_rd_error    = mig_p0_rd_error;
                            assign p1_rd_error    = mig_p1_rd_error;
                            assign p2_rd_error    = mig_p2_error;
                            assign p3_rd_error    = mig_p4_error;
                            
                            assign p0_rd_overflow = mig_p0_rd_overflow;
                            assign p1_rd_overflow = mig_p1_rd_overflow;
                            assign p2_rd_overflow = mig_p2_overflow;
                            assign p3_rd_overflow = mig_p4_overflow;

                            assign p0_wr_underrun = mig_p0_wr_underrun;
                            assign p1_wr_underrun = mig_p1_wr_underrun;
                            assign p2_wr_underrun = mig_p3_underrun;
                            assign p3_wr_underrun = mig_p5_underrun;
                            
                            assign p0_wr_empty    = mig_p0_wr_empty;
                            assign p1_wr_empty    = mig_p1_wr_empty;
                            assign p2_wr_empty    = mig_p3_empty; 
                            assign p3_wr_empty    = mig_p5_empty; 
 
                            assign p0_wr_full    = mig_p0_wr_full;
                            assign p1_wr_full    = mig_p1_wr_full;
                            assign p2_wr_full    = mig_p3_full;
                            assign p3_wr_full    = mig_p5_full;

                            assign p0_wr_error    = mig_p0_wr_error;
                            assign p1_wr_error    = mig_p1_wr_error;
                            assign p2_wr_error    = mig_p3_error;
                            assign p3_wr_error    = mig_p5_error;

     // unused ports signals
                           assign p4_cmd_empty        =     1'b0;
                           assign p4_cmd_full         =     1'b0;
                           assign mig_p2_wr_mask  = 'b0;
                           assign mig_p4_wr_mask  = 'b0;

                           assign mig_p2_wr_data     = 'b0;
                           assign mig_p4_wr_data     = 'b0;

                           assign p5_cmd_empty        =     1'b0;
                           assign p5_cmd_full         =     1'b0;
     
 
                            assign mig_p3_cmd_clk     =      1'b0;
                            assign mig_p3_cmd_en      =      1'b0;
                            assign mig_p3_cmd_ra      =      15'd0;
                            assign mig_p3_cmd_ba      =      3'd0;
                            assign mig_p3_cmd_ca      =      12'd0;
                            assign mig_p3_cmd_instr   =      3'd0;
                            assign mig_p3_cmd_bl      =      6'd0;
                            assign mig_p3_arb_en      =      1'b0;  // physical cmd port 3 is not used in this config
                            
                            
                            
                            
                            assign mig_p5_arb_en      =      1'b0;  // physical cmd port 3 is not used in this config
                            assign mig_p5_cmd_clk     =      1'b0;
                            assign mig_p5_cmd_en      =      1'b0;
                            assign mig_p5_cmd_ra      =      15'd0;
                            assign mig_p5_cmd_ba      =      3'd0;
                            assign mig_p5_cmd_ca      =      12'd0;
                            assign mig_p5_cmd_instr   =      3'd0;
                            assign mig_p5_cmd_bl      =      6'd0;



      ////////////////////////////////////////////////////////////////////////////
      /////////////////////////////////////////////////////////////////////////////
      ////     
      ////                         B64_B32_B32
      ////     
      /////////////////////////////////////////////////////////////////////////////
      ////////////////////////////////////////////////////////////////////////////

     
     
  end else if(C_PORT_CONFIG == "B64_B32_B32" ) begin : u_config_3

               // Inputs from Application CMD Port
 
 
       if (C_PORT_ENABLE[0] == 1'b1)
       begin
               assign mig_p0_arb_en      =  p0_arb_en ;
               assign mig_p0_cmd_clk     =  p0_cmd_clk  ;
               assign mig_p0_cmd_en      =  p0_cmd_en   ;
               assign mig_p0_cmd_ra      =  p0_cmd_ra  ;
               assign mig_p0_cmd_ba      =  p0_cmd_ba   ;
               assign mig_p0_cmd_ca      =  p0_cmd_ca  ;
               assign mig_p0_cmd_instr   =  p0_cmd_instr;
               assign mig_p0_cmd_bl      =   {(p0_cmd_instr[2] | p0_cmd_bl[5]),p0_cmd_bl[4:0]}   ;
               assign p0_cmd_empty       =  mig_p0_cmd_empty ;
               assign p0_cmd_full        =  mig_p0_cmd_full  ;

               assign mig_p0_wr_clk   = p0_wr_clk;
               assign mig_p0_rd_clk   = p0_rd_clk;
               assign mig_p1_wr_clk   = p0_wr_clk;
               assign mig_p1_rd_clk   = p0_rd_clk;
                
               if (C_USR_INTERFACE_MODE == "AXI")
                   assign mig_p0_wr_en    = p0_wr_en ;
               else
                   assign mig_p0_wr_en    = p0_wr_en & !p0_wr_full;

               if (C_USR_INTERFACE_MODE == "AXI")
                   assign mig_p1_wr_en    = p0_wr_en ;
               else
                   assign mig_p1_wr_en    = p0_wr_en & !p0_wr_full;
                   
               assign mig_p0_wr_data  = p0_wr_data[31:0];
               assign mig_p0_wr_mask  = p0_wr_mask[3:0];
               assign mig_p1_wr_data  = p0_wr_data[63 : 32];
               assign mig_p1_wr_mask  = p0_wr_mask[7 : 4];     

               assign p0_rd_empty       = mig_p1_rd_empty;
               assign p0_rd_data        = {mig_p1_rd_data , mig_p0_rd_data}; 
               if (C_USR_INTERFACE_MODE == "AXI")
                   assign mig_p0_rd_en    = p0_rd_en ;
               else
                   assign mig_p0_rd_en    = p0_rd_en & !p0_rd_empty;

               if (C_USR_INTERFACE_MODE == "AXI")               
                   assign mig_p1_rd_en    = p0_rd_en ;
                else
                   assign mig_p1_rd_en    = p0_rd_en & !p0_rd_empty;

                assign p0_wr_count       = mig_p1_wr_count;  // B64 for port 0, map most significant port to output
                assign p0_rd_count       = mig_p1_rd_count;
                assign p0_wr_empty       = mig_p1_wr_empty;
                assign p0_wr_error       = mig_p1_wr_error | mig_p0_wr_error;  
                assign p0_wr_full        = mig_p1_wr_full;
                assign p0_wr_underrun    = mig_p1_wr_underrun | mig_p0_wr_underrun; 
                assign p0_rd_overflow    = mig_p1_rd_overflow | mig_p0_rd_overflow; 
                assign p0_rd_error       = mig_p1_rd_error | mig_p0_rd_error; 
                assign p0_rd_full        = mig_p1_rd_full;

 
       end else
       begin
       
               assign mig_p0_arb_en      = 'b0;
               assign mig_p0_cmd_clk     = 'b0;
               assign mig_p0_cmd_en      = 'b0;
               assign mig_p0_cmd_ra      = 'b0;
               assign mig_p0_cmd_ba      = 'b0;
               assign mig_p0_cmd_ca      = 'b0;
               assign mig_p0_cmd_instr   = 'b0;
               assign mig_p0_cmd_bl      = 'b0;
               assign p0_cmd_empty       =  'b0;
               assign p0_cmd_full        =  'b0;


               assign mig_p0_wr_clk   = 'b0;
               assign mig_p0_rd_clk   = 'b0;
               assign mig_p1_wr_clk   = 'b0;
               assign mig_p1_rd_clk   = 'b0;
               
               assign mig_p0_wr_en    = 'b0;
               assign mig_p1_wr_en    = 'b0;
               assign mig_p0_wr_data  = 'b0;
               assign mig_p0_wr_mask  = 'b0;
               assign mig_p1_wr_data  = 'b0;
               assign mig_p1_wr_mask  = 'b0; 

               assign p0_rd_empty       = 'b0;
               assign p0_rd_data        = 'b0;
               assign mig_p0_rd_en      = 'b0;
               assign mig_p1_rd_en      = 'b0;
 
 
               assign p0_wr_count       =  'b0;
               assign p0_rd_count       =  'b0;
               assign p0_wr_empty       =  'b0;
               assign p0_wr_error       =  'b0;
               assign p0_wr_full        =  'b0;
               assign p0_wr_underrun    =  'b0;
               assign p0_rd_overflow    =  'b0;
               assign p0_rd_error       =  'b0;
               assign p0_rd_full        =  'b0;
                                         

       end       
       
        
 
       if (C_PORT_ENABLE[1] == 1'b1)
       begin

               assign mig_p2_arb_en      =      p1_arb_en ;
               assign mig_p2_cmd_clk     =      p1_cmd_clk  ;
               assign mig_p2_cmd_en      =      p1_cmd_en   ;
               assign mig_p2_cmd_ra      =      p1_cmd_ra  ;
               assign mig_p2_cmd_ba      =      p1_cmd_ba   ;
               assign mig_p2_cmd_ca      =      p1_cmd_ca  ;
               assign mig_p2_cmd_instr   =      p1_cmd_instr;
               assign mig_p2_cmd_bl      =      {(p1_cmd_instr[2] | p1_cmd_bl[5]),p1_cmd_bl[4:0]}  ;
               assign p1_cmd_empty       =      mig_p2_cmd_empty;  
               assign p1_cmd_full        =      mig_p2_cmd_full;   

               assign mig_p2_clk         = p1_rd_clk;
               assign mig_p3_clk         = p1_wr_clk;

               assign mig_p3_en       = p1_wr_en;
               assign mig_p3_wr_data  = p1_wr_data[31:0];
               assign mig_p3_wr_mask  = p1_wr_mask[3:0];
               assign mig_p2_en       = p1_rd_en;

               assign p1_rd_data        = mig_p2_rd_data;
               assign p1_wr_count       = mig_p3_count;
               assign p1_rd_count       = mig_p2_count;
               assign p1_wr_empty       = mig_p3_empty;
               assign p1_wr_error       = mig_p3_error;                 
               assign p1_wr_full        = mig_p3_full;
               assign p1_wr_underrun    = mig_p3_underrun;
               assign p1_rd_overflow    = mig_p2_overflow; 
               assign p1_rd_error       = mig_p2_error;
               assign p1_rd_full        = mig_p2_full;
               assign p1_rd_empty       = mig_p2_empty;
 
       end else
       begin

               assign mig_p2_arb_en      =     'b0; 
               assign mig_p2_cmd_clk     =     'b0; 
               assign mig_p2_cmd_en      =     'b0; 
               assign mig_p2_cmd_ra      =     'b0; 
               assign mig_p2_cmd_ba      =     'b0; 
               assign mig_p2_cmd_ca      =     'b0; 
               assign mig_p2_cmd_instr   =     'b0; 
               assign mig_p2_cmd_bl      =     'b0; 
               assign p1_cmd_empty       =     'b0; 
               assign p1_cmd_full        =     'b0; 
               assign mig_p3_en       = 'b0; 
               assign mig_p3_wr_data  = 'b0; 
               assign mig_p3_wr_mask  = 'b0; 
               assign mig_p2_en       = 'b0; 

               assign mig_p2_clk   = 'b0; 
               assign mig_p3_clk   = 'b0; 
               
               assign p1_rd_data        = 'b0; 
               assign p1_wr_count       = 'b0; 
               assign p1_rd_count       = 'b0; 
               assign p1_wr_empty       = 'b0; 
               assign p1_wr_error       = 'b0;         
               assign p1_wr_full        = 'b0; 
               assign p1_wr_underrun    = 'b0; 
               assign p1_rd_overflow    = 'b0; 
               assign p1_rd_error       = 'b0; 
               assign p1_rd_full        = 'b0; 
               assign p1_rd_empty       = 'b0; 
 
       end
       
       if (C_PORT_ENABLE[2] == 1'b1)
       begin
               assign mig_p4_arb_en      = p2_arb_en ;
               assign mig_p4_cmd_clk     = p2_cmd_clk  ;
               assign mig_p4_cmd_en      = p2_cmd_en   ;
               assign mig_p4_cmd_ra      = p2_cmd_ra  ;
               assign mig_p4_cmd_ba      = p2_cmd_ba   ;
               assign mig_p4_cmd_ca      = p2_cmd_ca  ;
               assign mig_p4_cmd_instr   = p2_cmd_instr;
               assign mig_p4_cmd_bl      = {(p2_cmd_instr[2] | p2_cmd_bl[5]),p2_cmd_bl[4:0]}   ;
               assign p2_cmd_empty       = mig_p4_cmd_empty ; 
               assign p2_cmd_full        = mig_p4_cmd_full  ; 
               assign mig_p5_en          = p2_wr_en;
               assign mig_p5_wr_data     = p2_wr_data[31:0];
               assign mig_p5_wr_mask     = p2_wr_mask[3:0];
               assign mig_p4_en          = p2_rd_en;
               
                assign mig_p4_clk        = p2_rd_clk;
                assign mig_p5_clk        = p2_wr_clk;

                assign p2_rd_data        = mig_p4_rd_data;
                assign p2_wr_count       = mig_p5_count;
                assign p2_rd_count       = mig_p4_count;
                assign p2_wr_empty       = mig_p5_empty;
                assign p2_wr_full        = mig_p5_full;
                assign p2_wr_error       = mig_p5_error;  
                assign p2_wr_underrun    = mig_p5_underrun;
                assign p2_rd_overflow    = mig_p4_overflow;    
                assign p2_rd_error       = mig_p4_error;
                assign p2_rd_full        = mig_p4_full;
                assign p2_rd_empty       = mig_p4_empty;
               
       end else
       begin
               assign mig_p4_arb_en      = 'b0;   
               assign mig_p4_cmd_clk     = 'b0;   
               assign mig_p4_cmd_en      = 'b0;   
               assign mig_p4_cmd_ra      = 'b0;   
               assign mig_p4_cmd_ba      = 'b0;   
               assign mig_p4_cmd_ca      = 'b0;   
               assign mig_p4_cmd_instr   = 'b0;   
               assign mig_p4_cmd_bl      = 'b0;   
               assign p2_cmd_empty       = 'b0;   
               assign p2_cmd_full        = 'b0;   
               assign mig_p5_en          = 'b0; 
               assign mig_p5_wr_data     = 'b0; 
               assign mig_p5_wr_mask     = 'b0; 
               assign mig_p4_en          = 'b0; 

                assign mig_p4_clk        = 'b0; 
                assign mig_p5_clk        = 'b0; 

                assign p2_rd_data        =   'b0;   
                assign p2_wr_count       =   'b0;   
                assign p2_rd_count       =   'b0;   
                assign p2_wr_empty       =   'b0;   
                assign p2_wr_full        =   'b0;   
                assign p2_wr_error       =   'b0;   
                assign p2_wr_underrun    =   'b0;   
                assign p2_rd_overflow    =   'b0;     
                assign p2_rd_error       =   'b0;   
                assign p2_rd_full        =   'b0;   
                assign p2_rd_empty       =   'b0;   

       end 
 

              // MCB's port 1,3,5 is not used in this Config mode
               assign mig_p1_arb_en      =      1'b0;
               assign mig_p1_cmd_clk     =      1'b0;
               assign mig_p1_cmd_en      =      1'b0;
               assign mig_p1_cmd_ra      =      15'd0;
               assign mig_p1_cmd_ba      =      3'd0;
               assign mig_p1_cmd_ca      =      12'd0;
               
               assign mig_p1_cmd_instr   =      3'd0;
               assign mig_p1_cmd_bl      =      6'd0;
                
               assign mig_p3_arb_en    =      1'b0;
               assign mig_p3_cmd_clk     =      1'b0;
               assign mig_p3_cmd_en      =      1'b0;
               assign mig_p3_cmd_ra      =      15'd0;
               assign mig_p3_cmd_ba      =      3'd0;
               assign mig_p3_cmd_ca      =      12'd0;
               
               assign mig_p3_cmd_instr   =      3'd0;
               assign mig_p3_cmd_bl      =      6'd0;

               assign mig_p5_arb_en    =      1'b0;
               assign mig_p5_cmd_clk     =      1'b0;
               assign mig_p5_cmd_en      =      1'b0;
               assign mig_p5_cmd_ra      =      15'd0;
               assign mig_p5_cmd_ba      =      3'd0;
               assign mig_p5_cmd_ca      =      12'd0;
               
               assign mig_p5_cmd_instr   =      3'd0;
               assign mig_p5_cmd_bl      =      6'd0;
 


end else if(C_PORT_CONFIG == "B64_B64" ) begin : u_config_4

               // Inputs from Application CMD Port

                 if (C_PORT_ENABLE[0] == 1'b1)
                  begin
               
                       assign mig_p0_arb_en      =      p0_arb_en ;
                       assign mig_p1_arb_en      =      p0_arb_en ;
                       
                       assign mig_p0_cmd_clk     =      p0_cmd_clk  ;
                       assign mig_p0_cmd_en      =      p0_cmd_en   ;
                       assign mig_p0_cmd_ra      =      p0_cmd_ra  ;
                       assign mig_p0_cmd_ba      =      p0_cmd_ba   ;
                       assign mig_p0_cmd_ca      =      p0_cmd_ca  ;
                       assign mig_p0_cmd_instr   =      p0_cmd_instr;
                       assign mig_p0_cmd_bl      =       {(p0_cmd_instr[2] | p0_cmd_bl[5]),p0_cmd_bl[4:0]}   ;


                        assign mig_p0_wr_clk   = p0_wr_clk;
                        assign mig_p0_rd_clk   = p0_rd_clk;
                        assign mig_p1_wr_clk   = p0_wr_clk;
                        assign mig_p1_rd_clk   = p0_rd_clk;
                        
                        if (C_USR_INTERFACE_MODE == "AXI")
                           assign mig_p0_wr_en    = p0_wr_en ;
                        else
                           assign mig_p0_wr_en    = p0_wr_en & !p0_wr_full;

                        if (C_USR_INTERFACE_MODE == "AXI")
                           assign mig_p1_wr_en    = p0_wr_en ;
                        else
                           assign mig_p1_wr_en    = p0_wr_en & !p0_wr_full;
                        
                        
                        assign mig_p0_wr_data  = p0_wr_data[31:0];
                        assign mig_p0_wr_mask  = p0_wr_mask[3:0];
                        assign mig_p1_wr_data  = p0_wr_data[63 : 32];
                        assign mig_p1_wr_mask  = p0_wr_mask[7 : 4];    


                        if (C_USR_INTERFACE_MODE == "AXI")
                           assign mig_p0_rd_en    = p0_rd_en ;
                        else
                           assign mig_p0_rd_en    = p0_rd_en & !p0_rd_empty;

                        if (C_USR_INTERFACE_MODE == "AXI")
                           assign mig_p1_rd_en    = p0_rd_en ;
                        else
                           assign mig_p1_rd_en    = p0_rd_en & !p0_rd_empty;
                        
                        assign p0_rd_data     = {mig_p1_rd_data , mig_p0_rd_data};
                        
                        assign p0_cmd_empty   =     mig_p0_cmd_empty ;
                        assign p0_cmd_full    =     mig_p0_cmd_full  ;
                        assign p0_wr_empty    = mig_p1_wr_empty;      
                        assign p0_wr_full    = mig_p1_wr_full;
                        assign p0_wr_error    = mig_p1_wr_error | mig_p0_wr_error; 
                        assign p0_wr_count    = mig_p1_wr_count;
                        assign p0_rd_count    = mig_p1_rd_count;
                        assign p0_wr_underrun = mig_p1_wr_underrun | mig_p0_wr_underrun; 
                        assign p0_rd_overflow = mig_p1_rd_overflow | mig_p0_rd_overflow; 
                        assign p0_rd_error    = mig_p1_rd_error | mig_p0_rd_error; 
                        assign p0_rd_full     = mig_p1_rd_full;
                        assign p0_rd_empty    = mig_p1_rd_empty;
                       
                       
                 end else
                 begin
                       assign mig_p0_arb_en      =      'b0;
                       assign mig_p0_cmd_clk     =      'b0;
                       assign mig_p0_cmd_en      =      'b0;
                       assign mig_p0_cmd_ra      =      'b0;
                       assign mig_p0_cmd_ba      =      'b0;
                       assign mig_p0_cmd_ca      =      'b0;
                       assign mig_p0_cmd_instr   =      'b0;
                       assign mig_p0_cmd_bl      =      'b0;

                        assign mig_p0_wr_clk   = 'b0;
                        assign mig_p0_rd_clk   = 'b0;
                        assign mig_p1_wr_clk   = 'b0;
                        assign mig_p1_rd_clk   = 'b0;
                        assign mig_p0_wr_en    = 'b0;
                        assign mig_p1_wr_en    = 'b0;
                        assign mig_p0_wr_data  = 'b0;
                        assign mig_p0_wr_mask  = 'b0;
                        assign mig_p1_wr_data  = 'b0;
                        assign mig_p1_wr_mask  = 'b0;            
                   //     assign mig_p1_wr_en    = 'b0;
                        assign mig_p0_rd_en    = 'b0;
                        assign mig_p1_rd_en    = 'b0;
                        assign p0_rd_data     = 'b0;


                        assign p0_cmd_empty   = 'b0;
                        assign p0_cmd_full    = 'b0;
                        assign p0_wr_empty    = 'b0;
                        assign p0_wr_full     = 'b0;
                        assign p0_wr_error    = 'b0;
                        assign p0_wr_count    = 'b0;
                        assign p0_rd_count    = 'b0;
                        assign p0_wr_underrun = 'b0;  
                        assign p0_rd_overflow = 'b0;
                        assign p0_rd_error    = 'b0;
                        assign p0_rd_full     = 'b0;
                        assign p0_rd_empty    = 'b0;
                 
                 
                 end

      

                 if (C_PORT_ENABLE[1] == 1'b1)
                 begin

                       assign mig_p2_arb_en      =      p1_arb_en ;
                       
                       assign mig_p2_cmd_clk     =      p1_cmd_clk  ;
                       assign mig_p2_cmd_en      =      p1_cmd_en   ;
                       assign mig_p2_cmd_ra      =      p1_cmd_ra  ;
                       assign mig_p2_cmd_ba      =      p1_cmd_ba   ;
                       assign mig_p2_cmd_ca      =      p1_cmd_ca  ;
                       assign mig_p2_cmd_instr   =      p1_cmd_instr;
                       assign mig_p2_cmd_bl      =      {(p1_cmd_instr[2] | p1_cmd_bl[5]),p1_cmd_bl[4:0]}  ;


                        assign mig_p2_clk     = p1_rd_clk;
                        assign mig_p3_clk     = p1_wr_clk;
                        assign mig_p4_clk     = p1_rd_clk;
                        assign mig_p5_clk     = p1_wr_clk;
                         
                        
                        if (C_USR_INTERFACE_MODE == "AXI")
                           assign mig_p3_en    = p1_wr_en ;
                        else
                           assign mig_p3_en    = p1_wr_en & !p1_wr_full;

                        if (C_USR_INTERFACE_MODE == "AXI")
                           assign mig_p5_en    = p1_wr_en ;
                        else
                           assign mig_p5_en    = p1_wr_en & !p1_wr_full;
                        


                        
                        
                        assign mig_p3_wr_data  = p1_wr_data[31:0];
                        assign mig_p3_wr_mask  = p1_wr_mask[3:0];
                        assign mig_p5_wr_data  = p1_wr_data[63 : 32];
                        assign mig_p5_wr_mask  = p1_wr_mask[7 : 4];                       

                        if (C_USR_INTERFACE_MODE == "AXI")
                           assign mig_p2_en    = p1_rd_en ;
                        else
                           assign mig_p2_en    = p1_rd_en & !p1_rd_empty;

                        if (C_USR_INTERFACE_MODE == "AXI")
                           assign mig_p4_en    = p1_rd_en ;
                        else
                           assign mig_p4_en    = p1_rd_en & !p1_rd_empty;


                        assign p1_cmd_empty       =      mig_p2_cmd_empty ;  
                        assign p1_cmd_full        =      mig_p2_cmd_full  ;

                        assign p1_wr_count    = mig_p5_count;
                        assign p1_rd_count    = mig_p4_count;
                        assign p1_wr_full    = mig_p5_full;
                        assign p1_wr_error    = mig_p5_error | mig_p5_error;
                        assign p1_wr_empty    = mig_p5_empty;
                        assign p1_wr_underrun = mig_p3_underrun | mig_p5_underrun;
                        assign p1_rd_overflow = mig_p4_overflow;
                        assign p1_rd_error    = mig_p4_error;
                        assign p1_rd_full     = mig_p4_full;
                        assign p1_rd_empty    = mig_p4_empty;

                        assign p1_rd_data     = {mig_p4_rd_data , mig_p2_rd_data};
                       
                       
                 end else
                 begin
                       assign mig_p2_arb_en      = 'b0;
                   //    assign mig_p3_arb_en      = 'b0;
                  //     assign mig_p4_arb_en      = 'b0;
                  //     assign mig_p5_arb_en      = 'b0;
                       
                       assign mig_p2_cmd_clk     = 'b0;
                       assign mig_p2_cmd_en      = 'b0;
                       assign mig_p2_cmd_ra      = 'b0;
                       assign mig_p2_cmd_ba      = 'b0;
                       assign mig_p2_cmd_ca      = 'b0;
                       assign mig_p2_cmd_instr   = 'b0;
                       assign mig_p2_cmd_bl      = 'b0;
                       assign mig_p2_clk      = 'b0;
                       assign mig_p3_clk      = 'b0;
                       assign mig_p4_clk      = 'b0;
                       assign mig_p5_clk      = 'b0;
                       assign mig_p3_en       = 'b0;
                       assign mig_p5_en       = 'b0;
                       assign mig_p3_wr_data  = 'b0;
                       assign mig_p3_wr_mask  = 'b0;
                       assign mig_p5_wr_data  = 'b0;
                       assign mig_p5_wr_mask  = 'b0; 
                       assign mig_p2_en    = 'b0;
                       assign mig_p4_en    = 'b0;
                       assign p1_cmd_empty    = 'b0;  
                       assign p1_cmd_full     = 'b0;  

                       assign p1_wr_count    = 'b0;
                       assign p1_rd_count    = 'b0;
                       assign p1_wr_full     = 'b0;
                       assign p1_wr_error    = 'b0;
                       assign p1_wr_empty    = 'b0;
                       assign p1_wr_underrun = 'b0;
                       assign p1_rd_overflow = 'b0;
                       assign p1_rd_error    = 'b0; 
                       assign p1_rd_full     = 'b0; 
                       assign p1_rd_empty    = 'b0; 
                       assign p1_rd_data     = 'b0;
                       
                 end               
                
                  // unused MCB's signals in this configuration
                       assign mig_p3_arb_en      =      1'b0;
                       assign mig_p4_arb_en      =      1'b0;
                       assign mig_p5_arb_en      =      1'b0;
                       
                       assign mig_p3_cmd_clk     =      1'b0;
                       assign mig_p3_cmd_en      =      1'b0;
                       assign mig_p3_cmd_ra      =      15'd0;
                       assign mig_p3_cmd_ba      =      3'd0;
                       assign mig_p3_cmd_ca      =      12'd0;
                       assign mig_p3_cmd_instr   =      3'd0;

                       assign mig_p4_cmd_clk     =      1'b0;
                       assign mig_p4_cmd_en      =      1'b0;
                       assign mig_p4_cmd_ra      =      15'd0;
                       assign mig_p4_cmd_ba      =      3'd0;
                       assign mig_p4_cmd_ca      =      12'd0;
                       assign mig_p4_cmd_instr   =      3'd0;
                       assign mig_p4_cmd_bl      =      6'd0;

                       assign mig_p5_cmd_clk     =      1'b0;
                       assign mig_p5_cmd_en      =      1'b0;
                       assign mig_p5_cmd_ra      =      15'd0;
                       assign mig_p5_cmd_ba      =      3'd0;
                       assign mig_p5_cmd_ca      =      12'd0;                       
                       assign mig_p5_cmd_instr   =      3'd0;
                       assign mig_p5_cmd_bl      =      6'd0;

                
                

  end else if(C_PORT_CONFIG == "B128" ) begin : u_config_5
//*******************************BEGIN OF CONFIG 5 SIGNALS ********************************     

               // Inputs from Application CMD Port
               
               assign mig_p0_arb_en      =  p0_arb_en ;
               assign mig_p0_cmd_clk     =  p0_cmd_clk  ;
               assign mig_p0_cmd_en      =  p0_cmd_en   ;
               assign mig_p0_cmd_ra      =  p0_cmd_ra  ;
               assign mig_p0_cmd_ba      =  p0_cmd_ba   ;
               assign mig_p0_cmd_ca      =  p0_cmd_ca  ;
               assign mig_p0_cmd_instr   =  p0_cmd_instr;
               assign mig_p0_cmd_bl      =   {(p0_cmd_instr[2] | p0_cmd_bl[5]),p0_cmd_bl[4:0]}   ;
               
               assign p0_cmd_empty       =      mig_p0_cmd_empty ;
               assign p0_cmd_full        =      mig_p0_cmd_full  ;
               
 
 
                // Inputs from Application User Port
                
                assign mig_p0_wr_clk   = p0_wr_clk;
                assign mig_p0_rd_clk   = p0_rd_clk;
                assign mig_p1_wr_clk   = p0_wr_clk;
                assign mig_p1_rd_clk   = p0_rd_clk;
                
                assign mig_p2_clk   = p0_rd_clk;
                assign mig_p3_clk   = p0_wr_clk;
                assign mig_p4_clk   = p0_rd_clk;
                assign mig_p5_clk   = p0_wr_clk;
                
                
                if (C_USR_INTERFACE_MODE == "AXI") begin
                
                   assign mig_p0_wr_en    = p0_wr_en ;
                   assign mig_p1_wr_en    = p0_wr_en ;
                   assign mig_p3_en       = p0_wr_en ;
                   assign mig_p5_en       = p0_wr_en ;
                   end
                else begin
                        
                   assign mig_p0_wr_en    = p0_wr_en & !p0_wr_full;
                   assign mig_p1_wr_en    = p0_wr_en & !p0_wr_full;
                   assign mig_p3_en       = p0_wr_en & !p0_wr_full;
                   assign mig_p5_en       = p0_wr_en & !p0_wr_full;
                end        

                
                
                
                assign mig_p0_wr_data = p0_wr_data[31:0];
                assign mig_p0_wr_mask = p0_wr_mask[3:0];
                assign mig_p1_wr_data = p0_wr_data[63 : 32];
                assign mig_p1_wr_mask = p0_wr_mask[7 : 4];                
                assign mig_p3_wr_data = p0_wr_data[95 : 64];
                assign mig_p3_wr_mask = p0_wr_mask[11 : 8];
                assign mig_p5_wr_data = p0_wr_data[127 : 96];
                assign mig_p5_wr_mask = p0_wr_mask[15 : 12];
                
                if (C_USR_INTERFACE_MODE == "AXI") begin
                    assign mig_p0_rd_en    = p0_rd_en;
                    assign mig_p1_rd_en    = p0_rd_en;
                    assign mig_p2_en       = p0_rd_en;
                    assign mig_p4_en       = p0_rd_en;
                    end
                else begin
                    assign mig_p0_rd_en    = p0_rd_en & !p0_rd_empty;
                    assign mig_p1_rd_en    = p0_rd_en & !p0_rd_empty;
                    assign mig_p2_en       = p0_rd_en & !p0_rd_empty;
                    assign mig_p4_en       = p0_rd_en & !p0_rd_empty;
                end
                
                // outputs to Applications User Port
                assign p0_rd_data     = {mig_p4_rd_data , mig_p2_rd_data , mig_p1_rd_data , mig_p0_rd_data};
                assign p0_rd_empty    = mig_p4_empty;
                assign p0_rd_full     = mig_p4_full;
                assign p0_rd_error    = mig_p0_rd_error | mig_p1_rd_error | mig_p2_error | mig_p4_error;  
                assign p0_rd_overflow    = mig_p0_rd_overflow | mig_p1_rd_overflow | mig_p2_overflow | mig_p4_overflow; 

                assign p0_wr_underrun    = mig_p0_wr_underrun | mig_p1_wr_underrun | mig_p3_underrun | mig_p5_underrun;      
                assign p0_wr_empty    = mig_p5_empty;
                assign p0_wr_full     = mig_p5_full;
                assign p0_wr_error    = mig_p0_wr_error | mig_p1_wr_error | mig_p3_error | mig_p5_error; 
                
                assign p0_wr_count    = mig_p5_count;
                assign p0_rd_count    = mig_p4_count;


               // unused MCB's siganls in this configuration
               
               assign mig_p1_arb_en      =      1'b0;
               assign mig_p1_cmd_clk     =      1'b0;
               assign mig_p1_cmd_en      =      1'b0;
               assign mig_p1_cmd_ra      =      15'd0;
               assign mig_p1_cmd_ba      =      3'd0;
               assign mig_p1_cmd_ca      =      12'd0;
               
               assign mig_p1_cmd_instr   =      3'd0;
               assign mig_p1_cmd_bl      =      6'd0;
               
               assign mig_p2_arb_en    =      1'b0;
               assign mig_p2_cmd_clk     =      1'b0;
               assign mig_p2_cmd_en      =      1'b0;
               assign mig_p2_cmd_ra      =      15'd0;
               assign mig_p2_cmd_ba      =      3'd0;
               assign mig_p2_cmd_ca      =      12'd0;
               
               assign mig_p2_cmd_instr   =      3'd0;
               assign mig_p2_cmd_bl      =      6'd0;
               
               assign mig_p3_arb_en    =      1'b0;
               assign mig_p3_cmd_clk     =      1'b0;
               assign mig_p3_cmd_en      =      1'b0;
               assign mig_p3_cmd_ra      =      15'd0;
               assign mig_p3_cmd_ba      =      3'd0;
               assign mig_p3_cmd_ca      =      12'd0;
               
               assign mig_p3_cmd_instr   =      3'd0;
               assign mig_p3_cmd_bl      =      6'd0;
               
               assign mig_p4_arb_en    =      1'b0;
               assign mig_p4_cmd_clk     =      1'b0;
               assign mig_p4_cmd_en      =      1'b0;
               assign mig_p4_cmd_ra      =      15'd0;
               assign mig_p4_cmd_ba      =      3'd0;
               assign mig_p4_cmd_ca      =      12'd0;
               
               assign mig_p4_cmd_instr   =      3'd0;
               assign mig_p4_cmd_bl      =      6'd0;
               
               assign mig_p5_arb_en    =      1'b0;
               assign mig_p5_cmd_clk     =      1'b0;
               assign mig_p5_cmd_en      =      1'b0;
               assign mig_p5_cmd_ra      =      15'd0;
               assign mig_p5_cmd_ba      =      3'd0;
               assign mig_p5_cmd_ca      =      12'd0;
               
               assign mig_p5_cmd_instr   =      3'd0;
               assign mig_p5_cmd_bl      =      6'd0;
                             
//*******************************END OF CONFIG 5 SIGNALS ********************************     
                                
end
endgenerate
                              
   MCB 
   # (         .PORT_CONFIG             (C_PORT_CONFIG),                                    
               .MEM_WIDTH              (C_NUM_DQ_PINS    ),        
               .MEM_TYPE                (C_MEM_TYPE       ), 
               .MEM_BURST_LEN            (C_MEM_BURST_LEN  ),  
               .MEM_ADDR_ORDER           (C_MEM_ADDR_ORDER),               
               .MEM_CAS_LATENCY          (C_MEM_CAS_LATENCY),        
               .MEM_DDR3_CAS_LATENCY      (C_MEM_DDR3_CAS_LATENCY   ),
               .MEM_DDR2_WRT_RECOVERY     (C_MEM_DDR2_WRT_RECOVERY  ),
               .MEM_DDR3_WRT_RECOVERY     (C_MEM_DDR3_WRT_RECOVERY  ),
               .MEM_MOBILE_PA_SR          (C_MEM_MOBILE_PA_SR       ),
               .MEM_DDR1_2_ODS              (C_MEM_DDR1_2_ODS         ),
               .MEM_DDR3_ODS                (C_MEM_DDR3_ODS           ),
               .MEM_DDR2_RTT                (C_MEM_DDR2_RTT           ),
               .MEM_DDR3_RTT                (C_MEM_DDR3_RTT           ),
               .MEM_DDR3_ADD_LATENCY        (C_MEM_DDR3_ADD_LATENCY   ),
               .MEM_DDR2_ADD_LATENCY        (C_MEM_DDR2_ADD_LATENCY   ),
               .MEM_MOBILE_TC_SR            (C_MEM_MOBILE_TC_SR       ),
               .MEM_MDDR_ODS                (C_MEM_MDDR_ODS           ),
               .MEM_DDR2_DIFF_DQS_EN        (C_MEM_DDR2_DIFF_DQS_EN   ),
               .MEM_DDR2_3_PA_SR            (C_MEM_DDR2_3_PA_SR       ),
               .MEM_DDR3_CAS_WR_LATENCY    (C_MEM_DDR3_CAS_WR_LATENCY),
               .MEM_DDR3_AUTO_SR           (C_MEM_DDR3_AUTO_SR       ),
               .MEM_DDR2_3_HIGH_TEMP_SR    (C_MEM_DDR2_3_HIGH_TEMP_SR),
               .MEM_DDR3_DYN_WRT_ODT       (C_MEM_DDR3_DYN_WRT_ODT   ),
               .MEM_RA_SIZE               (C_MEM_ADDR_WIDTH            ),
               .MEM_BA_SIZE               (C_MEM_BANKADDR_WIDTH            ),
               .MEM_CA_SIZE               (C_MEM_NUM_COL_BITS            ),
               .MEM_RAS_VAL               (MEM_RAS_VAL            ),  
               .MEM_RCD_VAL               (MEM_RCD_VAL            ),  
               .MEM_REFI_VAL               (MEM_REFI_VAL           ),  
               .MEM_RFC_VAL               (MEM_RFC_VAL            ),  
               .MEM_RP_VAL                (MEM_RP_VAL             ),  
               .MEM_WR_VAL                (MEM_WR_VAL             ),  
               .MEM_RTP_VAL               (MEM_RTP_VAL            ),  
               .MEM_WTR_VAL               (MEM_WTR_VAL            ),
               .CAL_BYPASS        (C_MC_CALIB_BYPASS),      
               .CAL_RA            (C_MC_CALIBRATION_RA),     
               .CAL_BA            (C_MC_CALIBRATION_BA ),    
               .CAL_CA            (C_MC_CALIBRATION_CA),  
               .CAL_CLK_DIV        (C_MC_CALIBRATION_CLK_DIV),        
               .CAL_DELAY         (C_MC_CALIBRATION_DELAY),
               .ARB_NUM_TIME_SLOTS         (C_ARB_NUM_TIME_SLOTS),
               .ARB_TIME_SLOT_0            (arbtimeslot0 )     ,    
               .ARB_TIME_SLOT_1            (arbtimeslot1 )     ,    
               .ARB_TIME_SLOT_2            (arbtimeslot2 )     ,    
               .ARB_TIME_SLOT_3            (arbtimeslot3 )     ,    
               .ARB_TIME_SLOT_4            (arbtimeslot4 )     ,    
               .ARB_TIME_SLOT_5            (arbtimeslot5 )     ,    
               .ARB_TIME_SLOT_6            (arbtimeslot6 )     ,    
               .ARB_TIME_SLOT_7            (arbtimeslot7 )     ,    
               .ARB_TIME_SLOT_8            (arbtimeslot8 )     ,    
               .ARB_TIME_SLOT_9            (arbtimeslot9 )     ,    
               .ARB_TIME_SLOT_10           (arbtimeslot10)   ,         
               .ARB_TIME_SLOT_11           (arbtimeslot11)            
             )  samc_0                                                
     (                                                              
                                                                    
             // HIGH-SPEED PLL clock interface
             
             .PLLCLK            ({ioclk90,ioclk0}),
             .PLLCE              ({pll_ce_90,pll_ce_0})       ,

             .PLLLOCK       (1'b1),
             
             // DQS CLOCK NETWork interface
             
             .DQSIOIN           (idelay_dqs_ioi_s),
             .DQSIOIP           (idelay_dqs_ioi_m),
             .UDQSIOIN          (idelay_udqs_ioi_s),
             .UDQSIOIP          (idelay_udqs_ioi_m),


               //.DQSPIN    (in_pre_dqsp),
               .DQI       (in_dq),
             // RESETS - GLOBAl & local
             .SYSRST         (MCB_SYSRST ), 
   
            // command port 0
             .P0ARBEN            (mig_p0_arb_en),
             .P0CMDCLK           (mig_p0_cmd_clk),
             .P0CMDEN            (mig_p0_cmd_en),
             .P0CMDRA            (mig_p0_cmd_ra),
             .P0CMDBA            (mig_p0_cmd_ba),
             .P0CMDCA            (mig_p0_cmd_ca),
             
             .P0CMDINSTR         (mig_p0_cmd_instr),
             .P0CMDBL            (mig_p0_cmd_bl),
             .P0CMDEMPTY         (mig_p0_cmd_empty),
             .P0CMDFULL          (mig_p0_cmd_full),
             
             // command port 1 
            
             .P1ARBEN            (mig_p1_arb_en),
             .P1CMDCLK           (mig_p1_cmd_clk),
             .P1CMDEN            (mig_p1_cmd_en),
             .P1CMDRA            (mig_p1_cmd_ra),
             .P1CMDBA            (mig_p1_cmd_ba),
             .P1CMDCA            (mig_p1_cmd_ca),
             
             .P1CMDINSTR         (mig_p1_cmd_instr),
             .P1CMDBL            (mig_p1_cmd_bl),
             .P1CMDEMPTY         (mig_p1_cmd_empty),
             .P1CMDFULL          (mig_p1_cmd_full),

             // command port 2
             
             .P2ARBEN            (mig_p2_arb_en),
             .P2CMDCLK           (mig_p2_cmd_clk),
             .P2CMDEN            (mig_p2_cmd_en),
             .P2CMDRA            (mig_p2_cmd_ra),
             .P2CMDBA            (mig_p2_cmd_ba),
             .P2CMDCA            (mig_p2_cmd_ca),
             
             .P2CMDINSTR         (mig_p2_cmd_instr),
             .P2CMDBL            (mig_p2_cmd_bl),
             .P2CMDEMPTY         (mig_p2_cmd_empty),
             .P2CMDFULL          (mig_p2_cmd_full),

             // command port 3
             
             .P3ARBEN            (mig_p3_arb_en),
             .P3CMDCLK           (mig_p3_cmd_clk),
             .P3CMDEN            (mig_p3_cmd_en),
             .P3CMDRA            (mig_p3_cmd_ra),
             .P3CMDBA            (mig_p3_cmd_ba),
             .P3CMDCA            (mig_p3_cmd_ca),
                               
             .P3CMDINSTR         (mig_p3_cmd_instr),
             .P3CMDBL            (mig_p3_cmd_bl),
             .P3CMDEMPTY         (mig_p3_cmd_empty),
             .P3CMDFULL          (mig_p3_cmd_full),

             // command port 4  // don't care in config 2
             
             .P4ARBEN            (mig_p4_arb_en),
             .P4CMDCLK           (mig_p4_cmd_clk),
             .P4CMDEN            (mig_p4_cmd_en),
             .P4CMDRA            (mig_p4_cmd_ra),
             .P4CMDBA            (mig_p4_cmd_ba),
             .P4CMDCA            (mig_p4_cmd_ca),
                               
             .P4CMDINSTR         (mig_p4_cmd_instr),
             .P4CMDBL            (mig_p4_cmd_bl),
             .P4CMDEMPTY         (mig_p4_cmd_empty),
             .P4CMDFULL          (mig_p4_cmd_full),

             // command port 5 // don't care in config 2
             
             .P5ARBEN            (mig_p5_arb_en),
             .P5CMDCLK           (mig_p5_cmd_clk),
             .P5CMDEN            (mig_p5_cmd_en),
             .P5CMDRA            (mig_p5_cmd_ra),
             .P5CMDBA            (mig_p5_cmd_ba),
             .P5CMDCA            (mig_p5_cmd_ca),
                               
             .P5CMDINSTR         (mig_p5_cmd_instr),
             .P5CMDBL            (mig_p5_cmd_bl),
             .P5CMDEMPTY         (mig_p5_cmd_empty),
             .P5CMDFULL          (mig_p5_cmd_full),

              
             // IOI & IOB SIGNals/tristate interface
             
             .DQIOWEN0        (dqIO_w_en_0),
             .DQSIOWEN90P     (dqsIO_w_en_90_p),
             .DQSIOWEN90N     (dqsIO_w_en_90_n),
             
             
             // IOB MEMORY INTerface signals
             .ADDR         (address_90),  
             .BA           (ba_90 ),      
             .RAS         (ras_90 ),     
             .CAS         (cas_90 ),     
             .WE          (we_90  ),     
             .CKE          (cke_90 ),     
             .ODT          (odt_90 ),     
             .RST          (rst_90 ),     
             
             // CALIBRATION DRP interface
             .IOIDRPCLK           (ioi_drp_clk    ),
             .IOIDRPADDR          (ioi_drp_addr   ),
             .IOIDRPSDO           (ioi_drp_sdo    ), 
             .IOIDRPSDI           (ioi_drp_sdi    ), 
             .IOIDRPCS            (ioi_drp_cs     ),
             .IOIDRPADD           (ioi_drp_add    ), 
             .IOIDRPBROADCAST     (ioi_drp_broadcast  ),
             .IOIDRPTRAIN         (ioi_drp_train    ),
             .IOIDRPUPDATE         (ioi_drp_update) ,
             
             // CALIBRATION DAtacapture interface
             //SPECIAL COMMANDs
             .RECAL               (mcb_recal    ), 
             .UIREAD               (mcb_ui_read),
             .UIADD                (mcb_ui_add)    ,
             .UICS                 (mcb_ui_cs)     ,
             .UICLK                (mcb_ui_clk)    ,
             .UISDI                (mcb_ui_sdi)    ,
             .UIADDR               (mcb_ui_addr)   ,
             .UIBROADCAST          (mcb_ui_broadcast) ,
             .UIDRPUPDATE          (mcb_ui_drp_update) ,
             .UIDONECAL            (mcb_ui_done_cal)   ,
             .UICMD                (mcb_ui_cmd),
             .UICMDIN              (mcb_ui_cmd_in)     ,
             .UICMDEN              (mcb_ui_cmd_en)     ,
             .UIDQCOUNT            (mcb_ui_dqcount)    ,
             .UIDQLOWERDEC          (mcb_ui_dq_lower_dec),
             .UIDQLOWERINC          (mcb_ui_dq_lower_inc),
             .UIDQUPPERDEC          (mcb_ui_dq_upper_dec),
             .UIDQUPPERINC          (mcb_ui_dq_upper_inc),
             .UIUDQSDEC          (mcb_ui_udqs_dec),
             .UIUDQSINC          (mcb_ui_udqs_inc),
             .UILDQSDEC          (mcb_ui_ldqs_dec),
             .UILDQSINC          (mcb_ui_ldqs_inc),
             .UODATA             (uo_data),
             .UODATAVALID          (uo_data_valid),
             .UODONECAL            (hard_done_cal)  ,
             .UOCMDREADYIN         (uo_cmd_ready_in),
             .UOREFRSHFLAG         (uo_refrsh_flag),
             .UOCALSTART           (uo_cal_start)   ,
             .UOSDO                (uo_sdo),
                                                   
             //CONTROL SIGNALS
              .STATUS                    (status),
              .SELFREFRESHENTER          (selfrefresh_mcb_enter  ),
              .SELFREFRESHMODE           (selfrefresh_mcb_mode ),  
//////////////////////////////  //////////////////
//MUIs
////////////////////////////////////////////////
            
              .P0RDDATA         ( mig_p0_rd_data[31:0]    ), 
              .P1RDDATA         ( mig_p1_rd_data[31:0]   ), 
              .P2RDDATA         ( mig_p2_rd_data[31:0]  ), 
              .P3RDDATA         ( mig_p3_rd_data[31:0]       ),
              .P4RDDATA         ( mig_p4_rd_data[31:0] ), 
              .P5RDDATA         ( mig_p5_rd_data[31:0]        ), 
              .LDMN             ( dqnlm       ),
              .UDMN             ( dqnum       ),
              .DQON             ( dqo_n       ),
              .DQOP             ( dqo_p       ),
              .LDMP             ( dqplm       ),
              .UDMP             ( dqpum       ),
              
              .P0RDCOUNT          ( mig_p0_rd_count ), 
              .P0WRCOUNT          ( mig_p0_wr_count ),
              .P1RDCOUNT          ( mig_p1_rd_count ), 
              .P1WRCOUNT          ( mig_p1_wr_count ), 
              .P2COUNT           ( mig_p2_count  ), 
              .P3COUNT           ( mig_p3_count  ),
              .P4COUNT           ( mig_p4_count  ),
              .P5COUNT           ( mig_p5_count  ),
              
              // NEW ADDED FIFo status siganls
              // MIG USER PORT 0
              .P0RDEMPTY        ( mig_p0_rd_empty), 
              .P0RDFULL         ( mig_p0_rd_full), 
              .P0RDOVERFLOW     ( mig_p0_rd_overflow), 
              .P0WREMPTY        ( mig_p0_wr_empty), 
              .P0WRFULL         ( mig_p0_wr_full), 
              .P0WRUNDERRUN     ( mig_p0_wr_underrun), 
              // MIG USER PORT 1
              .P1RDEMPTY        ( mig_p1_rd_empty), 
              .P1RDFULL         ( mig_p1_rd_full), 
              .P1RDOVERFLOW     ( mig_p1_rd_overflow),  
              .P1WREMPTY        ( mig_p1_wr_empty), 
              .P1WRFULL         ( mig_p1_wr_full), 
              .P1WRUNDERRUN     ( mig_p1_wr_underrun),  
              
              // MIG USER PORT 2
              .P2EMPTY          ( mig_p2_empty),
              .P2FULL           ( mig_p2_full),
              .P2RDOVERFLOW        ( mig_p2_overflow), 
              .P2WRUNDERRUN       ( mig_p2_underrun), 
              
              .P3EMPTY          ( mig_p3_empty ),
              .P3FULL           ( mig_p3_full ),
              .P3RDOVERFLOW        ( mig_p3_overflow), 
              .P3WRUNDERRUN       ( mig_p3_underrun ),
              // MIG USER PORT 3
              .P4EMPTY          ( mig_p4_empty),
              .P4FULL           ( mig_p4_full),
              .P4RDOVERFLOW        ( mig_p4_overflow), 
              .P4WRUNDERRUN       ( mig_p4_underrun), 
              
              .P5EMPTY          ( mig_p5_empty ),
              .P5FULL           ( mig_p5_full ),
              .P5RDOVERFLOW        ( mig_p5_overflow), 
              .P5WRUNDERRUN       ( mig_p5_underrun), 
              
              ////////////////////////////////////////////////////////-
              .P0WREN        ( mig_p0_wr_en), 
              .P0RDEN        ( mig_p0_rd_en),                         
              .P1WREN        ( mig_p1_wr_en), 
              .P1RDEN        ( mig_p1_rd_en), 
              .P2EN          ( mig_p2_en),
              .P3EN          ( mig_p3_en), 
              .P4EN          ( mig_p4_en), 
              .P5EN          ( mig_p5_en), 
              // WRITE  MASK BIts connection
              .P0RWRMASK        ( mig_p0_wr_mask[3:0]), 
              .P1RWRMASK        ( mig_p1_wr_mask[3:0]),
              .P2WRMASK        ( mig_p2_wr_mask[3:0]),
              .P3WRMASK        ( mig_p3_wr_mask[3:0]), 
              .P4WRMASK        ( mig_p4_wr_mask[3:0]),
              .P5WRMASK        ( mig_p5_wr_mask[3:0]), 
              // DATA WRITE COnnection
              .P0WRDATA      ( mig_p0_wr_data[31:0]), 
              .P1WRDATA      ( mig_p1_wr_data[31:0]),
              .P2WRDATA      ( mig_p2_wr_data[31:0]),
              .P3WRDATA      ( mig_p3_wr_data[31:0]), 
              .P4WRDATA      ( mig_p4_wr_data[31:0]),
              .P5WRDATA      ( mig_p5_wr_data[31:0]),  
              
              .P0WRERROR     (mig_p0_wr_error),
              .P1WRERROR     (mig_p1_wr_error),
              .P0RDERROR     (mig_p0_rd_error),
              .P1RDERROR     (mig_p1_rd_error),
              
              .P2ERROR       (mig_p2_error),
              .P3ERROR       (mig_p3_error),
              .P4ERROR       (mig_p4_error),
              .P5ERROR       (mig_p5_error),
              
              //  USER SIDE DAta ports clock
              //  128 BITS CONnections
              .P0WRCLK            ( mig_p0_wr_clk  ),
              .P1WRCLK            ( mig_p1_wr_clk  ),
              .P0RDCLK            ( mig_p0_rd_clk  ),
              .P1RDCLK            ( mig_p1_rd_clk  ),
              .P2CLK              ( mig_p2_clk  ),
              .P3CLK              ( mig_p3_clk  ),
              .P4CLK              ( mig_p4_clk  ),
              .P5CLK              ( mig_p5_clk) 
              ////////////////////////////////////////////////////////
              // TST MODE PINS
              
                            
            
              );
             

//////////////////////////////////////////////////////
// Input Termination Calibration
//////////////////////////////////////////////////////
wire                          DONE_SOFTANDHARD_CAL;

assign uo_done_cal = (   C_CALIB_SOFT_IP == "TRUE") ? DONE_SOFTANDHARD_CAL : hard_done_cal;
generate   
if ( C_CALIB_SOFT_IP == "TRUE") begin: gen_term_calib


  

 
mcb_soft_calibration_top  # (

    .C_MEM_TZQINIT_MAXCNT (C_MEM_TZQINIT_MAXCNT),
    .C_MC_CALIBRATION_MODE(C_MC_CALIBRATION_MODE),
    .SKIP_IN_TERM_CAL     (C_SKIP_IN_TERM_CAL),
    .SKIP_DYNAMIC_CAL     (C_SKIP_DYNAMIC_CAL),
    .SKIP_DYN_IN_TERM     (C_SKIP_DYN_IN_TERM),
    .C_SIMULATION         (C_SIMULATION),
    .C_MEM_TYPE           (C_MEM_TYPE)
        )
  mcb_soft_calibration_top_inst (
    .UI_CLK               (ui_clk),               //Input - global clock to be used for input_term_tuner and IODRP clock
    .RST                  (int_sys_rst),              //Input - reset for input_term_tuner - synchronous for input_term_tuner state machine, asynch for IODRP (sub)controller
    .IOCLK                (ioclk0),               //Input - IOCLK input to the IODRP's
    .DONE_SOFTANDHARD_CAL (DONE_SOFTANDHARD_CAL), // active high flag signals soft calibration of input delays is complete and MCB_UODONECAL is high (MCB hard calib complete)
    .PLL_LOCK             (gated_pll_lock),
    
    .SELFREFRESH_REQ      (soft_cal_selfrefresh_req),    // from user app
    .SELFREFRESH_MCB_MODE (selfrefresh_mcb_mode), // from MCB
    .SELFREFRESH_MCB_REQ  (selfrefresh_mcb_enter),// to mcb
    .SELFREFRESH_MODE     (selfrefresh_mode),     // to user app
    
    
    
    .MCB_UIADD            (mcb_ui_add),
    .MCB_UISDI            (mcb_ui_sdi),
    .MCB_UOSDO            (uo_sdo),               // from MCB's UOSDO port (User output SDO)
    .MCB_UODONECAL        (hard_done_cal),        // input for when MCB hard calibration process is complete
    .MCB_UOREFRSHFLAG     (uo_refrsh_flag),       //high during refresh cycle and time when MCB is innactive
    .MCB_UICS             (mcb_ui_cs),            // to MCB's UICS port (User Input CS)
    .MCB_UIDRPUPDATE      (mcb_ui_drp_update),    // MCB's UIDRPUPDATE port (gets passed to IODRP2_MCB's MEMUPDATE port: this controls shadow latch used during IODRP2_MCB writes).  Currently just trasnparent
    .MCB_UIBROADCAST      (mcb_ui_broadcast),     // to MCB's UIBROADCAST port (User Input BROADCAST - gets passed to IODRP2_MCB's BKST port)
    .MCB_UIADDR           (mcb_ui_addr),          //to MCB's UIADDR port (gets passed to IODRP2_MCB's AUXADDR port
    .MCB_UICMDEN          (mcb_ui_cmd_en),        //set to take control of UI interface - removes control from internal calib block
    .MCB_UIDONECAL        (mcb_ui_done_cal),      //
    .MCB_UIDQLOWERDEC     (mcb_ui_dq_lower_dec),
    .MCB_UIDQLOWERINC     (mcb_ui_dq_lower_inc),
    .MCB_UIDQUPPERDEC     (mcb_ui_dq_upper_dec),
    .MCB_UIDQUPPERINC     (mcb_ui_dq_upper_inc),
    .MCB_UILDQSDEC        (mcb_ui_ldqs_dec),
    .MCB_UILDQSINC        (mcb_ui_ldqs_inc),
    .MCB_UIREAD           (mcb_ui_read),          //enables read w/o writing by turning on a SDO->SDI loopback inside the IODRP2_MCBs (doesn't exist in regular IODRP2).  IODRPCTRLR_R_WB becomes don't-care.
    .MCB_UIUDQSDEC        (mcb_ui_udqs_dec),
    .MCB_UIUDQSINC        (mcb_ui_udqs_inc),
    .MCB_RECAL            (mcb_recal),
    .MCB_SYSRST           (MCB_SYSRST),           //drives the MCB's SYSRST pin - the main reset for MCB
    .MCB_UICMD            (mcb_ui_cmd),
    .MCB_UICMDIN          (mcb_ui_cmd_in),
    .MCB_UIDQCOUNT        (mcb_ui_dqcount),
    .MCB_UODATA           (uo_data),
    .MCB_UODATAVALID      (uo_data_valid),
    .MCB_UOCMDREADY       (uo_cmd_ready_in),
    .MCB_UO_CAL_START     (uo_cal_start),
    .RZQ_Pin              (rzq),
    .ZIO_Pin              (zio),
    .CKE_Train            (cke_train)
    
     );






        assign mcb_ui_clk = ui_clk;
end
endgenerate

generate   
if ( C_CALIB_SOFT_IP != "TRUE") begin: gen_no_term_calib   
    assign DONE_SOFTANDHARD_CAL = 1'b0;
    assign MCB_SYSRST = int_sys_rst | (~wait_200us_counter[15]);
    assign mcb_recal = calib_recal;
    assign mcb_ui_read = ui_read;
    assign mcb_ui_add = ui_add;
    assign mcb_ui_cs = ui_cs;  
    assign mcb_ui_clk = ui_clk;
    assign mcb_ui_sdi = ui_sdi;
    assign mcb_ui_addr = ui_addr;
    assign mcb_ui_broadcast = ui_broadcast;
    assign mcb_ui_drp_update = ui_drp_update;
    assign mcb_ui_done_cal = ui_done_cal;
    assign mcb_ui_cmd = ui_cmd;
    assign mcb_ui_cmd_in = ui_cmd_in;
    assign mcb_ui_cmd_en = ui_cmd_en;
    assign mcb_ui_dq_lower_dec = ui_dq_lower_dec;
    assign mcb_ui_dq_lower_inc = ui_dq_lower_inc;
    assign mcb_ui_dq_upper_dec = ui_dq_upper_dec;
    assign mcb_ui_dq_upper_inc = ui_dq_upper_inc;
    assign mcb_ui_udqs_inc = ui_udqs_inc;
    assign mcb_ui_udqs_dec = ui_udqs_dec;
    assign mcb_ui_ldqs_inc = ui_ldqs_inc;
    assign mcb_ui_ldqs_dec = ui_ldqs_dec; 
    assign selfrefresh_mode = 1'b0;
 
    if (C_SIMULATION == "FALSE") begin: init_sequence
        always @ (posedge ui_clk, posedge int_sys_rst)
        begin
            if (int_sys_rst)
                wait_200us_counter <= 'b0;
            else 
               if (wait_200us_counter[15])  // UI_CLK maximum is up to 100 MHz.
                   wait_200us_counter <= wait_200us_counter                        ;
               else
                   wait_200us_counter <= wait_200us_counter + 1'b1;
        end 
    end 
    else begin: init_sequence_skip
// synthesis translate_off        
        initial
        begin
           wait_200us_counter = 16'hFFFF;
           $display("The 200 us wait period required before CKE goes active has been skipped in Simulation\n");
        end       
// synthesis translate_on         
    end
   
    
    if( C_MEM_TYPE == "DDR2") begin : gen_cketrain_a

        always @ ( posedge ui_clk)
        begin 
          // When wait_200us_[13] and wait_200us_[14] are both asserted,
          // 200 us wait should have been passed. 
          if (wait_200us_counter[14] && wait_200us_counter[13])
             wait_200us_done_r1 <= 1'b1;
          else
             wait_200us_done_r1 <= 1'b0;
          

          wait_200us_done_r2 <= wait_200us_done_r1;
        end
        
        always @ ( posedge ui_clk, posedge int_sys_rst)
        begin 
        if (int_sys_rst)
           cke_train_reg <= 1'b0;
        else 
           if ( wait_200us_done_r1 && ~wait_200us_done_r2 )
               cke_train_reg <= 1'b1;
           else if ( uo_done_cal)
               cke_train_reg <= 1'b0;
        end
        
        assign cke_train = cke_train_reg;
    end

    if( C_MEM_TYPE != "DDR2") begin : gen_cketrain_b
    
        assign cke_train = 1'b0;
    end        
        
        
end 
endgenerate

//////////////////////////////////////////////////////
//ODDRDES2 instantiations
//////////////////////////////////////////////////////

////////
//ADDR
////////

genvar addr_ioi;
   generate 
      for(addr_ioi = 0; addr_ioi < C_MEM_ADDR_WIDTH; addr_ioi = addr_ioi + 1) begin : gen_addr_oserdes2
OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) ioi_addr_0  
(
  .OQ(ioi_addr[addr_ioi]),
  .SHIFTOUT1(),
  .SHIFTOUT2(),
  .SHIFTOUT3(),
  .SHIFTOUT4(),
  .TQ(t_addr[addr_ioi]),
  .CLK0(ioclk0),
  .CLK1(1'b0),
  .CLKDIV(1'b0),
  .D1(address_90[addr_ioi]),
  .D2(address_90[addr_ioi]),
  .D3(1'b0),
  .D4(1'b0),
  .IOCE(pll_ce_0),
  .OCE(1'b1),
  .RST(int_sys_rst),
  .SHIFTIN1(1'b0),
  .SHIFTIN2(1'b0),
  .SHIFTIN3(1'b0),
  .SHIFTIN4(1'b0),
  .T1(1'b0),
  .T2(1'b0),
  .T3(1'b0),
  .T4(1'b0),
  .TCE(1'b1),
  .TRAIN(1'b0)
    );
 end       
   endgenerate

////////
//BA
////////

genvar ba_ioi;
   generate 
      for(ba_ioi = 0; ba_ioi < C_MEM_BANKADDR_WIDTH; ba_ioi = ba_ioi + 1) begin : gen_ba_oserdes2
OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) ioi_ba_0  
(
  .OQ       (ioi_ba[ba_ioi]),
  .SHIFTOUT1 (),
  .SHIFTOUT2 (),
  .SHIFTOUT3 (),
  .SHIFTOUT4 (),
  .TQ       (t_ba[ba_ioi]),
  .CLK0     (ioclk0),
  .CLK1 (1'b0),
  .CLKDIV (1'b0),
  .D1       (ba_90[ba_ioi]),
  .D2       (ba_90[ba_ioi]),
  .D3 (1'b0),
  .D4 (1'b0),
  .IOCE     (pll_ce_0),
  .OCE      (1'b1),
  .RST      (int_sys_rst),
  .SHIFTIN1 (1'b0),
  .SHIFTIN2 (1'b0),
  .SHIFTIN3 (1'b0),
  .SHIFTIN4 (1'b0),
  .T1(1'b0),
  .T2(1'b0),
  .T3(1'b0),
  .T4(1'b0),
  .TCE(1'b1),
  .TRAIN    (1'b0)
    );
 end       
   endgenerate

////////
//CAS
////////

OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) ioi_cas_0 
(
  .OQ       (ioi_cas),
  .SHIFTOUT1 (),
  .SHIFTOUT2 (),
  .SHIFTOUT3 (),
  .SHIFTOUT4 (),
  .TQ       (t_cas),
  .CLK0     (ioclk0),
  .CLK1 (1'b0),
  .CLKDIV (1'b0),
  .D1       (cas_90),
  .D2       (cas_90),
  .D3 (1'b0),
  .D4 (1'b0),
  .IOCE     (pll_ce_0),
  .OCE      (1'b1),
  .RST      (int_sys_rst),
  .SHIFTIN1 (1'b0),
  .SHIFTIN2 (1'b0),
  .SHIFTIN3 (1'b0),
  .SHIFTIN4 (1'b0),
  .T1(1'b0),
  .T2(1'b0),
  .T3(1'b0),
  .T4(1'b0),
  .TCE(1'b1),
  .TRAIN    (1'b0)
    );

////////
//CKE
////////

OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2)    ,       // {1..8} 
  .TRAIN_PATTERN (15)
) ioi_cke_0 
(
  .OQ       (ioi_cke),
  .SHIFTOUT1 (),
  .SHIFTOUT2 (),
  .SHIFTOUT3 (),
  .SHIFTOUT4 (),
  .TQ       (t_cke),
  .CLK0     (ioclk0),
  .CLK1 (1'b0),
  .CLKDIV (1'b0),
  .D1       (cke_90),
  .D2       (cke_90),
  .D3 (1'b0),
  .D4 (1'b0),
  .IOCE     (pll_ce_0),
  .OCE      (pll_lock),
  .RST      (1'b0),//int_sys_rst
  .SHIFTIN1 (1'b0),
  .SHIFTIN2 (1'b0),
  .SHIFTIN3 (1'b0),
  .SHIFTIN4 (1'b0),
  .T1(1'b0),
  .T2(1'b0),
  .T3(1'b0),
  .T4(1'b0),
  .TCE(1'b1),
  .TRAIN    (cke_train)
    );

////////
//ODT
////////
generate
if(C_MEM_TYPE == "DDR3" || C_MEM_TYPE == "DDR2" ) begin : gen_ioi_odt

OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) ioi_odt_0 
(
  .OQ       (ioi_odt),
  .SHIFTOUT1 (),
  .SHIFTOUT2 (),
  .SHIFTOUT3 (),
  .SHIFTOUT4 (),
  .TQ       (t_odt),
  .CLK0     (ioclk0),
  .CLK1 (1'b0),
  .CLKDIV (1'b0),
  .D1       (odt_90),
  .D2       (odt_90),
  .D3 (1'b0),
  .D4 (1'b0),
  .IOCE     (pll_ce_0),
  .OCE      (1'b1),
  .RST      (int_sys_rst),
  .SHIFTIN1 (1'b0),
  .SHIFTIN2 (1'b0),
  .SHIFTIN3 (1'b0),
  .SHIFTIN4 (1'b0),
  .T1(1'b0),
  .T2(1'b0),
  .T3(1'b0),
  .T4(1'b0),
  .TCE(1'b1),
  .TRAIN    (1'b0)
    );
end
endgenerate
////////
//RAS
////////

OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) ioi_ras_0 
(
  .OQ       (ioi_ras),
  .SHIFTOUT1 (),
  .SHIFTOUT2 (),
  .SHIFTOUT3 (),
  .SHIFTOUT4 (),
  .TQ       (t_ras),
  .CLK0     (ioclk0),
  .CLK1 (1'b0),
  .CLKDIV (1'b0),
  .D1       (ras_90),
  .D2       (ras_90),
  .D3 (1'b0),
  .D4 (1'b0),
  .IOCE     (pll_ce_0),
  .OCE      (1'b1),
  .RST      (int_sys_rst),
  .SHIFTIN1 (1'b0),
  .SHIFTIN2 (1'b0),
  .SHIFTIN3 (1'b0),
  .SHIFTIN4 (1'b0),
  .T1 (1'b0),
  .T2 (1'b0),
  .T3 (1'b0),
  .T4 (1'b0),
  .TCE (1'b1),
  .TRAIN    (1'b0)
    );

////////
//RST
////////
generate 
if (C_MEM_TYPE == "DDR3"  ) begin : gen_ioi_rst

OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) ioi_rst_0 
(
  .OQ       (ioi_rst),
  .SHIFTOUT1 (),
  .SHIFTOUT2 (),
  .SHIFTOUT3 (),
  .SHIFTOUT4 (),
  .TQ       (t_rst),
  .CLK0     (ioclk0),
  .CLK1 (1'b0),
  .CLKDIV (1'b0),
  .D1       (rst_90),
  .D2       (rst_90),
  .D3 (1'b0),
  .D4 (1'b0),
  .IOCE     (pll_ce_0),
  .OCE      (pll_lock),
  .RST      (int_sys_rst),
  .SHIFTIN1 (1'b0),
  .SHIFTIN2 (1'b0),
  .SHIFTIN3 (1'b0),
  .SHIFTIN4 (1'b0),
  .T1(1'b0),
  .T2(1'b0),
  .T3(1'b0),
  .T4(1'b0),
  .TCE(1'b1),
  .TRAIN    (1'b0)
    );
end
endgenerate
////////
//WE
////////

OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) ioi_we_0 
(
  .OQ       (ioi_we),
  .TQ       (t_we),
  .SHIFTOUT1 (),
  .SHIFTOUT2 (),
  .SHIFTOUT3 (),
  .SHIFTOUT4 (),
  .CLK0     (ioclk0),
  .CLK1 (1'b0),
  .CLKDIV (1'b0),
  .D1       (we_90),
  .D2       (we_90),
  .D3 (1'b0),
  .D4 (1'b0),
  .IOCE     (pll_ce_0),
  .OCE      (1'b1),
  .RST      (int_sys_rst),
  .SHIFTIN1 (1'b0),
  .SHIFTIN2 (1'b0),
  .SHIFTIN3 (1'b0),
  .SHIFTIN4 (1'b0),
  .T1(1'b0),
  .T2(1'b0),
  .T3(1'b0),
  .T4(1'b0),
  .TCE(1'b1),
  .TRAIN    (1'b0)
);

////////
//CK
////////

OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) ioi_ck_0 
(
  .OQ       (ioi_ck),
  .SHIFTOUT1(),
  .SHIFTOUT2(),
  .SHIFTOUT3(),
  .SHIFTOUT4(),
  .TQ       (t_ck),
  .CLK0     (ioclk0),
  .CLK1(1'b0),
  .CLKDIV(1'b0),
  .D1       (1'b0),
  .D2       (1'b1),
  .D3(1'b0),
  .D4(1'b0),
  .IOCE     (pll_ce_0),
  .OCE      (pll_lock),

  .RST      (1'b0),//int_sys_rst
  .SHIFTIN1(1'b0),
  .SHIFTIN2(1'b0),
  .SHIFTIN3 (1'b0),
  .SHIFTIN4 (1'b0),
  .T1(1'b0),
  .T2(1'b0),
  .T3(1'b0),
  .T4(1'b0),
  .TCE(1'b1),
  .TRAIN    (1'b0)
);

////////
//CKN
////////
/*
OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_SLAVE),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) ioi_ckn_0 
(
  .OQ       (ioi_ckn),
  .SHIFTOUT1(),
  .SHIFTOUT2(),
  .SHIFTOUT3(),
  .SHIFTOUT4(),
  .TQ       (t_ckn),
  .CLK0     (ioclk0),
  .CLK1(),
  .CLKDIV(),
  .D1       (1'b1),
  .D2       (1'b0),
  .D3(),
  .D4(),
  .IOCE     (pll_ce_0),
  .OCE      (1'b1),
  .RST      (1'b0),//int_sys_rst
  .SHIFTIN1 (),
  .SHIFTIN2 (),
  .SHIFTIN3(),
  .SHIFTIN4(),
  .T1(1'b0),
  .T2(1'b0),
  .T3(),
  .T4(),
  .TCE(1'b1),
  .TRAIN    (1'b0)
);
*/

////////
//UDM
////////

wire udm_oq;
wire udm_t;
OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) ioi_udm_0 
(
  .OQ       (udm_oq),
  .SHIFTOUT1 (),
  .SHIFTOUT2 (),
  .SHIFTOUT3 (),
  .SHIFTOUT4 (),
  .TQ       (udm_t),
  .CLK0     (ioclk90),
  .CLK1 (1'b0),
  .CLKDIV (1'b0),
  .D1       (dqpum),
  .D2       (dqnum),
  .D3 (1'b0),
  .D4 (1'b0),
  .IOCE     (pll_ce_90),
  .OCE      (1'b1),
  .RST      (int_sys_rst),
  .SHIFTIN1 (1'b0),
  .SHIFTIN2 (1'b0),
  .SHIFTIN3 (1'b0),
  .SHIFTIN4 (1'b0),
  .T1       (dqIO_w_en_0),
  .T2       (dqIO_w_en_0),
  .T3 (1'b0),
  .T4 (1'b0),
  .TCE      (1'b1),
  .TRAIN    (1'b0)
);

////////
//LDM
////////
wire ldm_oq;
wire ldm_t;
OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) ioi_ldm_0 
(
  .OQ       (ldm_oq),
  .SHIFTOUT1 (),
  .SHIFTOUT2 (),
  .SHIFTOUT3 (),
  .SHIFTOUT4 (),
  .TQ       (ldm_t),
  .CLK0     (ioclk90),
  .CLK1 (1'b0),
  .CLKDIV (1'b0),
  .D1       (dqplm),
  .D2       (dqnlm),
  .D3 (1'b0),
  .D4 (1'b0),
  .IOCE     (pll_ce_90),
  .OCE      (1'b1),
  .RST      (int_sys_rst),
  .SHIFTIN1 (1'b0),
  .SHIFTIN2 (1'b0),
  .SHIFTIN3 (1'b0),
  .SHIFTIN4 (1'b0),
  .T1       (dqIO_w_en_0),
  .T2       (dqIO_w_en_0),
  .T3 (1'b0),
  .T4 (1'b0),
  .TCE      (1'b1),
  .TRAIN    (1'b0)
);

////////
//DQ
////////

wire dq_oq [C_NUM_DQ_PINS-1:0];
wire dq_tq [C_NUM_DQ_PINS-1:0];

genvar dq;
generate
      for(dq = 0; dq < C_NUM_DQ_PINS; dq = dq + 1) begin : gen_dq

OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2),           // {1..8} 
  .TRAIN_PATTERN (5)            // {0..15}             
) oserdes2_dq_0 
(
  .OQ       (dq_oq[dq]),
  .SHIFTOUT1 (),
  .SHIFTOUT2 (),
  .SHIFTOUT3 (),
  .SHIFTOUT4 (),
  .TQ       (dq_tq[dq]),
  .CLK0     (ioclk90),
  .CLK1 (1'b0),
  .CLKDIV (1'b0),
  .D1       (dqo_p[dq]),
  .D2       (dqo_n[dq]),
  .D3 (1'b0),
  .D4 (1'b0),
  .IOCE     (pll_ce_90),
  .OCE      (1'b1),
  .RST      (int_sys_rst),
  .SHIFTIN1 (1'b0),
  .SHIFTIN2 (1'b0),
  .SHIFTIN3 (1'b0),
  .SHIFTIN4 (1'b0),
  .T1       (dqIO_w_en_0),
  .T2       (dqIO_w_en_0),
  .T3 (1'b0),
  .T4 (1'b0),
  .TCE      (1'b1),
  .TRAIN    (ioi_drp_train)
);

end
endgenerate

////////
//DQSP
////////

wire dqsp_oq ;
wire dqsp_tq ;

OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) oserdes2_dqsp_0 
(
  .OQ       (dqsp_oq),
  .SHIFTOUT1(),
  .SHIFTOUT2(),
  .SHIFTOUT3(),
  .SHIFTOUT4(),
  .TQ       (dqsp_tq),
  .CLK0     (ioclk0),
  .CLK1(1'b0),
  .CLKDIV(1'b0),
  .D1       (1'b0),
  .D2       (1'b1),
  .D3(1'b0),
  .D4(1'b0),
  .IOCE     (pll_ce_0),
  .OCE      (1'b1),
  .RST      (int_sys_rst),
  .SHIFTIN1(1'b0),
  .SHIFTIN2(1'b0),
  .SHIFTIN3 (1'b0),
  .SHIFTIN4 (1'b0),
  .T1       (dqsIO_w_en_90_n),
  .T2       (dqsIO_w_en_90_p),
  .T3(1'b0),
  .T4(1'b0),
  .TCE      (1'b1),
  .TRAIN    (1'b0)
);

////////
//DQSN
////////

wire dqsn_oq ;
wire dqsn_tq ;



OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_SLAVE),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) oserdes2_dqsn_0 
(
  .OQ       (dqsn_oq),
  .SHIFTOUT1(),
  .SHIFTOUT2(),
  .SHIFTOUT3(),
  .SHIFTOUT4(),
  .TQ       (dqsn_tq),
  .CLK0     (ioclk0),
  .CLK1(1'b0),
  .CLKDIV(1'b0),
  .D1       (1'b1),
  .D2       (1'b0),
  .D3(1'b0),
  .D4(1'b0),
  .IOCE     (pll_ce_0),
  .OCE      (1'b1),
  .RST      (int_sys_rst),
  .SHIFTIN1 (1'b0),
  .SHIFTIN2 (1'b0),
  .SHIFTIN3(1'b0),
  .SHIFTIN4(1'b0),
  .T1       (dqsIO_w_en_90_n),
  .T2       (dqsIO_w_en_90_p),
  .T3(1'b0),
  .T4(1'b0),
  .TCE      (1'b1),
  .TRAIN    (1'b0)
);

////////
//UDQSP
////////

wire udqsp_oq ;
wire udqsp_tq ;


OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_MASTER),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) oserdes2_udqsp_0 
(
  .OQ       (udqsp_oq),
  .SHIFTOUT1(),
  .SHIFTOUT2(),
  .SHIFTOUT3(),
  .SHIFTOUT4(),
  .TQ       (udqsp_tq),
  .CLK0     (ioclk0),
  .CLK1(1'b0),
  .CLKDIV(1'b0),
  .D1       (1'b0),
  .D2       (1'b1),
  .D3(1'b0),
  .D4(1'b0),
  .IOCE     (pll_ce_0),
  .OCE      (1'b1),
  .RST      (int_sys_rst),
  .SHIFTIN1(1'b0),
  .SHIFTIN2(1'b0),
  .SHIFTIN3 (1'b0),
  .SHIFTIN4 (1'b0),
  .T1       (dqsIO_w_en_90_n),
  .T2       (dqsIO_w_en_90_p),
  .T3(1'b0),
  .T4(1'b0),
  .TCE      (1'b1),
  .TRAIN    (1'b0)
);

////////
//UDQSN
////////

wire udqsn_oq ;
wire udqsn_tq ;

OSERDES2 #(
  .BYPASS_GCLK_FF ("TRUE"),
  .DATA_RATE_OQ  (C_OSERDES2_DATA_RATE_OQ),         // SDR, DDR      | Data Rate setting
  .DATA_RATE_OT  (C_OSERDES2_DATA_RATE_OT),         // SDR, DDR, BUF | Tristate Rate setting.
  .OUTPUT_MODE   (C_OSERDES2_OUTPUT_MODE_SE),          // SINGLE_ENDED, DIFFERENTIAL
  .SERDES_MODE   (C_OSERDES2_SERDES_MODE_SLAVE),          // MASTER, SLAVE
  .DATA_WIDTH    (2)           // {1..8} 
) oserdes2_udqsn_0 
(
  .OQ       (udqsn_oq),
  .SHIFTOUT1(),
  .SHIFTOUT2(),
  .SHIFTOUT3(),
  .SHIFTOUT4(),
  .TQ       (udqsn_tq),
  .CLK0     (ioclk0),
  .CLK1(1'b0),
  .CLKDIV(1'b0),
  .D1       (1'b1),
  .D2       (1'b0),
  .D3(1'b0),
  .D4(1'b0),
  .IOCE     (pll_ce_0),
  .OCE      (1'b1),
  .RST      (int_sys_rst),
  .SHIFTIN1 (1'b0),
  .SHIFTIN2 (1'b0),
  .SHIFTIN3(1'b0),
  .SHIFTIN4(1'b0),
  .T1       (dqsIO_w_en_90_n),
  .T2       (dqsIO_w_en_90_p),
  .T3(1'b0),
  .T4(1'b0),
  .TCE      (1'b1),
  .TRAIN    (1'b0)
);

////////////////////////////////////////////////////////
//OSDDRES2 instantiations end
///////////////////////////////////////////////////////

wire aux_sdi_out_udqsp;
wire aux_sdi_out_10;
wire aux_sdi_out_11;
wire aux_sdi_out_12;
wire aux_sdi_out_14;
wire aux_sdi_out_15;

////////////////////////////////////////////////
//IODRP2 instantiations
////////////////////////////////////////////////
generate
if(C_NUM_DQ_PINS == 16 ) begin : dq_15_0_data
////////////////////////////////////////////////
//IODRP2 instantiations
////////////////////////////////////////////////

wire aux_sdi_out_14;
wire aux_sdi_out_15;
////////////////////////////////////////////////
//DQ14
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ14_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (7),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive
)
iodrp2_dq_14
(
  .AUXSDO             (aux_sdi_out_14),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[14]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[14]),
  .SDO(),
  .TOUT               (t_dq[14]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_15),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[14]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[14]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[14]) 
);


/////////////////////////////////////////////////
//DQ15
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ15_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (7),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_15
(
  .AUXSDO             (aux_sdi_out_15),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[15]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[15]),
  .SDO(),
  .TOUT               (t_dq[15]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (1'b0),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[15]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[15]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[15]) 
);



wire aux_sdi_out_12;
wire aux_sdi_out_13;
/////////////////////////////////////////////////
//DQ12
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ12_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (6),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_12
(
  .AUXSDO             (aux_sdi_out_12),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[12]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[12]),
  .SDO(),
  .TOUT               (t_dq[12]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_13),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[12]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[12]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[12]) 
);



/////////////////////////////////////////////////
//DQ13
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ13_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (6),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_13
(
  .AUXSDO             (aux_sdi_out_13),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[13]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[13]),
  .SDO(),
  .TOUT               (t_dq[13]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_14),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[13]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[13]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[13]) 
);


wire aux_sdi_out_udqsp;
wire aux_sdi_out_udqsn;
/////////
//UDQSP
/////////
IODRP2_MCB #(
.DATA_RATE            (C_DQS_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (UDQSP_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (14),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQS_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_udqsp_0
(
  .AUXSDO             (aux_sdi_out_udqsp),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_udqs),
  .DQSOUTN(),
  .DQSOUTP            (idelay_udqs_ioi_m),
  .SDO(),
  .TOUT               (t_udqs),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_udqsn),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_udqsp),
  .IOCLK0             (ioclk0),
  .IOCLK1(),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (udqsp_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (udqsp_tq) 
);

/////////
//UDQSN
/////////
IODRP2_MCB #(
.DATA_RATE            (C_DQS_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (UDQSN_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (14),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQS_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_udqsn_0
(
  .AUXSDO             (aux_sdi_out_udqsn),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_udqsn),
  .DQSOUTN(),
  .DQSOUTP            (idelay_udqs_ioi_s),
  .SDO(),
  .TOUT               (t_udqsn),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_12),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_udqsp),
  .IOCLK0             (ioclk0),
  .IOCLK1(),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (udqsn_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (udqsn_tq) 
);


wire aux_sdi_out_10;
wire aux_sdi_out_11;
/////////////////////////////////////////////////
//DQ10
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ10_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (5),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_10
(
  .AUXSDO             (aux_sdi_out_10),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[10]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[10]),
  .SDO(),
  .TOUT               (t_dq[10]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_11),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[10]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[10]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[10]) 
);


/////////////////////////////////////////////////
//DQ11
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ11_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (5),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_11
(
  .AUXSDO             (aux_sdi_out_11),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[11]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[11]),
  .SDO(),
  .TOUT               (t_dq[11]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_udqsp),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[11]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[11]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[11])
);



wire aux_sdi_out_8;
wire aux_sdi_out_9;
/////////////////////////////////////////////////
//DQ8
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ8_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (4),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_8
(
  .AUXSDO             (aux_sdi_out_8),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[8]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[8]),
  .SDO(),
  .TOUT               (t_dq[8]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_9),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[8]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[8]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[8]) 
);


/////////////////////////////////////////////////
//DQ9
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ9_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (4),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_9
(
  .AUXSDO             (aux_sdi_out_9),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[9]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[9]),
  .SDO(),
  .TOUT               (t_dq[9]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_10),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[9]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[9]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[9]) 
);


wire aux_sdi_out_0;
wire aux_sdi_out_1;
/////////////////////////////////////////////////
//DQ0
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ0_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (0),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_0
(
  .AUXSDO             (aux_sdi_out_0),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[0]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[0]),
  .SDO(),
  .TOUT               (t_dq[0]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_1),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[0]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[0]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[0]) 
);


/////////////////////////////////////////////////
//DQ1
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ1_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (0),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_1
(
  .AUXSDO             (aux_sdi_out_1),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[1]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[1]),
  .SDO(),
  .TOUT               (t_dq[1]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_8),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[1]),
  .IOCLK0             (ioclk90),
  .IOCLK1(),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[1]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[1]) 
);


wire aux_sdi_out_2;
wire aux_sdi_out_3;
/////////////////////////////////////////////////
//DQ2
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ2_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (1),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_2
(
  .AUXSDO             (aux_sdi_out_2),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[2]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[2]),
  .SDO(),
  .TOUT               (t_dq[2]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_3),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[2]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[2]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[2]) 
);


/////////////////////////////////////////////////
//DQ3
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ3_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (1),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_3
(
  .AUXSDO             (aux_sdi_out_3),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[3]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[3]),
  .SDO(),
  .TOUT               (t_dq[3]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_0),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[3]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[3]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[3]) 
);


wire aux_sdi_out_dqsp;
wire aux_sdi_out_dqsn;
/////////
//DQSP
/////////
IODRP2_MCB #(
.DATA_RATE            (C_DQS_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (LDQSP_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (15),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQS_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dqsp_0
(
  .AUXSDO             (aux_sdi_out_dqsp),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dqs),
  .DQSOUTN(),
  .DQSOUTP            (idelay_dqs_ioi_m),
  .SDO(),
  .TOUT               (t_dqs),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_dqsn),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dqsp),
  .IOCLK0             (ioclk0),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dqsp_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (dqsp_tq) 
);

/////////
//DQSN
/////////
IODRP2_MCB #(
.DATA_RATE            (C_DQS_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (LDQSN_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (15),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQS_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dqsn_0
(
  .AUXSDO             (aux_sdi_out_dqsn),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dqsn),
  .DQSOUTN(),
  .DQSOUTP            (idelay_dqs_ioi_s),
  .SDO(),
  .TOUT               (t_dqsn),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_2),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dqsp),
  .IOCLK0             (ioclk0),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dqsn_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (dqsn_tq) 
);

wire aux_sdi_out_6;
wire aux_sdi_out_7;
/////////////////////////////////////////////////
//DQ6
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ6_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (3),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_6
(
  .AUXSDO             (aux_sdi_out_6),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[6]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[6]),
  .SDO(),
  .TOUT               (t_dq[6]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_7),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[6]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[6]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[6]) 
);

/////////////////////////////////////////////////
//DQ7
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ7_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (3),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_7
(
  .AUXSDO             (aux_sdi_out_7),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[7]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[7]),
  .SDO(),
  .TOUT               (t_dq[7]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_dqsp),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[7]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[7]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[7]) 
);



wire aux_sdi_out_4;
wire aux_sdi_out_5;
/////////////////////////////////////////////////
//DQ4
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ4_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (2),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_4
(
  .AUXSDO             (aux_sdi_out_4),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[4]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[4]),
  .SDO(),
  .TOUT               (t_dq[4]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_5),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[4]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[4]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[4]) 
);

/////////////////////////////////////////////////
//DQ5
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ5_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (2),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_5
(
  .AUXSDO             (aux_sdi_out_5),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[5]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[5]),
  .SDO(),
  .TOUT               (t_dq[5]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_6),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[5]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[5]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[5]) 
);


//wire aux_sdi_out_udm;
wire aux_sdi_out_ldm;
/////////////////////////////////////////////////
//UDM
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (0),  // 0 to 255 inclusive
.MCB_ADDRESS          (8),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_udm
(
  .AUXSDO             (ioi_drp_sdi),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_udm),
  .DQSOUTN(),
  .DQSOUTP(),
  .SDO(),
  .TOUT               (t_udm),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_ldm),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN(1'b0),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (udm_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (udm_t) 
);


/////////////////////////////////////////////////
//LDM
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (0),  // 0 to 255 inclusive
.MCB_ADDRESS          (8),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_ldm
(
  .AUXSDO             (aux_sdi_out_ldm),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_ldm),
  .DQSOUTN(),
  .DQSOUTP(),
  .SDO(),
  .TOUT               (t_ldm),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_4),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN(1'b0),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (ldm_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (ldm_t) 
);
end
endgenerate

generate
if(C_NUM_DQ_PINS == 8 ) begin : dq_7_0_data
wire aux_sdi_out_0;
wire aux_sdi_out_1;
/////////////////////////////////////////////////
//DQ0
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ0_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (0),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_0
(
  .AUXSDO             (aux_sdi_out_0),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[0]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[0]),
  .SDO(),
  .TOUT               (t_dq[0]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_1),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[0]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[0]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[0]) 
);


/////////////////////////////////////////////////
//DQ1
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ1_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (0),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_1
(
  .AUXSDO             (aux_sdi_out_1),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[1]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[1]),
  .SDO(),
  .TOUT               (t_dq[1]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (1'b0),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[1]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[1]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[1]) 
);


wire aux_sdi_out_2;
wire aux_sdi_out_3;
/////////////////////////////////////////////////
//DQ2
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ2_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (1),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_2
(
  .AUXSDO             (aux_sdi_out_2),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[2]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[2]),
  .SDO(),
  .TOUT               (t_dq[2]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_3),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[2]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[2]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[2]) 
);


/////////////////////////////////////////////////
//DQ3
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ3_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (1),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_3
(
  .AUXSDO             (aux_sdi_out_3),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[3]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[3]),
  .SDO(),
  .TOUT               (t_dq[3]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_0),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[3]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[3]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[3]) 
);


wire aux_sdi_out_dqsp;
wire aux_sdi_out_dqsn;
/////////
//DQSP
/////////
IODRP2_MCB #(
.DATA_RATE            (C_DQS_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (LDQSP_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (15),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQS_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dqsp_0
(
  .AUXSDO             (aux_sdi_out_dqsp),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dqs),
  .DQSOUTN(),
  .DQSOUTP            (idelay_dqs_ioi_m),
  .SDO(),
  .TOUT               (t_dqs),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_dqsn),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dqsp),
  .IOCLK0             (ioclk0),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dqsp_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (dqsp_tq) 
);

/////////
//DQSN
/////////
IODRP2_MCB #(
.DATA_RATE            (C_DQS_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (LDQSN_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (15),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQS_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dqsn_0
(
  .AUXSDO             (aux_sdi_out_dqsn),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dqsn),
  .DQSOUTN(),
  .DQSOUTP            (idelay_dqs_ioi_s),
  .SDO(),
  .TOUT               (t_dqsn),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_2),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dqsp),
  .IOCLK0             (ioclk0),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dqsn_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (dqsn_tq) 
);

wire aux_sdi_out_6;
wire aux_sdi_out_7;
/////////////////////////////////////////////////
//DQ6
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ6_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (3),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_6
(
  .AUXSDO             (aux_sdi_out_6),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[6]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[6]),
  .SDO(),
  .TOUT               (t_dq[6]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_7),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[6]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[6]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[6]) 
);

/////////////////////////////////////////////////
//DQ7
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ7_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (3),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_7
(
  .AUXSDO             (aux_sdi_out_7),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[7]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[7]),
  .SDO(),
  .TOUT               (t_dq[7]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_dqsp),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[7]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[7]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[7]) 
);



wire aux_sdi_out_4;
wire aux_sdi_out_5;
/////////////////////////////////////////////////
//DQ4
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ4_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (2),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_4
(
  .AUXSDO             (aux_sdi_out_4),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[4]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[4]),
  .SDO(),
  .TOUT               (t_dq[4]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_5),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[4]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[4]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[4]) 
);

/////////////////////////////////////////////////
//DQ5
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ5_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (2),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_5
(
  .AUXSDO             (aux_sdi_out_5),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[5]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[5]),
  .SDO(),
  .TOUT               (t_dq[5]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_6),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[5]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[5]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[5]) 
);

//NEED TO GENERATE UDM so that user won't instantiate in this location
//wire aux_sdi_out_udm;
wire aux_sdi_out_ldm;
/////////////////////////////////////////////////
//UDM
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (0),  // 0 to 255 inclusive
.MCB_ADDRESS          (8),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_udm
(
  .AUXSDO             (ioi_drp_sdi),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_udm),
  .DQSOUTN(),
  .DQSOUTP(),
  .SDO(),
  .TOUT               (t_udm),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_ldm),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN(1'b0),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (udm_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (udm_t) 
);


/////////////////////////////////////////////////
//LDM
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (0),  // 0 to 255 inclusive
.MCB_ADDRESS          (8),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_ldm
(
  .AUXSDO             (aux_sdi_out_ldm),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_ldm),
  .DQSOUTN(),
  .DQSOUTP(),
  .SDO(),
  .TOUT               (t_ldm),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_4),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN(1'b0),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (ldm_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (ldm_t) 
);
end
endgenerate

generate
if(C_NUM_DQ_PINS == 4 ) begin : dq_3_0_data

wire aux_sdi_out_0;
wire aux_sdi_out_1;
/////////////////////////////////////////////////
//DQ0
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ0_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (0),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_0
(
  .AUXSDO             (aux_sdi_out_0),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[0]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[0]),
  .SDO(),
  .TOUT               (t_dq[0]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_1),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[0]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[0]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[0]) 
);


/////////////////////////////////////////////////
//DQ1
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ1_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (0),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_1
(
  .AUXSDO             (aux_sdi_out_1),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[1]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[1]),
  .SDO(),
  .TOUT               (t_dq[1]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (1'b0),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[1]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[1]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[1]) 
);


wire aux_sdi_out_2;
wire aux_sdi_out_3;
/////////////////////////////////////////////////
//DQ2
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ2_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (1),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_2
(
  .AUXSDO             (aux_sdi_out_2),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[2]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[2]),
  .SDO(),
  .TOUT               (t_dq[2]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_3),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[2]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[2]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[2]) 
);


/////////////////////////////////////////////////
//DQ3
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (DQ3_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (1),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_3
(
  .AUXSDO             (aux_sdi_out_3),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dq[3]),
  .DQSOUTN(),
  .DQSOUTP            (in_dq[3]),
  .SDO(),
  .TOUT               (t_dq[3]),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_0),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dq[3]),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dq_oq[3]),
  .SDI                (ioi_drp_sdo),
  .T                  (dq_tq[3]) 
);


wire aux_sdi_out_dqsp;
wire aux_sdi_out_dqsn;
/////////
//DQSP
/////////
IODRP2_MCB #(
.DATA_RATE            (C_DQS_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (LDQSP_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (15),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQS_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dqsp_0
(
  .AUXSDO             (aux_sdi_out_dqsp),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dqs),
  .DQSOUTN(),
  .DQSOUTP            (idelay_dqs_ioi_m),
  .SDO(),
  .TOUT               (t_dqs),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_dqsn),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dqsp),
  .IOCLK0             (ioclk0),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dqsp_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (dqsp_tq) 
);

/////////
//DQSN
/////////
IODRP2_MCB #(
.DATA_RATE            (C_DQS_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (LDQSN_TAP_DELAY_VAL),  // 0 to 255 inclusive
.MCB_ADDRESS          (15),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQS_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dqsn_0
(
  .AUXSDO             (aux_sdi_out_dqsn),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_dqsn),
  .DQSOUTN(),
  .DQSOUTP            (idelay_dqs_ioi_s),
  .SDO(),
  .TOUT               (t_dqsn),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_2),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN            (in_pre_dqsp),
  .IOCLK0             (ioclk0),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (dqsn_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (dqsn_tq) 
);

//NEED TO GENERATE UDM so that user won't instantiate in this location
//wire aux_sdi_out_udm;
wire aux_sdi_out_ldm;
/////////////////////////////////////////////////
//UDM
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (0),  // 0 to 255 inclusive
.MCB_ADDRESS          (8),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_MASTER),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_udm
(
  .AUXSDO             (ioi_drp_sdi),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_udm),
  .DQSOUTN(),
  .DQSOUTP(),
  .SDO(),
  .TOUT               (t_udm),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_ldm),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN(1'b0),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (udm_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (udm_t) 
);


/////////////////////////////////////////////////
//LDM
////////////////////////////////////////////////
IODRP2_MCB #(
.DATA_RATE            (C_DQ_IODRP2_DATA_RATE),   // "SDR", "DDR"
.IDELAY_VALUE         (0),  // 0 to 255 inclusive
.MCB_ADDRESS          (8),  // 0 to 15
.ODELAY_VALUE         (0),  // 0 to 255 inclusive
.SERDES_MODE          (C_DQ_IODRP2_SERDES_MODE_SLAVE),   // "NONE", "MASTER", "SLAVE"
.SIM_TAPDELAY_VALUE   (10)  // 10 to 90 inclusive

)
iodrp2_dq_ldm
(
  .AUXSDO             (aux_sdi_out_ldm),
  .DATAOUT(),
  .DATAOUT2(),
  .DOUT               (ioi_ldm),
  .DQSOUTN(),
  .DQSOUTP(),
  .SDO(),
  .TOUT               (t_ldm),
  .ADD                (ioi_drp_add),
  .AUXADDR            (ioi_drp_addr),
  .AUXSDOIN           (aux_sdi_out_4),
  .BKST               (ioi_drp_broadcast),
  .CLK                (ioi_drp_clk),
  .CS                 (ioi_drp_cs),
  .IDATAIN(),
  .IOCLK0             (ioclk90),
  .IOCLK1(1'b0),
  .MEMUPDATE          (ioi_drp_update),
  .ODATAIN            (ldm_oq),
  .SDI                (ioi_drp_sdo),
  .T                  (ldm_t) 
);

end
endgenerate

 ////////////////////////////////////////////////
 //IOBs instantiations
 // this part need more inputs from design team 
 // for now just use as listed in fpga.v
 ////////////////////////////////////////////////


//// Address

genvar addr_i;
   generate 
      for(addr_i = 0; addr_i < C_MEM_ADDR_WIDTH; addr_i = addr_i + 1) begin : gen_addr_obuft
        OBUFT iob_addr_inst
        (.I  ( ioi_addr[addr_i]), 
         .T   ( t_addr[addr_i]), 
         .O ( mcbx_dram_addr[addr_i])
        );
      end       
   endgenerate

genvar ba_i;
   generate 
      for(ba_i = 0; ba_i < C_MEM_BANKADDR_WIDTH; ba_i = ba_i + 1) begin : gen_ba_obuft
        OBUFT iob_ba_inst
        (.I  ( ioi_ba[ba_i]), 
         .T   ( t_ba[ba_i]), 
         .O ( mcbx_dram_ba[ba_i])
        );
      end       
   endgenerate



// DRAM Control
OBUFT iob_ras (.O(mcbx_dram_ras_n),.I(ioi_ras),.T(t_ras));
OBUFT iob_cas (.O(mcbx_dram_cas_n),.I(ioi_cas),.T(t_cas));
OBUFT iob_we  (.O(mcbx_dram_we_n ),.I(ioi_we ),.T(t_we ));
OBUFT iob_cke (.O(mcbx_dram_cke),.I(ioi_cke),.T(t_cke));

generate 
if (C_MEM_TYPE == "DDR3") begin : gen_ddr3_rst
OBUFT iob_rst (.O(mcbx_dram_ddr3_rst),.I(ioi_rst),.T(t_rst));
end
endgenerate
generate
if((C_MEM_TYPE == "DDR3"  && (C_MEM_DDR3_RTT != "OFF" || C_MEM_DDR3_DYN_WRT_ODT != "OFF"))
 ||(C_MEM_TYPE == "DDR2" &&  C_MEM_DDR2_RTT != "OFF") ) begin : gen_dram_odt
OBUFT iob_odt (.O(mcbx_dram_odt),.I(ioi_odt),.T(t_odt));
end
endgenerate

// Clock
OBUFTDS iob_clk  (.I(ioi_ck), .T(t_ck), .O(mcbx_dram_clk), .OB(mcbx_dram_clk_n)); 

//DQ
genvar dq_i;
generate
      for(dq_i = 0; dq_i < C_NUM_DQ_PINS; dq_i = dq_i + 1) begin : gen_dq_iobuft
         IOBUF gen_iob_dq_inst (.IO(mcbx_dram_dq[dq_i]),.I(ioi_dq[dq_i]),.T(t_dq[dq_i]),.O(in_pre_dq[dq_i]));
      end
endgenerate


// DQS
generate 
if(C_MEM_TYPE == "DDR" || C_MEM_TYPE =="MDDR" || (C_MEM_TYPE == "DDR2" && (C_MEM_DDR2_DIFF_DQS_EN == "NO"))) begin: gen_dqs_iobuf
IOBUF iob_dqs  (.IO(mcbx_dram_dqs), .I(ioi_dqs),.T(t_dqs),.O(in_pre_dqsp));
end else begin: gen_dqs_iobufds
IOBUFDS iob_dqs  (.IO(mcbx_dram_dqs),.IOB(mcbx_dram_dqs_n), .I(ioi_dqs),.T(t_dqs),.O(in_pre_dqsp));

end
endgenerate

generate
if((C_MEM_TYPE == "DDR" || C_MEM_TYPE =="MDDR" || (C_MEM_TYPE == "DDR2" && (C_MEM_DDR2_DIFF_DQS_EN == "NO"))) && C_NUM_DQ_PINS == 16) begin: gen_udqs_iobuf
IOBUF iob_udqs  (.IO(mcbx_dram_udqs), .I(ioi_udqs),.T(t_udqs),.O(in_pre_udqsp));
end else if(C_NUM_DQ_PINS == 16) begin: gen_udqs_iobufds
IOBUFDS iob_udqs  (.IO(mcbx_dram_udqs),.IOB(mcbx_dram_udqs_n), .I(ioi_udqs),.T(t_udqs),.O(in_pre_udqsp));

end
endgenerate

// DQS PULLDWON
generate 
if(C_MEM_TYPE == "DDR" || C_MEM_TYPE =="MDDR" || (C_MEM_TYPE == "DDR2" && (C_MEM_DDR2_DIFF_DQS_EN == "NO"))) begin: gen_dqs_pullupdn
PULLDOWN dqs_pulldown (.O(mcbx_dram_dqs));
end else begin: gen_dqs_pullupdn_ds
PULLDOWN dqs_pulldown (.O(mcbx_dram_dqs));
PULLUP dqs_n_pullup (.O(mcbx_dram_dqs_n));

end
endgenerate

// DQSN PULLUP
generate
if((C_MEM_TYPE == "DDR" || C_MEM_TYPE =="MDDR" || (C_MEM_TYPE == "DDR2" && (C_MEM_DDR2_DIFF_DQS_EN == "NO"))) && C_NUM_DQ_PINS == 16) begin: gen_udqs_pullupdn
PULLDOWN udqs_pulldown (.O(mcbx_dram_udqs));
end else if(C_NUM_DQ_PINS == 16) begin: gen_udqs_pullupdn_ds
PULLDOWN udqs_pulldown (.O(mcbx_dram_udqs));
PULLUP   udqs_n_pullup (.O(mcbx_dram_udqs_n));

end
endgenerate




//DM
//  datamask generation
generate
if( C_NUM_DQ_PINS == 16) begin : gen_udm
OBUFT iob_udm (.I(ioi_udm), .T(t_udm), .O(mcbx_dram_udm)); 
end
endgenerate

OBUFT iob_ldm (.I(ioi_ldm), .T(t_ldm), .O(mcbx_dram_ldm)); 

endmodule

