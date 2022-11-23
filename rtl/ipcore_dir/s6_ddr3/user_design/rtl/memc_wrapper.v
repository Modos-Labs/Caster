//*****************************************************************************
// (c) Copyright 2009-10 Xilinx, Inc. All rights reserved.
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
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Application        : MIG             
//  \   \         Filename           : memc_wrapper.v
//  /   /         Date Last Modified : $Date: 2010/08/
// /___/   /\     Date Created       : Mon Mar 2 2009
// \   \  /  \    
//  \___\/\___\
//
//Device           : Spartan-6
//Design Name      : DDR/DDR2/DDR3/LPDDR 
//Purpose          : This is a static top level module instantiating the mcb_ui_top,
//                   which provides interface to all the standard as well as AXI ports.
//                   This module memc_wrapper provides interface to only the standard ports.
//Reference        :
//Revision History :
//*****************************************************************************
`timescale 1ns/1ps

module memc_wrapper  #
  (
   parameter         C_MEMCLK_PERIOD           = 2500,
   parameter         C_P0_MASK_SIZE            = 4,
   parameter         C_P0_DATA_PORT_SIZE       = 32,
   parameter         C_P1_MASK_SIZE            = 4,
   parameter         C_P1_DATA_PORT_SIZE       = 32,

   parameter         C_PORT_ENABLE             = 6'b111111,
   parameter         C_PORT_CONFIG             = "B128",
   parameter         C_MEM_ADDR_ORDER          = "BANK_ROW_COLUMN",
   // The following parameter reflects the GUI selection of the Arbitration algorithm.
   // Zero value corresponds to round robin algorithm and one to custom selection.
   // The parameter is used to calculate the arbitration time slot parameters.                           
   parameter         C_ARB_ALGORITHM           = 0,    								   					   
   parameter         C_ARB_NUM_TIME_SLOTS      = 12,
   parameter         C_ARB_TIME_SLOT_0         = 18'o012345,
   parameter         C_ARB_TIME_SLOT_1         = 18'o123450,
   parameter         C_ARB_TIME_SLOT_2         = 18'o234501,
   parameter         C_ARB_TIME_SLOT_3         = 18'o345012,
   parameter         C_ARB_TIME_SLOT_4         = 18'o450123,
   parameter         C_ARB_TIME_SLOT_5         = 18'o501234,
   parameter         C_ARB_TIME_SLOT_6         = 18'o012345,
   parameter         C_ARB_TIME_SLOT_7         = 18'o123450,
   parameter         C_ARB_TIME_SLOT_8         = 18'o234501,
   parameter         C_ARB_TIME_SLOT_9         = 18'o345012,
   parameter         C_ARB_TIME_SLOT_10        = 18'o450123,
   parameter         C_ARB_TIME_SLOT_11        = 18'o501234,
   parameter         C_MEM_TRAS                = 45000,
   parameter         C_MEM_TRCD                = 12500,
   parameter         C_MEM_TREFI               = 7800,
   parameter         C_MEM_TRFC                = 127500,
   parameter         C_MEM_TRP                 = 12500,
   parameter         C_MEM_TWR                 = 15000,
   parameter         C_MEM_TRTP                = 7500,
   parameter         C_MEM_TWTR                = 7500,
   parameter         C_NUM_DQ_PINS             = 8,
   parameter         C_MEM_TYPE                = "DDR3",
   parameter         C_MEM_DENSITY             = "512M",
   parameter         C_MEM_BURST_LEN           = 8,
   parameter         C_MEM_CAS_LATENCY         = 4,
   parameter         C_MEM_ADDR_WIDTH          = 13,
   parameter         C_MEM_BANKADDR_WIDTH      = 3,
   parameter         C_MEM_NUM_COL_BITS        = 11,
   parameter         C_MEM_DDR3_CAS_LATENCY    = 7,
   parameter         C_MEM_MOBILE_PA_SR        = "FULL",
   parameter         C_MEM_DDR1_2_ODS          = "FULL",
   parameter         C_MEM_DDR3_ODS            = "DIV6",
   parameter         C_MEM_DDR2_RTT            = "50OHMS",
   parameter         C_MEM_DDR3_RTT            = "DIV2",
   parameter         C_MEM_MDDR_ODS            = "FULL",
   parameter         C_MEM_DDR2_DIFF_DQS_EN    = "YES",
   parameter         C_MEM_DDR2_3_PA_SR        = "OFF",
   parameter         C_MEM_DDR3_CAS_WR_LATENCY = 5,
   parameter         C_MEM_DDR3_AUTO_SR        = "ENABLED",
   parameter         C_MEM_DDR2_3_HIGH_TEMP_SR = "NORMAL",
   parameter         C_MEM_DDR3_DYN_WRT_ODT    = "OFF",
   parameter         C_MC_CALIB_BYPASS         = "NO",

   parameter         LDQSP_TAP_DELAY_VAL       = 0,
   parameter         UDQSP_TAP_DELAY_VAL       = 0,
   parameter         LDQSN_TAP_DELAY_VAL       = 0,
   parameter         UDQSN_TAP_DELAY_VAL       = 0,
   parameter         DQ0_TAP_DELAY_VAL         = 0,
   parameter         DQ1_TAP_DELAY_VAL         = 0,
   parameter         DQ2_TAP_DELAY_VAL         = 0,
   parameter         DQ3_TAP_DELAY_VAL         = 0,
   parameter         DQ4_TAP_DELAY_VAL         = 0,
   parameter         DQ5_TAP_DELAY_VAL         = 0,
   parameter         DQ6_TAP_DELAY_VAL         = 0,
   parameter         DQ7_TAP_DELAY_VAL         = 0,
   parameter         DQ8_TAP_DELAY_VAL         = 0,
   parameter         DQ9_TAP_DELAY_VAL         = 0,
   parameter         DQ10_TAP_DELAY_VAL        = 0,
   parameter         DQ11_TAP_DELAY_VAL        = 0,
   parameter         DQ12_TAP_DELAY_VAL        = 0,
   parameter         DQ13_TAP_DELAY_VAL        = 0,
   parameter         DQ14_TAP_DELAY_VAL        = 0,
   parameter         DQ15_TAP_DELAY_VAL        = 0,

   parameter         C_CALIB_SOFT_IP           = "TRUE",
   parameter         C_SIMULATION              = "FALSE",
   parameter         C_SKIP_IN_TERM_CAL        = 1'b0,
   parameter         C_SKIP_DYNAMIC_CAL        = 1'b0,
   parameter         C_MC_CALIBRATION_MODE     = "CALIBRATION",
   parameter         C_MC_CALIBRATION_DELAY    = "HALF"

  )

  (

   // Raw Wrapper Signals
   input                                     sysclk_2x,          
   input                                     sysclk_2x_180, 
   input                                     pll_ce_0,
   input                                     pll_ce_90, 
   input                                     pll_lock,
   input                                     async_rst,
   input                                     mcb_drp_clk,       
   output      [C_MEM_ADDR_WIDTH-1:0]        mcbx_dram_addr,  
   output      [C_MEM_BANKADDR_WIDTH-1:0]    mcbx_dram_ba,
   output                                    mcbx_dram_ras_n,       
   output                                    mcbx_dram_cas_n,       
   output                                    mcbx_dram_we_n,  
   output                                    mcbx_dram_cke, 
   output                                    mcbx_dram_clk, 
   output                                    mcbx_dram_clk_n,       
   inout       [C_NUM_DQ_PINS-1:0]           mcbx_dram_dq,
   inout                                     mcbx_dram_dqs, 
   inout                                     mcbx_dram_dqs_n,       
   inout                                     mcbx_dram_udqs,  
   inout                                     mcbx_dram_udqs_n,       
   output                                    mcbx_dram_udm, 
   output                                    mcbx_dram_ldm, 
   output                                    mcbx_dram_odt, 
   output                                    mcbx_dram_ddr3_rst,      
   inout                                     mcbx_rzq,
   inout                                     mcbx_zio,
   output                                    calib_done,
   input                                     selfrefresh_enter,       
   output                                    selfrefresh_mode,

// This new memc_wrapper shows all the six logical static user ports. The port
// configuration parameter and the port enable parameter are the ones that 
// determine the active and non-active ports. The following list shows the 
// default active ports for each port configuration.
//
// Config 1: "B32_B32_X32_X32_X32_X32"
//            User port 0  --> 32 bit,  User port 1  --> 32 bit 
//            User port 2  --> 32 bit,  User port 3  --> 32 bit
//            User port 4  --> 32 bit,  User port 5  --> 32 bit
// Config 2: "B32_B32_B32_B32"  
//            User port 0  --> 32 bit 
//            User port 1  --> 32 bit 
//            User port 2  --> 32 bit 
//            User port 3  --> 32 bit 
// Config 3: "B64_B32_B3"  
//            User port 0  --> 64 bit 
//            User port 1  --> 32 bit 
//            User port 2  --> 32 bit 
// Config 4: "B64_B64"          
//            User port 0  --> 64 bit 
//            User port 1  --> 64 bit
// Config 5  "B128"          
//            User port 0  --> 128 bit


   // User Port-0 command interface will be active only when the port is enabled in 
   // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
   input                                     p0_cmd_clk, 
   input                                     p0_cmd_en, 
   input       [2:0]                         p0_cmd_instr,
   input       [5:0]                         p0_cmd_bl, 
   input       [29:0]                        p0_cmd_byte_addr,       
   output                                    p0_cmd_full,
   output                                    p0_cmd_empty,
   // User Port-0 data write interface will be active only when the port is enabled in
   // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
   input                                     p0_wr_clk,       
   input                                     p0_wr_en,
   input       [C_P0_MASK_SIZE-1:0]          p0_wr_mask,
   input       [C_P0_DATA_PORT_SIZE-1:0]     p0_wr_data,
   output                                    p0_wr_full,
   output      [6:0]                         p0_wr_count,
   output                                    p0_wr_empty,
   output                                    p0_wr_underrun,  
   output                                    p0_wr_error,
   // User Port-0 data read interface will be active only when the port is enabled in
   // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
   input                                     p0_rd_clk,
   input                                     p0_rd_en,
   output      [C_P0_DATA_PORT_SIZE-1:0]     p0_rd_data,
   output                                    p0_rd_empty,
   output      [6:0]                         p0_rd_count,
   output                                    p0_rd_full,
   output                                    p0_rd_overflow,  
   output                                    p0_rd_error,

   // User Port-1 command interface will be active only when the port is enabled in 
   // the port configurations Config-1, Config-2, Config-3 and Config-4
   input                                     p1_cmd_clk, 
   input                                     p1_cmd_en, 
   input       [2:0]                         p1_cmd_instr,
   input       [5:0]                         p1_cmd_bl, 
   input       [29:0]                        p1_cmd_byte_addr,       
   output                                    p1_cmd_full,
   output                                    p1_cmd_empty,
   // User Port-1 data write interface will be active only when the port is enabled in 
   // the port configurations Config-1, Config-2, Config-3 and Config-4
   input                                     p1_wr_clk,       
   input                                     p1_wr_en,
   input       [C_P1_MASK_SIZE-1:0]          p1_wr_mask,
   input       [C_P1_DATA_PORT_SIZE-1:0]     p1_wr_data,
   output                                    p1_wr_full,
   output      [6:0]                         p1_wr_count,
   output                                    p1_wr_empty,
   output                                    p1_wr_underrun,  
   output                                    p1_wr_error,
   // User Port-1 data read interface will be active only when the port is enabled in 
   // the port configurations Config-1, Config-2, Config-3 and Config-4
   input                                     p1_rd_clk,
   input                                     p1_rd_en,
   output      [C_P1_DATA_PORT_SIZE-1:0]     p1_rd_data,
   output                                    p1_rd_empty,
   output      [6:0]                         p1_rd_count,
   output                                    p1_rd_full,
   output                                    p1_rd_overflow,  
   output                                    p1_rd_error,

   // User Port-2 command interface will be active only when the port is enabled in 
   // the port configurations Config-1, Config-2 and Config-3
   input                                     p2_cmd_clk, 
   input                                     p2_cmd_en, 
   input       [2:0]                         p2_cmd_instr,
   input       [5:0]                         p2_cmd_bl, 
   input       [29:0]                        p2_cmd_byte_addr,       
   output                                    p2_cmd_full,
   output                                    p2_cmd_empty,
   // User Port-2 data write interface will be active only when the port is enabled in 
   // the port configurations Config-1 write direction, Config-2 and Config-3
   input                                     p2_wr_clk,       
   input                                     p2_wr_en,
   input       [3:0]                         p2_wr_mask,
   input       [31:0]                        p2_wr_data,
   output                                    p2_wr_full,
   output      [6:0]                         p2_wr_count,
   output                                    p2_wr_empty,
   output                                    p2_wr_underrun,  
   output                                    p2_wr_error,
   // User Port-2 data read interface will be active only when the port is enabled in 
   // the port configurations Config-1 read direction, Config-2 and Config-3
   input                                     p2_rd_clk,
   input                                     p2_rd_en,
   output      [31:0]                        p2_rd_data,
   output                                    p2_rd_empty,
   output      [6:0]                         p2_rd_count,
   output                                    p2_rd_full,
   output                                    p2_rd_overflow,  
   output                                    p2_rd_error,

   // User Port-3 command interface will be active only when the port is enabled in 
   // the port configurations Config-1 and Config-2
   input                                     p3_cmd_clk, 
   input                                     p3_cmd_en, 
   input       [2:0]                         p3_cmd_instr,
   input       [5:0]                         p3_cmd_bl, 
   input       [29:0]                        p3_cmd_byte_addr,       
   output                                    p3_cmd_full,
   output                                    p3_cmd_empty,
   // User Port-3 data write interface will be active only when the port is enabled in 
   // the port configurations Config-1 write direction and Config-2
   input                                     p3_wr_clk,       
   input                                     p3_wr_en,
   input       [3:0]                         p3_wr_mask,
   input       [31:0]                        p3_wr_data,
   output                                    p3_wr_full,
   output      [6:0]                         p3_wr_count,
   output                                    p3_wr_empty,
   output                                    p3_wr_underrun,  
   output                                    p3_wr_error,
   // User Port-3 data read interface will be active only when the port is enabled in 
   // the port configurations Config-1 read direction and Config-2
   input                                     p3_rd_clk,
   input                                     p3_rd_en,
   output      [31:0]                        p3_rd_data,
   output                                    p3_rd_empty,
   output      [6:0]                         p3_rd_count,
   output                                    p3_rd_full,
   output                                    p3_rd_overflow,  
   output                                    p3_rd_error,

   // User Port-4 command interface will be active only when the port is enabled in 
   // the port configuration Config-1
   input                                     p4_cmd_clk, 
   input                                     p4_cmd_en, 
   input       [2:0]                         p4_cmd_instr,
   input       [5:0]                         p4_cmd_bl, 
   input       [29:0]                        p4_cmd_byte_addr,       
   output                                    p4_cmd_full,
   output                                    p4_cmd_empty,
   // User Port-4 data write interface will be active only when the port is enabled in 
   // the port configuration Config-1 write direction
   input                                     p4_wr_clk,       
   input                                     p4_wr_en,
   input       [3:0]                         p4_wr_mask,
   input       [31:0]                        p4_wr_data,
   output                                    p4_wr_full,
   output      [6:0]                         p4_wr_count,
   output                                    p4_wr_empty,
   output                                    p4_wr_underrun,  
   output                                    p4_wr_error,
   // User Port-4 data read interface will be active only when the port is enabled in 
   // the port configuration Config-1 read direction
   input                                     p4_rd_clk,
   input                                     p4_rd_en,
   output      [31:0]                        p4_rd_data,
   output                                    p4_rd_empty,
   output      [6:0]                         p4_rd_count,
   output                                    p4_rd_full,
   output                                    p4_rd_overflow,  
   output                                    p4_rd_error,
   // User Port-5 command interface will be active only when the port is enabled in 
   // the port configuration Config-1
   input                                     p5_cmd_clk, 
   input                                     p5_cmd_en, 
   input       [2:0]                         p5_cmd_instr,
   input       [5:0]                         p5_cmd_bl, 
   input       [29:0]                        p5_cmd_byte_addr,       
   output                                    p5_cmd_full,
   output                                    p5_cmd_empty,
   // User Port-5 data write interface will be active only when the port is enabled in 
   // the port configuration Config-1 write direction
   input                                     p5_wr_clk,       
   input                                     p5_wr_en,
   input       [3:0]                         p5_wr_mask,
   input       [31:0]                        p5_wr_data,
   output                                    p5_wr_full,
   output      [6:0]                         p5_wr_count,
   output                                    p5_wr_empty,
   output                                    p5_wr_underrun,  
   output                                    p5_wr_error,
   // User Port-5 data read interface will be active only when the port is enabled in 
   // the port configuration Config-1 read direction
   input                                     p5_rd_clk,
   input                                     p5_rd_en,
   output      [31:0]                        p5_rd_data,
   output                                    p5_rd_empty,
   output      [6:0]                         p5_rd_count,
   output                                    p5_rd_full,
   output                                    p5_rd_overflow,  
   output                                    p5_rd_error

  );
  
   localparam C_MC_CALIBRATION_CLK_DIV  = 1;
   localparam C_MEM_TZQINIT_MAXCNT      = 10'd512 + 10'd16;   // 16 clock cycles are added to avoid trfc violations
   localparam C_SKIP_DYN_IN_TERM        = 1'b1;

   localparam C_MC_CALIBRATION_RA       = 16'h0000;       
   localparam C_MC_CALIBRATION_BA       = 3'h0;       
   localparam C_MC_CALIBRATION_CA       = 12'h000;       

// All the following new localparams and signals are added to support 
// the AXI slave interface. They have no function to play in a standard
// interface design and can be ignored. 
   localparam C_S0_AXI_ID_WIDTH         = 4;
   localparam C_S0_AXI_ADDR_WIDTH       = 64;
   localparam C_S0_AXI_DATA_WIDTH       = 32;
   localparam C_S1_AXI_ID_WIDTH         = 4;
   localparam C_S1_AXI_ADDR_WIDTH       = 64;
   localparam C_S1_AXI_DATA_WIDTH       = 32;
   localparam C_S2_AXI_ID_WIDTH         = 4;
   localparam C_S2_AXI_ADDR_WIDTH       = 64;
   localparam C_S2_AXI_DATA_WIDTH       = 32;
   localparam C_S3_AXI_ID_WIDTH         = 4;
   localparam C_S3_AXI_ADDR_WIDTH       = 64;
   localparam C_S3_AXI_DATA_WIDTH       = 32;
   localparam C_S4_AXI_ID_WIDTH         = 4;
   localparam C_S4_AXI_ADDR_WIDTH       = 64;
   localparam C_S4_AXI_DATA_WIDTH       = 32;
   localparam C_S5_AXI_ID_WIDTH         = 4;
   localparam C_S5_AXI_ADDR_WIDTH       = 64;
   localparam C_S5_AXI_DATA_WIDTH       = 32;
   localparam C_MCB_USE_EXTERNAL_BUFPLL = 1;

// AXI wire declarations
// AXI interface of the mcb_ui_top module is connected to the following
// floating wires in all the standard interface designs.
   wire                                      s0_axi_aclk;
   wire                                      s0_axi_aresetn;
   wire [C_S0_AXI_ID_WIDTH-1:0]              s0_axi_awid; 
   wire [C_S0_AXI_ADDR_WIDTH-1:0]            s0_axi_awaddr; 
   wire [7:0]                                s0_axi_awlen; 
   wire [2:0]                                s0_axi_awsize; 
   wire [1:0]                                s0_axi_awburst; 
   wire [0:0]                                s0_axi_awlock; 
   wire [3:0]                                s0_axi_awcache; 
   wire [2:0]                                s0_axi_awprot; 
   wire [3:0]                                s0_axi_awqos; 
   wire                                      s0_axi_awvalid; 
   wire                                      s0_axi_awready; 
   wire [C_S0_AXI_DATA_WIDTH-1:0]            s0_axi_wdata; 
   wire [C_S0_AXI_DATA_WIDTH/8-1:0]          s0_axi_wstrb; 
   wire                                      s0_axi_wlast; 
   wire                                      s0_axi_wvalid; 
   wire                                      s0_axi_wready; 
   wire [C_S0_AXI_ID_WIDTH-1:0]              s0_axi_bid; 
   wire [1:0]                                s0_axi_bresp; 
   wire                                      s0_axi_bvalid; 
   wire                                      s0_axi_bready; 
   wire [C_S0_AXI_ID_WIDTH-1:0]              s0_axi_arid; 
   wire [C_S0_AXI_ADDR_WIDTH-1:0]            s0_axi_araddr; 
   wire [7:0]                                s0_axi_arlen; 
   wire [2:0]                                s0_axi_arsize; 
   wire [1:0]                                s0_axi_arburst; 
   wire [0:0]                                s0_axi_arlock; 
   wire [3:0]                                s0_axi_arcache; 
   wire [2:0]                                s0_axi_arprot; 
   wire [3:0]                                s0_axi_arqos; 
   wire                                      s0_axi_arvalid; 
   wire                                      s0_axi_arready; 
   wire [C_S0_AXI_ID_WIDTH-1:0]              s0_axi_rid; 
   wire [C_S0_AXI_DATA_WIDTH-1:0]            s0_axi_rdata; 
   wire [1:0]                                s0_axi_rresp; 
   wire                                      s0_axi_rlast; 
   wire                                      s0_axi_rvalid; 
   wire                                      s0_axi_rready;

   wire                                      s1_axi_aclk;
   wire                                      s1_axi_aresetn;
   wire [C_S1_AXI_ID_WIDTH-1:0]              s1_axi_awid; 
   wire [C_S1_AXI_ADDR_WIDTH-1:0]            s1_axi_awaddr; 
   wire [7:0]                                s1_axi_awlen; 
   wire [2:0]                                s1_axi_awsize; 
   wire [1:0]                                s1_axi_awburst; 
   wire [0:0]                                s1_axi_awlock; 
   wire [3:0]                                s1_axi_awcache; 
   wire [2:0]                                s1_axi_awprot; 
   wire [3:0]                                s1_axi_awqos; 
   wire                                      s1_axi_awvalid; 
   wire                                      s1_axi_awready; 
   wire [C_S1_AXI_DATA_WIDTH-1:0]            s1_axi_wdata; 
   wire [C_S1_AXI_DATA_WIDTH/8-1:0]          s1_axi_wstrb; 
   wire                                      s1_axi_wlast; 
   wire                                      s1_axi_wvalid; 
   wire                                      s1_axi_wready; 
   wire [C_S1_AXI_ID_WIDTH-1:0]              s1_axi_bid; 
   wire [1:0]                                s1_axi_bresp; 
   wire                                      s1_axi_bvalid; 
   wire                                      s1_axi_bready; 
   wire [C_S1_AXI_ID_WIDTH-1:0]              s1_axi_arid; 
   wire [C_S1_AXI_ADDR_WIDTH-1:0]            s1_axi_araddr; 
   wire [7:0]                                s1_axi_arlen; 
   wire [2:0]                                s1_axi_arsize; 
   wire [1:0]                                s1_axi_arburst; 
   wire [0:0]                                s1_axi_arlock; 
   wire [3:0]                                s1_axi_arcache; 
   wire [2:0]                                s1_axi_arprot; 
   wire [3:0]                                s1_axi_arqos; 
   wire                                      s1_axi_arvalid; 
   wire                                      s1_axi_arready; 
   wire [C_S1_AXI_ID_WIDTH-1:0]              s1_axi_rid; 
   wire [C_S1_AXI_DATA_WIDTH-1:0]            s1_axi_rdata; 
   wire [1:0]                                s1_axi_rresp; 
   wire                                      s1_axi_rlast; 
   wire                                      s1_axi_rvalid; 
   wire                                      s1_axi_rready;

   wire                                      s2_axi_aclk;
   wire                                      s2_axi_aresetn;
   wire [C_S2_AXI_ID_WIDTH-1:0]              s2_axi_awid; 
   wire [C_S2_AXI_ADDR_WIDTH-1:0]            s2_axi_awaddr; 
   wire [7:0]                                s2_axi_awlen; 
   wire [2:0]                                s2_axi_awsize; 
   wire [1:0]                                s2_axi_awburst; 
   wire [0:0]                                s2_axi_awlock; 
   wire [3:0]                                s2_axi_awcache; 
   wire [2:0]                                s2_axi_awprot; 
   wire [3:0]                                s2_axi_awqos; 
   wire                                      s2_axi_awvalid; 
   wire                                      s2_axi_awready; 
   wire [C_S2_AXI_DATA_WIDTH-1:0]            s2_axi_wdata; 
   wire [C_S2_AXI_DATA_WIDTH/8-1:0]          s2_axi_wstrb; 
   wire                                      s2_axi_wlast; 
   wire                                      s2_axi_wvalid; 
   wire                                      s2_axi_wready; 
   wire [C_S2_AXI_ID_WIDTH-1:0]              s2_axi_bid; 
   wire [1:0]                                s2_axi_bresp; 
   wire                                      s2_axi_bvalid; 
   wire                                      s2_axi_bready; 
   wire [C_S2_AXI_ID_WIDTH-1:0]              s2_axi_arid; 
   wire [C_S2_AXI_ADDR_WIDTH-1:0]            s2_axi_araddr; 
   wire [7:0]                                s2_axi_arlen; 
   wire [2:0]                                s2_axi_arsize; 
   wire [1:0]                                s2_axi_arburst; 
   wire [0:0]                                s2_axi_arlock; 
   wire [3:0]                                s2_axi_arcache; 
   wire [2:0]                                s2_axi_arprot; 
   wire [3:0]                                s2_axi_arqos; 
   wire                                      s2_axi_arvalid; 
   wire                                      s2_axi_arready; 
   wire [C_S2_AXI_ID_WIDTH-1:0]              s2_axi_rid; 
   wire [C_S2_AXI_DATA_WIDTH-1:0]            s2_axi_rdata; 
   wire [1:0]                                s2_axi_rresp; 
   wire                                      s2_axi_rlast; 
   wire                                      s2_axi_rvalid; 
   wire                                      s2_axi_rready;

   wire                                      s3_axi_aclk;
   wire                                      s3_axi_aresetn;
   wire [C_S3_AXI_ID_WIDTH-1:0]              s3_axi_awid; 
   wire [C_S3_AXI_ADDR_WIDTH-1:0]            s3_axi_awaddr; 
   wire [7:0]                                s3_axi_awlen; 
   wire [2:0]                                s3_axi_awsize; 
   wire [1:0]                                s3_axi_awburst; 
   wire [0:0]                                s3_axi_awlock; 
   wire [3:0]                                s3_axi_awcache; 
   wire [2:0]                                s3_axi_awprot; 
   wire [3:0]                                s3_axi_awqos; 
   wire                                      s3_axi_awvalid; 
   wire                                      s3_axi_awready; 
   wire [C_S3_AXI_DATA_WIDTH-1:0]            s3_axi_wdata; 
   wire [C_S3_AXI_DATA_WIDTH/8-1:0]          s3_axi_wstrb; 
   wire                                      s3_axi_wlast; 
   wire                                      s3_axi_wvalid; 
   wire                                      s3_axi_wready; 
   wire [C_S3_AXI_ID_WIDTH-1:0]              s3_axi_bid; 
   wire [1:0]                                s3_axi_bresp; 
   wire                                      s3_axi_bvalid; 
   wire                                      s3_axi_bready; 
   wire [C_S3_AXI_ID_WIDTH-1:0]              s3_axi_arid; 
   wire [C_S3_AXI_ADDR_WIDTH-1:0]            s3_axi_araddr; 
   wire [7:0]                                s3_axi_arlen; 
   wire [2:0]                                s3_axi_arsize; 
   wire [1:0]                                s3_axi_arburst; 
   wire [0:0]                                s3_axi_arlock; 
   wire [3:0]                                s3_axi_arcache; 
   wire [2:0]                                s3_axi_arprot; 
   wire [3:0]                                s3_axi_arqos; 
   wire                                      s3_axi_arvalid; 
   wire                                      s3_axi_arready; 
   wire [C_S3_AXI_ID_WIDTH-1:0]              s3_axi_rid; 
   wire [C_S3_AXI_DATA_WIDTH-1:0]            s3_axi_rdata; 
   wire [1:0]                                s3_axi_rresp; 
   wire                                      s3_axi_rlast; 
   wire                                      s3_axi_rvalid; 
   wire                                      s3_axi_rready;

   wire                                      s4_axi_aclk;
   wire                                      s4_axi_aresetn;
   wire [C_S4_AXI_ID_WIDTH-1:0]              s4_axi_awid; 
   wire [C_S4_AXI_ADDR_WIDTH-1:0]            s4_axi_awaddr; 
   wire [7:0]                                s4_axi_awlen; 
   wire [2:0]                                s4_axi_awsize; 
   wire [1:0]                                s4_axi_awburst; 
   wire [0:0]                                s4_axi_awlock; 
   wire [3:0]                                s4_axi_awcache; 
   wire [2:0]                                s4_axi_awprot; 
   wire [3:0]                                s4_axi_awqos; 
   wire                                      s4_axi_awvalid; 
   wire                                      s4_axi_awready; 
   wire [C_S4_AXI_DATA_WIDTH-1:0]            s4_axi_wdata; 
   wire [C_S4_AXI_DATA_WIDTH/8-1:0]          s4_axi_wstrb; 
   wire                                      s4_axi_wlast; 
   wire                                      s4_axi_wvalid; 
   wire                                      s4_axi_wready; 
   wire [C_S4_AXI_ID_WIDTH-1:0]              s4_axi_bid; 
   wire [1:0]                                s4_axi_bresp; 
   wire                                      s4_axi_bvalid; 
   wire                                      s4_axi_bready; 
   wire [C_S4_AXI_ID_WIDTH-1:0]              s4_axi_arid; 
   wire [C_S4_AXI_ADDR_WIDTH-1:0]            s4_axi_araddr; 
   wire [7:0]                                s4_axi_arlen; 
   wire [2:0]                                s4_axi_arsize; 
   wire [1:0]                                s4_axi_arburst; 
   wire [0:0]                                s4_axi_arlock; 
   wire [3:0]                                s4_axi_arcache; 
   wire [2:0]                                s4_axi_arprot; 
   wire [3:0]                                s4_axi_arqos; 
   wire                                      s4_axi_arvalid; 
   wire                                      s4_axi_arready; 
   wire [C_S4_AXI_ID_WIDTH-1:0]              s4_axi_rid; 
   wire [C_S4_AXI_DATA_WIDTH-1:0]            s4_axi_rdata; 
   wire [1:0]                                s4_axi_rresp; 
   wire                                      s4_axi_rlast; 
   wire                                      s4_axi_rvalid; 
   wire                                      s4_axi_rready;

   wire                                      s5_axi_aclk;
   wire                                      s5_axi_aresetn;
   wire [C_S5_AXI_ID_WIDTH-1:0]              s5_axi_awid; 
   wire [C_S5_AXI_ADDR_WIDTH-1:0]            s5_axi_awaddr; 
   wire [7:0]                                s5_axi_awlen; 
   wire [2:0]                                s5_axi_awsize; 
   wire [1:0]                                s5_axi_awburst; 
   wire [0:0]                                s5_axi_awlock; 
   wire [3:0]                                s5_axi_awcache; 
   wire [2:0]                                s5_axi_awprot; 
   wire [3:0]                                s5_axi_awqos; 
   wire                                      s5_axi_awvalid; 
   wire                                      s5_axi_awready; 
   wire [C_S5_AXI_DATA_WIDTH-1:0]            s5_axi_wdata; 
   wire [C_S5_AXI_DATA_WIDTH/8-1:0]          s5_axi_wstrb; 
   wire                                      s5_axi_wlast; 
   wire                                      s5_axi_wvalid; 
   wire                                      s5_axi_wready; 
   wire [C_S5_AXI_ID_WIDTH-1:0]              s5_axi_bid; 
   wire [1:0]                                s5_axi_bresp; 
   wire                                      s5_axi_bvalid; 
   wire                                      s5_axi_bready; 
   wire [C_S5_AXI_ID_WIDTH-1:0]              s5_axi_arid; 
   wire [C_S5_AXI_ADDR_WIDTH-1:0]            s5_axi_araddr; 
   wire [7:0]                                s5_axi_arlen; 
   wire [2:0]                                s5_axi_arsize; 
   wire [1:0]                                s5_axi_arburst; 
   wire [0:0]                                s5_axi_arlock; 
   wire [3:0]                                s5_axi_arcache; 
   wire [2:0]                                s5_axi_arprot; 
   wire [3:0]                                s5_axi_arqos; 
   wire                                      s5_axi_arvalid; 
   wire                                      s5_axi_arready; 
   wire [C_S5_AXI_ID_WIDTH-1:0]              s5_axi_rid; 
   wire [C_S5_AXI_DATA_WIDTH-1:0]            s5_axi_rdata; 
   wire [1:0]                                s5_axi_rresp; 
   wire                                      s5_axi_rlast; 
   wire                                      s5_axi_rvalid; 
   wire                                      s5_axi_rready;

   wire [7:0]                                uo_data;        
   wire                                      uo_data_valid;  
   wire                                      uo_cmd_ready_in;
   wire                                      uo_refrsh_flag; 
   wire                                      uo_cal_start;   
   wire                                      uo_sdo;
   wire [31:0]                               status;  
   wire                                      sysclk_2x_bufpll_o;
   wire                                      sysclk_2x_180_bufpll_o;
   wire                                      pll_ce_0_bufpll_o;
   wire                                      pll_ce_90_bufpll_o;
   wire                                      pll_lock_bufpll_o;


// mcb_ui_top instantiation
mcb_ui_top #
  (
   // Raw Wrapper Parameters
   .C_MEMCLK_PERIOD               (C_MEMCLK_PERIOD), 
   .C_PORT_ENABLE                 (C_PORT_ENABLE), 
   .C_MEM_ADDR_ORDER              (C_MEM_ADDR_ORDER), 
   .C_ARB_ALGORITHM               (C_ARB_ALGORITHM), 
   .C_ARB_NUM_TIME_SLOTS          (C_ARB_NUM_TIME_SLOTS), 
   .C_ARB_TIME_SLOT_0             (C_ARB_TIME_SLOT_0), 
   .C_ARB_TIME_SLOT_1             (C_ARB_TIME_SLOT_1), 
   .C_ARB_TIME_SLOT_2             (C_ARB_TIME_SLOT_2), 
   .C_ARB_TIME_SLOT_3             (C_ARB_TIME_SLOT_3), 
   .C_ARB_TIME_SLOT_4             (C_ARB_TIME_SLOT_4), 
   .C_ARB_TIME_SLOT_5             (C_ARB_TIME_SLOT_5), 
   .C_ARB_TIME_SLOT_6             (C_ARB_TIME_SLOT_6), 
   .C_ARB_TIME_SLOT_7             (C_ARB_TIME_SLOT_7), 
   .C_ARB_TIME_SLOT_8             (C_ARB_TIME_SLOT_8), 
   .C_ARB_TIME_SLOT_9             (C_ARB_TIME_SLOT_9), 
   .C_ARB_TIME_SLOT_10            (C_ARB_TIME_SLOT_10), 
   .C_ARB_TIME_SLOT_11            (C_ARB_TIME_SLOT_11), 
   .C_PORT_CONFIG                 (C_PORT_CONFIG), 
   .C_MEM_TRAS                    (C_MEM_TRAS), 
   .C_MEM_TRCD                    (C_MEM_TRCD), 
   .C_MEM_TREFI                   (C_MEM_TREFI), 
   .C_MEM_TRFC                    (C_MEM_TRFC), 
   .C_MEM_TRP                     (C_MEM_TRP), 
   .C_MEM_TWR                     (C_MEM_TWR), 
   .C_MEM_TRTP                    (C_MEM_TRTP), 
   .C_MEM_TWTR                    (C_MEM_TWTR), 
   .C_NUM_DQ_PINS                 (C_NUM_DQ_PINS), 
   .C_MEM_TYPE                    (C_MEM_TYPE), 
   .C_MEM_DENSITY                 (C_MEM_DENSITY), 
   .C_MEM_BURST_LEN               (C_MEM_BURST_LEN), 
   .C_MEM_CAS_LATENCY             (C_MEM_CAS_LATENCY), 
   .C_MEM_ADDR_WIDTH              (C_MEM_ADDR_WIDTH), 
   .C_MEM_BANKADDR_WIDTH          (C_MEM_BANKADDR_WIDTH), 
   .C_MEM_NUM_COL_BITS            (C_MEM_NUM_COL_BITS), 
   .C_MEM_DDR3_CAS_LATENCY        (C_MEM_DDR3_CAS_LATENCY), 
   .C_MEM_MOBILE_PA_SR            (C_MEM_MOBILE_PA_SR), 
   .C_MEM_DDR1_2_ODS              (C_MEM_DDR1_2_ODS), 
   .C_MEM_DDR3_ODS                (C_MEM_DDR3_ODS), 
   .C_MEM_DDR2_RTT                (C_MEM_DDR2_RTT), 
   .C_MEM_DDR3_RTT                (C_MEM_DDR3_RTT), 
   .C_MEM_MDDR_ODS                (C_MEM_MDDR_ODS), 
   .C_MEM_DDR2_DIFF_DQS_EN        (C_MEM_DDR2_DIFF_DQS_EN), 
   .C_MEM_DDR2_3_PA_SR            (C_MEM_DDR2_3_PA_SR), 
   .C_MEM_DDR3_CAS_WR_LATENCY     (C_MEM_DDR3_CAS_WR_LATENCY), 
   .C_MEM_DDR3_AUTO_SR            (C_MEM_DDR3_AUTO_SR), 
   .C_MEM_DDR2_3_HIGH_TEMP_SR     (C_MEM_DDR2_3_HIGH_TEMP_SR), 
   .C_MEM_DDR3_DYN_WRT_ODT        (C_MEM_DDR3_DYN_WRT_ODT), 
   .C_MEM_TZQINIT_MAXCNT          (C_MEM_TZQINIT_MAXCNT), 
   .C_MC_CALIB_BYPASS             (C_MC_CALIB_BYPASS), 
   .C_MC_CALIBRATION_RA           (C_MC_CALIBRATION_RA),
   .C_MC_CALIBRATION_BA           (C_MC_CALIBRATION_BA),
   .C_MC_CALIBRATION_CA           (C_MC_CALIBRATION_CA),
   .C_CALIB_SOFT_IP               (C_CALIB_SOFT_IP), 
   .C_SKIP_IN_TERM_CAL            (C_SKIP_IN_TERM_CAL), 
   .C_SKIP_DYNAMIC_CAL            (C_SKIP_DYNAMIC_CAL), 
   .C_SKIP_DYN_IN_TERM            (C_SKIP_DYN_IN_TERM), 
   .LDQSP_TAP_DELAY_VAL           (LDQSP_TAP_DELAY_VAL), 
   .UDQSP_TAP_DELAY_VAL           (UDQSP_TAP_DELAY_VAL), 
   .LDQSN_TAP_DELAY_VAL           (LDQSN_TAP_DELAY_VAL), 
   .UDQSN_TAP_DELAY_VAL           (UDQSN_TAP_DELAY_VAL), 
   .DQ0_TAP_DELAY_VAL             (DQ0_TAP_DELAY_VAL), 
   .DQ1_TAP_DELAY_VAL             (DQ1_TAP_DELAY_VAL), 
   .DQ2_TAP_DELAY_VAL             (DQ2_TAP_DELAY_VAL), 
   .DQ3_TAP_DELAY_VAL             (DQ3_TAP_DELAY_VAL), 
   .DQ4_TAP_DELAY_VAL             (DQ4_TAP_DELAY_VAL), 
   .DQ5_TAP_DELAY_VAL             (DQ5_TAP_DELAY_VAL), 
   .DQ6_TAP_DELAY_VAL             (DQ6_TAP_DELAY_VAL), 
   .DQ7_TAP_DELAY_VAL             (DQ7_TAP_DELAY_VAL), 
   .DQ8_TAP_DELAY_VAL             (DQ8_TAP_DELAY_VAL), 
   .DQ9_TAP_DELAY_VAL             (DQ9_TAP_DELAY_VAL), 
   .DQ10_TAP_DELAY_VAL            (DQ10_TAP_DELAY_VAL), 
   .DQ11_TAP_DELAY_VAL            (DQ11_TAP_DELAY_VAL), 
   .DQ12_TAP_DELAY_VAL            (DQ12_TAP_DELAY_VAL), 
   .DQ13_TAP_DELAY_VAL            (DQ13_TAP_DELAY_VAL), 
   .DQ14_TAP_DELAY_VAL            (DQ14_TAP_DELAY_VAL), 
   .DQ15_TAP_DELAY_VAL            (DQ15_TAP_DELAY_VAL), 
   .C_MC_CALIBRATION_CLK_DIV      (C_MC_CALIBRATION_CLK_DIV), 
   .C_MC_CALIBRATION_MODE         (C_MC_CALIBRATION_MODE), 
   .C_MC_CALIBRATION_DELAY        (C_MC_CALIBRATION_DELAY),
   .C_SIMULATION                  (C_SIMULATION), 
   .C_P0_MASK_SIZE                (C_P0_MASK_SIZE), 
   .C_P0_DATA_PORT_SIZE           (C_P0_DATA_PORT_SIZE), 
   .C_P1_MASK_SIZE                (C_P1_MASK_SIZE), 
   .C_P1_DATA_PORT_SIZE           (C_P1_DATA_PORT_SIZE), 
   .C_MCB_USE_EXTERNAL_BUFPLL     (C_MCB_USE_EXTERNAL_BUFPLL)
  )
mcb_ui_top_inst
  (
   // Raw Wrapper Signals
   .sysclk_2x                     (sysclk_2x),          
   .sysclk_2x_180                 (sysclk_2x_180), 
   .pll_ce_0                      (pll_ce_0),
   .pll_ce_90                     (pll_ce_90), 
   .pll_lock                      (pll_lock),
   .sysclk_2x_bufpll_o            (sysclk_2x_bufpll_o),     
   .sysclk_2x_180_bufpll_o        (sysclk_2x_180_bufpll_o),
   .pll_ce_0_bufpll_o             (pll_ce_0_bufpll_o),
   .pll_ce_90_bufpll_o            (pll_ce_90_bufpll_o),
   .pll_lock_bufpll_o             (pll_lock_bufpll_o),   
   .sys_rst                       (async_rst),
   .p0_arb_en                     (1'b1), 
   .p0_cmd_clk                    (p0_cmd_clk),
   .p0_cmd_en                     (p0_cmd_en), 
   .p0_cmd_instr                  (p0_cmd_instr),
   .p0_cmd_bl                     (p0_cmd_bl), 
   .p0_cmd_byte_addr              (p0_cmd_byte_addr),       
   .p0_cmd_empty                  (p0_cmd_empty),
   .p0_cmd_full                   (p0_cmd_full),
   .p0_wr_clk                     (p0_wr_clk), 
   .p0_wr_en                      (p0_wr_en),
   .p0_wr_mask                    (p0_wr_mask),
   .p0_wr_data                    (p0_wr_data),
   .p0_wr_full                    (p0_wr_full),
   .p0_wr_empty                   (p0_wr_empty),
   .p0_wr_count                   (p0_wr_count),
   .p0_wr_underrun                (p0_wr_underrun),  
   .p0_wr_error                   (p0_wr_error),
   .p0_rd_clk                     (p0_rd_clk), 
   .p0_rd_en                      (p0_rd_en),
   .p0_rd_data                    (p0_rd_data),
   .p0_rd_full                    (p0_rd_full),
   .p0_rd_empty                   (p0_rd_empty),
   .p0_rd_count                   (p0_rd_count),
   .p0_rd_overflow                (p0_rd_overflow),  
   .p0_rd_error                   (p0_rd_error),
   .p1_arb_en                     (1'b1), 
   .p1_cmd_clk                    (p1_cmd_clk),
   .p1_cmd_en                     (p1_cmd_en), 
   .p1_cmd_instr                  (p1_cmd_instr),
   .p1_cmd_bl                     (p1_cmd_bl), 
   .p1_cmd_byte_addr              (p1_cmd_byte_addr),       
   .p1_cmd_empty                  (p1_cmd_empty),
   .p1_cmd_full                   (p1_cmd_full),
   .p1_wr_clk                     (p1_wr_clk), 
   .p1_wr_en                      (p1_wr_en),
   .p1_wr_mask                    (p1_wr_mask),
   .p1_wr_data                    (p1_wr_data),
   .p1_wr_full                    (p1_wr_full),
   .p1_wr_empty                   (p1_wr_empty),
   .p1_wr_count                   (p1_wr_count),
   .p1_wr_underrun                (p1_wr_underrun),  
   .p1_wr_error                   (p1_wr_error),
   .p1_rd_clk                     (p1_rd_clk), 
   .p1_rd_en                      (p1_rd_en),
   .p1_rd_data                    (p1_rd_data),
   .p1_rd_full                    (p1_rd_full),
   .p1_rd_empty                   (p1_rd_empty),
   .p1_rd_count                   (p1_rd_count),
   .p1_rd_overflow                (p1_rd_overflow),  
   .p1_rd_error                   (p1_rd_error),
   .p2_arb_en                     (1'b1), 
   .p2_cmd_clk                    (p2_cmd_clk),
   .p2_cmd_en                     (p2_cmd_en), 
   .p2_cmd_instr                  (p2_cmd_instr),
   .p2_cmd_bl                     (p2_cmd_bl), 
   .p2_cmd_byte_addr              (p2_cmd_byte_addr),       
   .p2_cmd_empty                  (p2_cmd_empty),
   .p2_cmd_full                   (p2_cmd_full),
   .p2_wr_clk                     (p2_wr_clk), 
   .p2_wr_en                      (p2_wr_en),
   .p2_wr_mask                    (p2_wr_mask),
   .p2_wr_data                    (p2_wr_data),
   .p2_wr_full                    (p2_wr_full),
   .p2_wr_empty                   (p2_wr_empty),
   .p2_wr_count                   (p2_wr_count),
   .p2_wr_underrun                (p2_wr_underrun),  
   .p2_wr_error                   (p2_wr_error),
   .p2_rd_clk                     (p2_rd_clk), 
   .p2_rd_en                      (p2_rd_en),
   .p2_rd_data                    (p2_rd_data),
   .p2_rd_full                    (p2_rd_full),
   .p2_rd_empty                   (p2_rd_empty),
   .p2_rd_count                   (p2_rd_count),
   .p2_rd_overflow                (p2_rd_overflow),  
   .p2_rd_error                   (p2_rd_error),
   .p3_arb_en                     (1'b1), 
   .p3_cmd_clk                    (p3_cmd_clk),
   .p3_cmd_en                     (p3_cmd_en), 
   .p3_cmd_instr                  (p3_cmd_instr),
   .p3_cmd_bl                     (p3_cmd_bl), 
   .p3_cmd_byte_addr              (p3_cmd_byte_addr),       
   .p3_cmd_empty                  (p3_cmd_empty),
   .p3_cmd_full                   (p3_cmd_full),
   .p3_wr_clk                     (p3_wr_clk), 
   .p3_wr_en                      (p3_wr_en),
   .p3_wr_mask                    (p3_wr_mask),
   .p3_wr_data                    (p3_wr_data),
   .p3_wr_full                    (p3_wr_full),
   .p3_wr_empty                   (p3_wr_empty),
   .p3_wr_count                   (p3_wr_count),
   .p3_wr_underrun                (p3_wr_underrun),  
   .p3_wr_error                   (p3_wr_error),
   .p3_rd_clk                     (p3_rd_clk), 
   .p3_rd_en                      (p3_rd_en),
   .p3_rd_data                    (p3_rd_data),
   .p3_rd_full                    (p3_rd_full),
   .p3_rd_empty                   (p3_rd_empty),
   .p3_rd_count                   (p3_rd_count),
   .p3_rd_overflow                (p3_rd_overflow),  
   .p3_rd_error                   (p3_rd_error),
   .p4_arb_en                     (1'b1), 
   .p4_cmd_clk                    (p4_cmd_clk),
   .p4_cmd_en                     (p4_cmd_en), 
   .p4_cmd_instr                  (p4_cmd_instr),
   .p4_cmd_bl                     (p4_cmd_bl), 
   .p4_cmd_byte_addr              (p4_cmd_byte_addr),       
   .p4_cmd_empty                  (p4_cmd_empty),
   .p4_cmd_full                   (p4_cmd_full),
   .p4_wr_clk                     (p4_wr_clk), 
   .p4_wr_en                      (p4_wr_en),
   .p4_wr_mask                    (p4_wr_mask),
   .p4_wr_data                    (p4_wr_data),
   .p4_wr_full                    (p4_wr_full),
   .p4_wr_empty                   (p4_wr_empty),
   .p4_wr_count                   (p4_wr_count),
   .p4_wr_underrun                (p4_wr_underrun),  
   .p4_wr_error                   (p4_wr_error),
   .p4_rd_clk                     (p4_rd_clk), 
   .p4_rd_en                      (p4_rd_en),
   .p4_rd_data                    (p4_rd_data),
   .p4_rd_full                    (p4_rd_full),
   .p4_rd_empty                   (p4_rd_empty),
   .p4_rd_count                   (p4_rd_count),
   .p4_rd_overflow                (p4_rd_overflow),  
   .p4_rd_error                   (p4_rd_error),
   .p5_arb_en                     (1'b1), 
   .p5_cmd_clk                    (p5_cmd_clk),
   .p5_cmd_en                     (p5_cmd_en), 
   .p5_cmd_instr                  (p5_cmd_instr),
   .p5_cmd_bl                     (p5_cmd_bl), 
   .p5_cmd_byte_addr              (p5_cmd_byte_addr),       
   .p5_cmd_empty                  (p5_cmd_empty),
   .p5_cmd_full                   (p5_cmd_full),
   .p5_wr_clk                     (p5_wr_clk), 
   .p5_wr_en                      (p5_wr_en),
   .p5_wr_mask                    (p5_wr_mask),
   .p5_wr_data                    (p5_wr_data),
   .p5_wr_full                    (p5_wr_full),
   .p5_wr_empty                   (p5_wr_empty),
   .p5_wr_count                   (p5_wr_count),
   .p5_wr_underrun                (p5_wr_underrun),  
   .p5_wr_error                   (p5_wr_error),
   .p5_rd_clk                     (p5_rd_clk), 
   .p5_rd_en                      (p5_rd_en),
   .p5_rd_data                    (p5_rd_data),
   .p5_rd_full                    (p5_rd_full),
   .p5_rd_empty                   (p5_rd_empty),
   .p5_rd_count                   (p5_rd_count),
   .p5_rd_overflow                (p5_rd_overflow),  
   .p5_rd_error                   (p5_rd_error),
   .mcbx_dram_addr                (mcbx_dram_addr),  
   .mcbx_dram_ba                  (mcbx_dram_ba),
   .mcbx_dram_ras_n               (mcbx_dram_ras_n),       
   .mcbx_dram_cas_n               (mcbx_dram_cas_n),       
   .mcbx_dram_we_n                (mcbx_dram_we_n),  
   .mcbx_dram_cke                 (mcbx_dram_cke), 
   .mcbx_dram_clk                 (mcbx_dram_clk), 
   .mcbx_dram_clk_n               (mcbx_dram_clk_n),       
   .mcbx_dram_dq                  (mcbx_dram_dq),
   .mcbx_dram_dqs                 (mcbx_dram_dqs), 
   .mcbx_dram_dqs_n               (mcbx_dram_dqs_n),       
   .mcbx_dram_udqs                (mcbx_dram_udqs),  
   .mcbx_dram_udqs_n              (mcbx_dram_udqs_n),       
   .mcbx_dram_udm                 (mcbx_dram_udm), 
   .mcbx_dram_ldm                 (mcbx_dram_ldm), 
   .mcbx_dram_odt                 (mcbx_dram_odt), 
   .mcbx_dram_ddr3_rst            (mcbx_dram_ddr3_rst),      
   .calib_recal                   (1'b0),
   .rzq                           (mcbx_rzq),
   .zio                           (mcbx_zio),
   .ui_read                       (1'b0),
   .ui_add                        (1'b0),
   .ui_cs                         (1'b0),
   .ui_clk                        (mcb_drp_clk),
   .ui_sdi                        (1'b0),
   .ui_addr                       (5'b0),
   .ui_broadcast                  (1'b0),
   .ui_drp_update                 (1'b0), 
   .ui_done_cal                   (1'b1),
   .ui_cmd                        (1'b0),
   .ui_cmd_in                     (1'b0), 
   .ui_cmd_en                     (1'b0), 
   .ui_dqcount                    (4'b0),
   .ui_dq_lower_dec               (1'b0),       
   .ui_dq_lower_inc               (1'b0),       
   .ui_dq_upper_dec               (1'b0),       
   .ui_dq_upper_inc               (1'b0),       
   .ui_udqs_inc                   (1'b0),
   .ui_udqs_dec                   (1'b0),
   .ui_ldqs_inc                   (1'b0),
   .ui_ldqs_dec                   (1'b0),
   .uo_data                       (uo_data),
   .uo_data_valid                 (uo_data_valid), 
   .uo_done_cal                   (calib_done),
   .uo_cmd_ready_in               (uo_cmd_ready_in),       
   .uo_refrsh_flag                (uo_refrsh_flag),  
   .uo_cal_start                  (uo_cal_start),
   .uo_sdo                        (uo_sdo),
   .status                        (status),
   .selfrefresh_enter             (selfrefresh_enter),       
   .selfrefresh_mode              (selfrefresh_mode),

   // AXI Signals                 
   .s0_axi_aclk                   (s0_axi_aclk),
   .s0_axi_aresetn                (s0_axi_aresetn),
   .s0_axi_awid                   (s0_axi_awid), 
   .s0_axi_awaddr                 (s0_axi_awaddr), 
   .s0_axi_awlen                  (s0_axi_awlen), 
   .s0_axi_awsize                 (s0_axi_awsize), 
   .s0_axi_awburst                (s0_axi_awburst), 
   .s0_axi_awlock                 (s0_axi_awlock), 
   .s0_axi_awcache                (s0_axi_awcache), 
   .s0_axi_awprot                 (s0_axi_awprot), 
   .s0_axi_awqos                  (s0_axi_awqos), 
   .s0_axi_awvalid                (s0_axi_awvalid), 
   .s0_axi_awready                (s0_axi_awready), 
   .s0_axi_wdata                  (s0_axi_wdata), 
   .s0_axi_wstrb                  (s0_axi_wstrb), 
   .s0_axi_wlast                  (s0_axi_wlast), 
   .s0_axi_wvalid                 (s0_axi_wvalid), 
   .s0_axi_wready                 (s0_axi_wready), 
   .s0_axi_bid                    (s0_axi_bid), 
   .s0_axi_bresp                  (s0_axi_bresp), 
   .s0_axi_bvalid                 (s0_axi_bvalid), 
   .s0_axi_bready                 (s0_axi_bready), 
   .s0_axi_arid                   (s0_axi_arid), 
   .s0_axi_araddr                 (s0_axi_araddr), 
   .s0_axi_arlen                  (s0_axi_arlen), 
   .s0_axi_arsize                 (s0_axi_arsize), 
   .s0_axi_arburst                (s0_axi_arburst), 
   .s0_axi_arlock                 (s0_axi_arlock), 
   .s0_axi_arcache                (s0_axi_arcache), 
   .s0_axi_arprot                 (s0_axi_arprot), 
   .s0_axi_arqos                  (s0_axi_arqos), 
   .s0_axi_arvalid                (s0_axi_arvalid), 
   .s0_axi_arready                (s0_axi_arready), 
   .s0_axi_rid                    (s0_axi_rid), 
   .s0_axi_rdata                  (s0_axi_rdata), 
   .s0_axi_rresp                  (s0_axi_rresp), 
   .s0_axi_rlast                  (s0_axi_rlast), 
   .s0_axi_rvalid                 (s0_axi_rvalid), 
   .s0_axi_rready                 (s0_axi_rready),
                                                   
   .s1_axi_aclk                   (s1_axi_aclk),
   .s1_axi_aresetn                (s1_axi_aresetn),
   .s1_axi_awid                   (s1_axi_awid), 
   .s1_axi_awaddr                 (s1_axi_awaddr), 
   .s1_axi_awlen                  (s1_axi_awlen), 
   .s1_axi_awsize                 (s1_axi_awsize), 
   .s1_axi_awburst                (s1_axi_awburst), 
   .s1_axi_awlock                 (s1_axi_awlock), 
   .s1_axi_awcache                (s1_axi_awcache), 
   .s1_axi_awprot                 (s1_axi_awprot), 
   .s1_axi_awqos                  (s1_axi_awqos), 
   .s1_axi_awvalid                (s1_axi_awvalid), 
   .s1_axi_awready                (s1_axi_awready), 
   .s1_axi_wdata                  (s1_axi_wdata), 
   .s1_axi_wstrb                  (s1_axi_wstrb), 
   .s1_axi_wlast                  (s1_axi_wlast), 
   .s1_axi_wvalid                 (s1_axi_wvalid), 
   .s1_axi_wready                 (s1_axi_wready), 
   .s1_axi_bid                    (s1_axi_bid), 
   .s1_axi_bresp                  (s1_axi_bresp), 
   .s1_axi_bvalid                 (s1_axi_bvalid), 
   .s1_axi_bready                 (s1_axi_bready), 
   .s1_axi_arid                   (s1_axi_arid), 
   .s1_axi_araddr                 (s1_axi_araddr), 
   .s1_axi_arlen                  (s1_axi_arlen), 
   .s1_axi_arsize                 (s1_axi_arsize), 
   .s1_axi_arburst                (s1_axi_arburst), 
   .s1_axi_arlock                 (s1_axi_arlock), 
   .s1_axi_arcache                (s1_axi_arcache), 
   .s1_axi_arprot                 (s1_axi_arprot), 
   .s1_axi_arqos                  (s1_axi_arqos), 
   .s1_axi_arvalid                (s1_axi_arvalid), 
   .s1_axi_arready                (s1_axi_arready), 
   .s1_axi_rid                    (s1_axi_rid), 
   .s1_axi_rdata                  (s1_axi_rdata), 
   .s1_axi_rresp                  (s1_axi_rresp), 
   .s1_axi_rlast                  (s1_axi_rlast), 
   .s1_axi_rvalid                 (s1_axi_rvalid), 
   .s1_axi_rready                 (s1_axi_rready),
                                                   
   .s2_axi_aclk                   (s2_axi_aclk),
   .s2_axi_aresetn                (s2_axi_aresetn),
   .s2_axi_awid                   (s2_axi_awid), 
   .s2_axi_awaddr                 (s2_axi_awaddr), 
   .s2_axi_awlen                  (s2_axi_awlen), 
   .s2_axi_awsize                 (s2_axi_awsize), 
   .s2_axi_awburst                (s2_axi_awburst), 
   .s2_axi_awlock                 (s2_axi_awlock), 
   .s2_axi_awcache                (s2_axi_awcache), 
   .s2_axi_awprot                 (s2_axi_awprot), 
   .s2_axi_awqos                  (s2_axi_awqos), 
   .s2_axi_awvalid                (s2_axi_awvalid), 
   .s2_axi_awready                (s2_axi_awready), 
   .s2_axi_wdata                  (s2_axi_wdata), 
   .s2_axi_wstrb                  (s2_axi_wstrb), 
   .s2_axi_wlast                  (s2_axi_wlast), 
   .s2_axi_wvalid                 (s2_axi_wvalid), 
   .s2_axi_wready                 (s2_axi_wready), 
   .s2_axi_bid                    (s2_axi_bid), 
   .s2_axi_bresp                  (s2_axi_bresp), 
   .s2_axi_bvalid                 (s2_axi_bvalid), 
   .s2_axi_bready                 (s2_axi_bready), 
   .s2_axi_arid                   (s2_axi_arid), 
   .s2_axi_araddr                 (s2_axi_araddr), 
   .s2_axi_arlen                  (s2_axi_arlen), 
   .s2_axi_arsize                 (s2_axi_arsize), 
   .s2_axi_arburst                (s2_axi_arburst), 
   .s2_axi_arlock                 (s2_axi_arlock), 
   .s2_axi_arcache                (s2_axi_arcache), 
   .s2_axi_arprot                 (s2_axi_arprot), 
   .s2_axi_arqos                  (s2_axi_arqos), 
   .s2_axi_arvalid                (s2_axi_arvalid), 
   .s2_axi_arready                (s2_axi_arready), 
   .s2_axi_rid                    (s2_axi_rid), 
   .s2_axi_rdata                  (s2_axi_rdata), 
   .s2_axi_rresp                  (s2_axi_rresp), 
   .s2_axi_rlast                  (s2_axi_rlast), 
   .s2_axi_rvalid                 (s2_axi_rvalid), 
   .s2_axi_rready                 (s2_axi_rready),
                                                   
   .s3_axi_aclk                   (s3_axi_aclk),
   .s3_axi_aresetn                (s3_axi_aresetn),
   .s3_axi_awid                   (s3_axi_awid), 
   .s3_axi_awaddr                 (s3_axi_awaddr), 
   .s3_axi_awlen                  (s3_axi_awlen), 
   .s3_axi_awsize                 (s3_axi_awsize), 
   .s3_axi_awburst                (s3_axi_awburst), 
   .s3_axi_awlock                 (s3_axi_awlock), 
   .s3_axi_awcache                (s3_axi_awcache), 
   .s3_axi_awprot                 (s3_axi_awprot), 
   .s3_axi_awqos                  (s3_axi_awqos), 
   .s3_axi_awvalid                (s3_axi_awvalid), 
   .s3_axi_awready                (s3_axi_awready), 
   .s3_axi_wdata                  (s3_axi_wdata), 
   .s3_axi_wstrb                  (s3_axi_wstrb), 
   .s3_axi_wlast                  (s3_axi_wlast), 
   .s3_axi_wvalid                 (s3_axi_wvalid), 
   .s3_axi_wready                 (s3_axi_wready), 
   .s3_axi_bid                    (s3_axi_bid), 
   .s3_axi_bresp                  (s3_axi_bresp), 
   .s3_axi_bvalid                 (s3_axi_bvalid), 
   .s3_axi_bready                 (s3_axi_bready), 
   .s3_axi_arid                   (s3_axi_arid), 
   .s3_axi_araddr                 (s3_axi_araddr), 
   .s3_axi_arlen                  (s3_axi_arlen), 
   .s3_axi_arsize                 (s3_axi_arsize), 
   .s3_axi_arburst                (s3_axi_arburst), 
   .s3_axi_arlock                 (s3_axi_arlock), 
   .s3_axi_arcache                (s3_axi_arcache), 
   .s3_axi_arprot                 (s3_axi_arprot), 
   .s3_axi_arqos                  (s3_axi_arqos), 
   .s3_axi_arvalid                (s3_axi_arvalid), 
   .s3_axi_arready                (s3_axi_arready), 
   .s3_axi_rid                    (s3_axi_rid), 
   .s3_axi_rdata                  (s3_axi_rdata), 
   .s3_axi_rresp                  (s3_axi_rresp), 
   .s3_axi_rlast                  (s3_axi_rlast), 
   .s3_axi_rvalid                 (s3_axi_rvalid), 
   .s3_axi_rready                 (s3_axi_rready),
                                                   
   .s4_axi_aclk                   (s4_axi_aclk),
   .s4_axi_aresetn                (s4_axi_aresetn),
   .s4_axi_awid                   (s4_axi_awid), 
   .s4_axi_awaddr                 (s4_axi_awaddr), 
   .s4_axi_awlen                  (s4_axi_awlen), 
   .s4_axi_awsize                 (s4_axi_awsize), 
   .s4_axi_awburst                (s4_axi_awburst), 
   .s4_axi_awlock                 (s4_axi_awlock), 
   .s4_axi_awcache                (s4_axi_awcache), 
   .s4_axi_awprot                 (s4_axi_awprot), 
   .s4_axi_awqos                  (s4_axi_awqos), 
   .s4_axi_awvalid                (s4_axi_awvalid), 
   .s4_axi_awready                (s4_axi_awready), 
   .s4_axi_wdata                  (s4_axi_wdata), 
   .s4_axi_wstrb                  (s4_axi_wstrb), 
   .s4_axi_wlast                  (s4_axi_wlast), 
   .s4_axi_wvalid                 (s4_axi_wvalid), 
   .s4_axi_wready                 (s4_axi_wready), 
   .s4_axi_bid                    (s4_axi_bid), 
   .s4_axi_bresp                  (s4_axi_bresp), 
   .s4_axi_bvalid                 (s4_axi_bvalid), 
   .s4_axi_bready                 (s4_axi_bready), 
   .s4_axi_arid                   (s4_axi_arid), 
   .s4_axi_araddr                 (s4_axi_araddr), 
   .s4_axi_arlen                  (s4_axi_arlen), 
   .s4_axi_arsize                 (s4_axi_arsize), 
   .s4_axi_arburst                (s4_axi_arburst), 
   .s4_axi_arlock                 (s4_axi_arlock), 
   .s4_axi_arcache                (s4_axi_arcache), 
   .s4_axi_arprot                 (s4_axi_arprot), 
   .s4_axi_arqos                  (s4_axi_arqos), 
   .s4_axi_arvalid                (s4_axi_arvalid), 
   .s4_axi_arready                (s4_axi_arready), 
   .s4_axi_rid                    (s4_axi_rid), 
   .s4_axi_rdata                  (s4_axi_rdata), 
   .s4_axi_rresp                  (s4_axi_rresp), 
   .s4_axi_rlast                  (s4_axi_rlast), 
   .s4_axi_rvalid                 (s4_axi_rvalid), 
   .s4_axi_rready                 (s4_axi_rready),
                                                   
   .s5_axi_aclk                   (s5_axi_aclk),
   .s5_axi_aresetn                (s5_axi_aresetn),
   .s5_axi_awid                   (s5_axi_awid), 
   .s5_axi_awaddr                 (s5_axi_awaddr), 
   .s5_axi_awlen                  (s5_axi_awlen), 
   .s5_axi_awsize                 (s5_axi_awsize), 
   .s5_axi_awburst                (s5_axi_awburst), 
   .s5_axi_awlock                 (s5_axi_awlock), 
   .s5_axi_awcache                (s5_axi_awcache), 
   .s5_axi_awprot                 (s5_axi_awprot), 
   .s5_axi_awqos                  (s5_axi_awqos), 
   .s5_axi_awvalid                (s5_axi_awvalid), 
   .s5_axi_awready                (s5_axi_awready), 
   .s5_axi_wdata                  (s5_axi_wdata), 
   .s5_axi_wstrb                  (s5_axi_wstrb), 
   .s5_axi_wlast                  (s5_axi_wlast), 
   .s5_axi_wvalid                 (s5_axi_wvalid), 
   .s5_axi_wready                 (s5_axi_wready), 
   .s5_axi_bid                    (s5_axi_bid), 
   .s5_axi_bresp                  (s5_axi_bresp), 
   .s5_axi_bvalid                 (s5_axi_bvalid), 
   .s5_axi_bready                 (s5_axi_bready), 
   .s5_axi_arid                   (s5_axi_arid), 
   .s5_axi_araddr                 (s5_axi_araddr), 
   .s5_axi_arlen                  (s5_axi_arlen), 
   .s5_axi_arsize                 (s5_axi_arsize), 
   .s5_axi_arburst                (s5_axi_arburst), 
   .s5_axi_arlock                 (s5_axi_arlock), 
   .s5_axi_arcache                (s5_axi_arcache), 
   .s5_axi_arprot                 (s5_axi_arprot), 
   .s5_axi_arqos                  (s5_axi_arqos), 
   .s5_axi_arvalid                (s5_axi_arvalid), 
   .s5_axi_arready                (s5_axi_arready), 
   .s5_axi_rid                    (s5_axi_rid), 
   .s5_axi_rdata                  (s5_axi_rdata), 
   .s5_axi_rresp                  (s5_axi_rresp), 
   .s5_axi_rlast                  (s5_axi_rlast), 
   .s5_axi_rvalid                 (s5_axi_rvalid), 
   .s5_axi_rready                 (s5_axi_rready)
  );

endmodule
