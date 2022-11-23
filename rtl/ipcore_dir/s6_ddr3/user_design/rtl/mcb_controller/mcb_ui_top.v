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
//Device: Spartan6
//Design Name: DDR/DDR2/DDR3/LPDDR
//Purpose:
//Reference:
//   This module instantiates the AXI bridges
//
//*****************************************************************************
`timescale 1ps / 1ps

module mcb_ui_top #
   (
///////////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////////
   // Raw Wrapper Parameters
   parameter         C_MEMCLK_PERIOD           = 2500,
   parameter         C_PORT_ENABLE             = 6'b111111,
   parameter         C_MEM_ADDR_ORDER          = "BANK_ROW_COLUMN",
   parameter         C_USR_INTERFACE_MODE      = "NATIVE",
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
   parameter         C_PORT_CONFIG             = "B128",
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
   parameter         C_MEM_TZQINIT_MAXCNT      = 10'd512,
   parameter         C_MC_CALIB_BYPASS         = "NO",
   parameter         C_MC_CALIBRATION_RA       = 15'h0000,
   parameter         C_MC_CALIBRATION_BA       = 3'h0,
   parameter         C_CALIB_SOFT_IP           = "TRUE",
   parameter         C_SKIP_IN_TERM_CAL        = 1'b0,
   parameter         C_SKIP_DYNAMIC_CAL        = 1'b0,
   parameter         C_SKIP_DYN_IN_TERM        = 1'b1,
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
   parameter         C_MC_CALIBRATION_CA       = 12'h000,
   parameter         C_MC_CALIBRATION_CLK_DIV  = 1,
   parameter         C_MC_CALIBRATION_MODE     = "CALIBRATION",
   parameter         C_MC_CALIBRATION_DELAY    = "HALF",
   parameter         C_SIMULATION              = "FALSE",
   parameter         C_P0_MASK_SIZE            = 4,
   parameter         C_P0_DATA_PORT_SIZE       = 32,
   parameter         C_P1_MASK_SIZE            = 4,
   parameter         C_P1_DATA_PORT_SIZE       = 32,
   parameter integer C_MCB_USE_EXTERNAL_BUFPLL = 1,
   // AXI Parameters
   parameter         C_S0_AXI_BASEADDR         = 32'h00000000,
   parameter         C_S0_AXI_HIGHADDR         = 32'h00000000,
   parameter integer C_S0_AXI_ENABLE           = 0,
   parameter integer C_S0_AXI_ID_WIDTH         = 4,
   parameter integer C_S0_AXI_ADDR_WIDTH       = 64,
   parameter integer C_S0_AXI_DATA_WIDTH       = 32,
   parameter integer C_S0_AXI_SUPPORTS_READ    = 1,
   parameter integer C_S0_AXI_SUPPORTS_WRITE   = 1,
   parameter integer C_S0_AXI_SUPPORTS_NARROW_BURST  = 1,
   parameter         C_S0_AXI_REG_EN0          = 20'h00000,
   parameter         C_S0_AXI_REG_EN1          = 20'h01000,
   parameter integer C_S0_AXI_STRICT_COHERENCY = 1,
   parameter integer C_S0_AXI_ENABLE_AP        = 0,
   parameter         C_S1_AXI_BASEADDR         = 32'h00000000,
   parameter         C_S1_AXI_HIGHADDR         = 32'h00000000,
   parameter integer C_S1_AXI_ENABLE           = 0,
   parameter integer C_S1_AXI_ID_WIDTH         = 4,
   parameter integer C_S1_AXI_ADDR_WIDTH       = 64,
   parameter integer C_S1_AXI_DATA_WIDTH       = 32,
   parameter integer C_S1_AXI_SUPPORTS_READ    = 1,
   parameter integer C_S1_AXI_SUPPORTS_WRITE   = 1,
   parameter integer C_S1_AXI_SUPPORTS_NARROW_BURST  = 1,
   parameter         C_S1_AXI_REG_EN0          = 20'h00000,
   parameter         C_S1_AXI_REG_EN1          = 20'h01000,
   parameter integer C_S1_AXI_STRICT_COHERENCY = 1,
   parameter integer C_S1_AXI_ENABLE_AP        = 0,
   parameter         C_S2_AXI_BASEADDR         = 32'h00000000,
   parameter         C_S2_AXI_HIGHADDR         = 32'h00000000,
   parameter integer C_S2_AXI_ENABLE           = 0,
   parameter integer C_S2_AXI_ID_WIDTH         = 4,
   parameter integer C_S2_AXI_ADDR_WIDTH       = 64,
   parameter integer C_S2_AXI_DATA_WIDTH       = 32,
   parameter integer C_S2_AXI_SUPPORTS_READ    = 1,
   parameter integer C_S2_AXI_SUPPORTS_WRITE   = 1,
   parameter integer C_S2_AXI_SUPPORTS_NARROW_BURST  = 1,
   parameter         C_S2_AXI_REG_EN0          = 20'h00000,
   parameter         C_S2_AXI_REG_EN1          = 20'h01000,
   parameter integer C_S2_AXI_STRICT_COHERENCY = 1,
   parameter integer C_S2_AXI_ENABLE_AP        = 0,
   parameter         C_S3_AXI_BASEADDR         = 32'h00000000,
   parameter         C_S3_AXI_HIGHADDR         = 32'h00000000,
   parameter integer C_S3_AXI_ENABLE           = 0,
   parameter integer C_S3_AXI_ID_WIDTH         = 4,
   parameter integer C_S3_AXI_ADDR_WIDTH       = 64,
   parameter integer C_S3_AXI_DATA_WIDTH       = 32,
   parameter integer C_S3_AXI_SUPPORTS_READ    = 1,
   parameter integer C_S3_AXI_SUPPORTS_WRITE   = 1,
   parameter integer C_S3_AXI_SUPPORTS_NARROW_BURST  = 1,
   parameter         C_S3_AXI_REG_EN0          = 20'h00000,
   parameter         C_S3_AXI_REG_EN1          = 20'h01000,
   parameter integer C_S3_AXI_STRICT_COHERENCY = 1,
   parameter integer C_S3_AXI_ENABLE_AP        = 0,
   parameter         C_S4_AXI_BASEADDR         = 32'h00000000,
   parameter         C_S4_AXI_HIGHADDR         = 32'h00000000,
   parameter integer C_S4_AXI_ENABLE           = 0,
   parameter integer C_S4_AXI_ID_WIDTH         = 4,
   parameter integer C_S4_AXI_ADDR_WIDTH       = 64,
   parameter integer C_S4_AXI_DATA_WIDTH       = 32,
   parameter integer C_S4_AXI_SUPPORTS_READ    = 1,
   parameter integer C_S4_AXI_SUPPORTS_WRITE   = 1,
   parameter integer C_S4_AXI_SUPPORTS_NARROW_BURST  = 1,
   parameter         C_S4_AXI_REG_EN0          = 20'h00000,
   parameter         C_S4_AXI_REG_EN1          = 20'h01000,
   parameter integer C_S4_AXI_STRICT_COHERENCY = 1,
   parameter integer C_S4_AXI_ENABLE_AP        = 0,
   parameter         C_S5_AXI_BASEADDR         = 32'h00000000,
   parameter         C_S5_AXI_HIGHADDR         = 32'h00000000,
   parameter integer C_S5_AXI_ENABLE           = 0,
   parameter integer C_S5_AXI_ID_WIDTH         = 4,
   parameter integer C_S5_AXI_ADDR_WIDTH       = 64,
   parameter integer C_S5_AXI_DATA_WIDTH       = 32,
   parameter integer C_S5_AXI_SUPPORTS_READ    = 1,
   parameter integer C_S5_AXI_SUPPORTS_WRITE   = 1,
   parameter integer C_S5_AXI_SUPPORTS_NARROW_BURST  = 1,
   parameter         C_S5_AXI_REG_EN0          = 20'h00000,
   parameter         C_S5_AXI_REG_EN1          = 20'h01000,
   parameter integer C_S5_AXI_STRICT_COHERENCY = 1,
   parameter integer C_S5_AXI_ENABLE_AP        = 0
   )
   (
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
   // Raw Wrapper Signals
   input                                     sysclk_2x          ,
   input                                     sysclk_2x_180      ,
   input                                     pll_ce_0           ,
   input                                     pll_ce_90          ,
   output                                    sysclk_2x_bufpll_o ,
   output                                    sysclk_2x_180_bufpll_o,
   output                                    pll_ce_0_bufpll_o  ,
   output                                    pll_ce_90_bufpll_o ,
   output                                    pll_lock_bufpll_o  ,
   input                                     pll_lock           ,
   input                                     sys_rst            ,
   input                                     p0_arb_en          ,
   input                                     p0_cmd_clk         ,
   input                                     p0_cmd_en          ,
   input       [2:0]                         p0_cmd_instr       ,
   input       [5:0]                         p0_cmd_bl          ,
   input       [29:0]                        p0_cmd_byte_addr   ,
   output                                    p0_cmd_empty       ,
   output                                    p0_cmd_full        ,
   input                                     p0_wr_clk          ,
   input                                     p0_wr_en           ,
   input       [C_P0_MASK_SIZE-1:0]          p0_wr_mask         ,
   input       [C_P0_DATA_PORT_SIZE-1:0]     p0_wr_data         ,
   output                                    p0_wr_full         ,
   output                                    p0_wr_empty        ,
   output      [6:0]                         p0_wr_count        ,
   output                                    p0_wr_underrun     ,
   output                                    p0_wr_error        ,
   input                                     p0_rd_clk          ,
   input                                     p0_rd_en           ,
   output      [C_P0_DATA_PORT_SIZE-1:0]     p0_rd_data         ,
   output                                    p0_rd_full         ,
   output                                    p0_rd_empty        ,
   output      [6:0]                         p0_rd_count        ,
   output                                    p0_rd_overflow     ,
   output                                    p0_rd_error        ,
   input                                     p1_arb_en          ,
   input                                     p1_cmd_clk         ,
   input                                     p1_cmd_en          ,
   input       [2:0]                         p1_cmd_instr       ,
   input       [5:0]                         p1_cmd_bl          ,
   input       [29:0]                        p1_cmd_byte_addr   ,
   output                                    p1_cmd_empty       ,
   output                                    p1_cmd_full        ,
   input                                     p1_wr_clk          ,
   input                                     p1_wr_en           ,
   input       [C_P1_MASK_SIZE-1:0]          p1_wr_mask         ,
   input       [C_P1_DATA_PORT_SIZE-1:0]     p1_wr_data         ,
   output                                    p1_wr_full         ,
   output                                    p1_wr_empty        ,
   output      [6:0]                         p1_wr_count        ,
   output                                    p1_wr_underrun     ,
   output                                    p1_wr_error        ,
   input                                     p1_rd_clk          ,
   input                                     p1_rd_en           ,
   output      [C_P1_DATA_PORT_SIZE-1:0]     p1_rd_data         ,
   output                                    p1_rd_full         ,
   output                                    p1_rd_empty        ,
   output      [6:0]                         p1_rd_count        ,
   output                                    p1_rd_overflow     ,
   output                                    p1_rd_error        ,
   input                                     p2_arb_en          ,
   input                                     p2_cmd_clk         ,
   input                                     p2_cmd_en          ,
   input       [2:0]                         p2_cmd_instr       ,
   input       [5:0]                         p2_cmd_bl          ,
   input       [29:0]                        p2_cmd_byte_addr   ,
   output                                    p2_cmd_empty       ,
   output                                    p2_cmd_full        ,
   input                                     p2_wr_clk          ,
   input                                     p2_wr_en           ,
   input       [3:0]                         p2_wr_mask         ,
   input       [31:0]                        p2_wr_data         ,
   output                                    p2_wr_full         ,
   output                                    p2_wr_empty        ,
   output      [6:0]                         p2_wr_count        ,
   output                                    p2_wr_underrun     ,
   output                                    p2_wr_error        ,
   input                                     p2_rd_clk          ,
   input                                     p2_rd_en           ,
   output      [31:0]                        p2_rd_data         ,
   output                                    p2_rd_full         ,
   output                                    p2_rd_empty        ,
   output      [6:0]                         p2_rd_count        ,
   output                                    p2_rd_overflow     ,
   output                                    p2_rd_error        ,
   input                                     p3_arb_en          ,
   input                                     p3_cmd_clk         ,
   input                                     p3_cmd_en          ,
   input       [2:0]                         p3_cmd_instr       ,
   input       [5:0]                         p3_cmd_bl          ,
   input       [29:0]                        p3_cmd_byte_addr   ,
   output                                    p3_cmd_empty       ,
   output                                    p3_cmd_full        ,
   input                                     p3_wr_clk          ,
   input                                     p3_wr_en           ,
   input       [3:0]                         p3_wr_mask         ,
   input       [31:0]                        p3_wr_data         ,
   output                                    p3_wr_full         ,
   output                                    p3_wr_empty        ,
   output      [6:0]                         p3_wr_count        ,
   output                                    p3_wr_underrun     ,
   output                                    p3_wr_error        ,
   input                                     p3_rd_clk          ,
   input                                     p3_rd_en           ,
   output      [31:0]                        p3_rd_data         ,
   output                                    p3_rd_full         ,
   output                                    p3_rd_empty        ,
   output      [6:0]                         p3_rd_count        ,
   output                                    p3_rd_overflow     ,
   output                                    p3_rd_error        ,
   input                                     p4_arb_en          ,
   input                                     p4_cmd_clk         ,
   input                                     p4_cmd_en          ,
   input       [2:0]                         p4_cmd_instr       ,
   input       [5:0]                         p4_cmd_bl          ,
   input       [29:0]                        p4_cmd_byte_addr   ,
   output                                    p4_cmd_empty       ,
   output                                    p4_cmd_full        ,
   input                                     p4_wr_clk          ,
   input                                     p4_wr_en           ,
   input       [3:0]                         p4_wr_mask         ,
   input       [31:0]                        p4_wr_data         ,
   output                                    p4_wr_full         ,
   output                                    p4_wr_empty        ,
   output      [6:0]                         p4_wr_count        ,
   output                                    p4_wr_underrun     ,
   output                                    p4_wr_error        ,
   input                                     p4_rd_clk          ,
   input                                     p4_rd_en           ,
   output      [31:0]                        p4_rd_data         ,
   output                                    p4_rd_full         ,
   output                                    p4_rd_empty        ,
   output      [6:0]                         p4_rd_count        ,
   output                                    p4_rd_overflow     ,
   output                                    p4_rd_error        ,
   input                                     p5_arb_en          ,
   input                                     p5_cmd_clk         ,
   input                                     p5_cmd_en          ,
   input       [2:0]                         p5_cmd_instr       ,
   input       [5:0]                         p5_cmd_bl          ,
   input       [29:0]                        p5_cmd_byte_addr   ,
   output                                    p5_cmd_empty       ,
   output                                    p5_cmd_full        ,
   input                                     p5_wr_clk          ,
   input                                     p5_wr_en           ,
   input       [3:0]                         p5_wr_mask         ,
   input       [31:0]                        p5_wr_data         ,
   output                                    p5_wr_full         ,
   output                                    p5_wr_empty        ,
   output      [6:0]                         p5_wr_count        ,
   output                                    p5_wr_underrun     ,
   output                                    p5_wr_error        ,
   input                                     p5_rd_clk          ,
   input                                     p5_rd_en           ,
   output      [31:0]                        p5_rd_data         ,
   output                                    p5_rd_full         ,
   output                                    p5_rd_empty        ,
   output      [6:0]                         p5_rd_count        ,
   output                                    p5_rd_overflow     ,
   output                                    p5_rd_error        ,
   output      [C_MEM_ADDR_WIDTH-1:0]        mcbx_dram_addr     ,
   output      [C_MEM_BANKADDR_WIDTH-1:0]    mcbx_dram_ba       ,
   output                                    mcbx_dram_ras_n    ,
   output                                    mcbx_dram_cas_n    ,
   output                                    mcbx_dram_we_n     ,
   output                                    mcbx_dram_cke      ,
   output                                    mcbx_dram_clk      ,
   output                                    mcbx_dram_clk_n    ,
   inout       [C_NUM_DQ_PINS-1:0]           mcbx_dram_dq       ,
   inout                                     mcbx_dram_dqs      ,
   inout                                     mcbx_dram_dqs_n    ,
   inout                                     mcbx_dram_udqs     ,
   inout                                     mcbx_dram_udqs_n   ,
   output                                    mcbx_dram_udm      ,
   output                                    mcbx_dram_ldm      ,
   output                                    mcbx_dram_odt      ,
   output                                    mcbx_dram_ddr3_rst ,
   input                                     calib_recal        ,
   inout                                     rzq                ,
   inout                                     zio                ,
   input                                     ui_read            ,
   input                                     ui_add             ,
   input                                     ui_cs              ,
   input                                     ui_clk             ,
   input                                     ui_sdi             ,
   input       [4:0]                         ui_addr            ,
   input                                     ui_broadcast       ,
   input                                     ui_drp_update      ,
   input                                     ui_done_cal        ,
   input                                     ui_cmd             ,
   input                                     ui_cmd_in          ,
   input                                     ui_cmd_en          ,
   input       [3:0]                         ui_dqcount         ,
   input                                     ui_dq_lower_dec    ,
   input                                     ui_dq_lower_inc    ,
   input                                     ui_dq_upper_dec    ,
   input                                     ui_dq_upper_inc    ,
   input                                     ui_udqs_inc        ,
   input                                     ui_udqs_dec        ,
   input                                     ui_ldqs_inc        ,
   input                                     ui_ldqs_dec        ,
   output      [7:0]                         uo_data            ,
   output                                    uo_data_valid      ,
   output                                    uo_done_cal        ,
   output                                    uo_cmd_ready_in    ,
   output                                    uo_refrsh_flag     ,
   output                                    uo_cal_start       ,
   output                                    uo_sdo             ,
   output      [31:0]                        status             ,
   input                                     selfrefresh_enter  ,
   output                                    selfrefresh_mode   ,
   // AXI Signals
   input  wire                               s0_axi_aclk        ,
   input  wire                               s0_axi_aresetn     ,
   input  wire [C_S0_AXI_ID_WIDTH-1:0]       s0_axi_awid        ,
   input  wire [C_S0_AXI_ADDR_WIDTH-1:0]     s0_axi_awaddr      ,
   input  wire [7:0]                         s0_axi_awlen       ,
   input  wire [2:0]                         s0_axi_awsize      ,
   input  wire [1:0]                         s0_axi_awburst     ,
   input  wire [0:0]                         s0_axi_awlock      ,
   input  wire [3:0]                         s0_axi_awcache     ,
   input  wire [2:0]                         s0_axi_awprot      ,
   input  wire [3:0]                         s0_axi_awqos       ,
   input  wire                               s0_axi_awvalid     ,
   output wire                               s0_axi_awready     ,
   input  wire [C_S0_AXI_DATA_WIDTH-1:0]     s0_axi_wdata       ,
   input  wire [C_S0_AXI_DATA_WIDTH/8-1:0]   s0_axi_wstrb       ,
   input  wire                               s0_axi_wlast       ,
   input  wire                               s0_axi_wvalid      ,
   output wire                               s0_axi_wready      ,
   output wire [C_S0_AXI_ID_WIDTH-1:0]       s0_axi_bid         ,
   output wire [1:0]                         s0_axi_bresp       ,
   output wire                               s0_axi_bvalid      ,
   input  wire                               s0_axi_bready      ,
   input  wire [C_S0_AXI_ID_WIDTH-1:0]       s0_axi_arid        ,
   input  wire [C_S0_AXI_ADDR_WIDTH-1:0]     s0_axi_araddr      ,
   input  wire [7:0]                         s0_axi_arlen       ,
   input  wire [2:0]                         s0_axi_arsize      ,
   input  wire [1:0]                         s0_axi_arburst     ,
   input  wire [0:0]                         s0_axi_arlock      ,
   input  wire [3:0]                         s0_axi_arcache     ,
   input  wire [2:0]                         s0_axi_arprot      ,
   input  wire [3:0]                         s0_axi_arqos       ,
   input  wire                               s0_axi_arvalid     ,
   output wire                               s0_axi_arready     ,
   output wire [C_S0_AXI_ID_WIDTH-1:0]       s0_axi_rid         ,
   output wire [C_S0_AXI_DATA_WIDTH-1:0]     s0_axi_rdata       ,
   output wire [1:0]                         s0_axi_rresp       ,
   output wire                               s0_axi_rlast       ,
   output wire                               s0_axi_rvalid      ,
   input  wire                               s0_axi_rready      ,

   input  wire                               s1_axi_aclk        ,
   input  wire                               s1_axi_aresetn     ,
   input  wire [C_S1_AXI_ID_WIDTH-1:0]       s1_axi_awid        ,
   input  wire [C_S1_AXI_ADDR_WIDTH-1:0]     s1_axi_awaddr      ,
   input  wire [7:0]                         s1_axi_awlen       ,
   input  wire [2:0]                         s1_axi_awsize      ,
   input  wire [1:0]                         s1_axi_awburst     ,
   input  wire [0:0]                         s1_axi_awlock      ,
   input  wire [3:0]                         s1_axi_awcache     ,
   input  wire [2:0]                         s1_axi_awprot      ,
   input  wire [3:0]                         s1_axi_awqos       ,
   input  wire                               s1_axi_awvalid     ,
   output wire                               s1_axi_awready     ,
   input  wire [C_S1_AXI_DATA_WIDTH-1:0]     s1_axi_wdata       ,
   input  wire [C_S1_AXI_DATA_WIDTH/8-1:0]   s1_axi_wstrb       ,
   input  wire                               s1_axi_wlast       ,
   input  wire                               s1_axi_wvalid      ,
   output wire                               s1_axi_wready      ,
   output wire [C_S1_AXI_ID_WIDTH-1:0]       s1_axi_bid         ,
   output wire [1:0]                         s1_axi_bresp       ,
   output wire                               s1_axi_bvalid      ,
   input  wire                               s1_axi_bready      ,
   input  wire [C_S1_AXI_ID_WIDTH-1:0]       s1_axi_arid        ,
   input  wire [C_S1_AXI_ADDR_WIDTH-1:0]     s1_axi_araddr      ,
   input  wire [7:0]                         s1_axi_arlen       ,
   input  wire [2:0]                         s1_axi_arsize      ,
   input  wire [1:0]                         s1_axi_arburst     ,
   input  wire [0:0]                         s1_axi_arlock      ,
   input  wire [3:0]                         s1_axi_arcache     ,
   input  wire [2:0]                         s1_axi_arprot      ,
   input  wire [3:0]                         s1_axi_arqos       ,
   input  wire                               s1_axi_arvalid     ,
   output wire                               s1_axi_arready     ,
   output wire [C_S1_AXI_ID_WIDTH-1:0]       s1_axi_rid         ,
   output wire [C_S1_AXI_DATA_WIDTH-1:0]     s1_axi_rdata       ,
   output wire [1:0]                         s1_axi_rresp       ,
   output wire                               s1_axi_rlast       ,
   output wire                               s1_axi_rvalid      ,
   input  wire                               s1_axi_rready      ,

   input  wire                               s2_axi_aclk        ,
   input  wire                               s2_axi_aresetn     ,
   input  wire [C_S2_AXI_ID_WIDTH-1:0]       s2_axi_awid        ,
   input  wire [C_S2_AXI_ADDR_WIDTH-1:0]     s2_axi_awaddr      ,
   input  wire [7:0]                         s2_axi_awlen       ,
   input  wire [2:0]                         s2_axi_awsize      ,
   input  wire [1:0]                         s2_axi_awburst     ,
   input  wire [0:0]                         s2_axi_awlock      ,
   input  wire [3:0]                         s2_axi_awcache     ,
   input  wire [2:0]                         s2_axi_awprot      ,
   input  wire [3:0]                         s2_axi_awqos       ,
   input  wire                               s2_axi_awvalid     ,
   output wire                               s2_axi_awready     ,
   input  wire [C_S2_AXI_DATA_WIDTH-1:0]     s2_axi_wdata       ,
   input  wire [C_S2_AXI_DATA_WIDTH/8-1:0]   s2_axi_wstrb       ,
   input  wire                               s2_axi_wlast       ,
   input  wire                               s2_axi_wvalid      ,
   output wire                               s2_axi_wready      ,
   output wire [C_S2_AXI_ID_WIDTH-1:0]       s2_axi_bid         ,
   output wire [1:0]                         s2_axi_bresp       ,
   output wire                               s2_axi_bvalid      ,
   input  wire                               s2_axi_bready      ,
   input  wire [C_S2_AXI_ID_WIDTH-1:0]       s2_axi_arid        ,
   input  wire [C_S2_AXI_ADDR_WIDTH-1:0]     s2_axi_araddr      ,
   input  wire [7:0]                         s2_axi_arlen       ,
   input  wire [2:0]                         s2_axi_arsize      ,
   input  wire [1:0]                         s2_axi_arburst     ,
   input  wire [0:0]                         s2_axi_arlock      ,
   input  wire [3:0]                         s2_axi_arcache     ,
   input  wire [2:0]                         s2_axi_arprot      ,
   input  wire [3:0]                         s2_axi_arqos       ,
   input  wire                               s2_axi_arvalid     ,
   output wire                               s2_axi_arready     ,
   output wire [C_S2_AXI_ID_WIDTH-1:0]       s2_axi_rid         ,
   output wire [C_S2_AXI_DATA_WIDTH-1:0]     s2_axi_rdata       ,
   output wire [1:0]                         s2_axi_rresp       ,
   output wire                               s2_axi_rlast       ,
   output wire                               s2_axi_rvalid      ,
   input  wire                               s2_axi_rready      ,

   input  wire                               s3_axi_aclk        ,
   input  wire                               s3_axi_aresetn     ,
   input  wire [C_S3_AXI_ID_WIDTH-1:0]       s3_axi_awid        ,
   input  wire [C_S3_AXI_ADDR_WIDTH-1:0]     s3_axi_awaddr      ,
   input  wire [7:0]                         s3_axi_awlen       ,
   input  wire [2:0]                         s3_axi_awsize      ,
   input  wire [1:0]                         s3_axi_awburst     ,
   input  wire [0:0]                         s3_axi_awlock      ,
   input  wire [3:0]                         s3_axi_awcache     ,
   input  wire [2:0]                         s3_axi_awprot      ,
   input  wire [3:0]                         s3_axi_awqos       ,
   input  wire                               s3_axi_awvalid     ,
   output wire                               s3_axi_awready     ,
   input  wire [C_S3_AXI_DATA_WIDTH-1:0]     s3_axi_wdata       ,
   input  wire [C_S3_AXI_DATA_WIDTH/8-1:0]   s3_axi_wstrb       ,
   input  wire                               s3_axi_wlast       ,
   input  wire                               s3_axi_wvalid      ,
   output wire                               s3_axi_wready      ,
   output wire [C_S3_AXI_ID_WIDTH-1:0]       s3_axi_bid         ,
   output wire [1:0]                         s3_axi_bresp       ,
   output wire                               s3_axi_bvalid      ,
   input  wire                               s3_axi_bready      ,
   input  wire [C_S3_AXI_ID_WIDTH-1:0]       s3_axi_arid        ,
   input  wire [C_S3_AXI_ADDR_WIDTH-1:0]     s3_axi_araddr      ,
   input  wire [7:0]                         s3_axi_arlen       ,
   input  wire [2:0]                         s3_axi_arsize      ,
   input  wire [1:0]                         s3_axi_arburst     ,
   input  wire [0:0]                         s3_axi_arlock      ,
   input  wire [3:0]                         s3_axi_arcache     ,
   input  wire [2:0]                         s3_axi_arprot      ,
   input  wire [3:0]                         s3_axi_arqos       ,
   input  wire                               s3_axi_arvalid     ,
   output wire                               s3_axi_arready     ,
   output wire [C_S3_AXI_ID_WIDTH-1:0]       s3_axi_rid         ,
   output wire [C_S3_AXI_DATA_WIDTH-1:0]     s3_axi_rdata       ,
   output wire [1:0]                         s3_axi_rresp       ,
   output wire                               s3_axi_rlast       ,
   output wire                               s3_axi_rvalid      ,
   input  wire                               s3_axi_rready      ,

   input  wire                               s4_axi_aclk        ,
   input  wire                               s4_axi_aresetn     ,
   input  wire [C_S4_AXI_ID_WIDTH-1:0]       s4_axi_awid        ,
   input  wire [C_S4_AXI_ADDR_WIDTH-1:0]     s4_axi_awaddr      ,
   input  wire [7:0]                         s4_axi_awlen       ,
   input  wire [2:0]                         s4_axi_awsize      ,
   input  wire [1:0]                         s4_axi_awburst     ,
   input  wire [0:0]                         s4_axi_awlock      ,
   input  wire [3:0]                         s4_axi_awcache     ,
   input  wire [2:0]                         s4_axi_awprot      ,
   input  wire [3:0]                         s4_axi_awqos       ,
   input  wire                               s4_axi_awvalid     ,
   output wire                               s4_axi_awready     ,
   input  wire [C_S4_AXI_DATA_WIDTH-1:0]     s4_axi_wdata       ,
   input  wire [C_S4_AXI_DATA_WIDTH/8-1:0]   s4_axi_wstrb       ,
   input  wire                               s4_axi_wlast       ,
   input  wire                               s4_axi_wvalid      ,
   output wire                               s4_axi_wready      ,
   output wire [C_S4_AXI_ID_WIDTH-1:0]       s4_axi_bid         ,
   output wire [1:0]                         s4_axi_bresp       ,
   output wire                               s4_axi_bvalid      ,
   input  wire                               s4_axi_bready      ,
   input  wire [C_S4_AXI_ID_WIDTH-1:0]       s4_axi_arid        ,
   input  wire [C_S4_AXI_ADDR_WIDTH-1:0]     s4_axi_araddr      ,
   input  wire [7:0]                         s4_axi_arlen       ,
   input  wire [2:0]                         s4_axi_arsize      ,
   input  wire [1:0]                         s4_axi_arburst     ,
   input  wire [0:0]                         s4_axi_arlock      ,
   input  wire [3:0]                         s4_axi_arcache     ,
   input  wire [2:0]                         s4_axi_arprot      ,
   input  wire [3:0]                         s4_axi_arqos       ,
   input  wire                               s4_axi_arvalid     ,
   output wire                               s4_axi_arready     ,
   output wire [C_S4_AXI_ID_WIDTH-1:0]       s4_axi_rid         ,
   output wire [C_S4_AXI_DATA_WIDTH-1:0]     s4_axi_rdata       ,
   output wire [1:0]                         s4_axi_rresp       ,
   output wire                               s4_axi_rlast       ,
   output wire                               s4_axi_rvalid      ,
   input  wire                               s4_axi_rready      ,

   input  wire                               s5_axi_aclk        ,
   input  wire                               s5_axi_aresetn     ,
   input  wire [C_S5_AXI_ID_WIDTH-1:0]       s5_axi_awid        ,
   input  wire [C_S5_AXI_ADDR_WIDTH-1:0]     s5_axi_awaddr      ,
   input  wire [7:0]                         s5_axi_awlen       ,
   input  wire [2:0]                         s5_axi_awsize      ,
   input  wire [1:0]                         s5_axi_awburst     ,
   input  wire [0:0]                         s5_axi_awlock      ,
   input  wire [3:0]                         s5_axi_awcache     ,
   input  wire [2:0]                         s5_axi_awprot      ,
   input  wire [3:0]                         s5_axi_awqos       ,
   input  wire                               s5_axi_awvalid     ,
   output wire                               s5_axi_awready     ,
   input  wire [C_S5_AXI_DATA_WIDTH-1:0]     s5_axi_wdata       ,
   input  wire [C_S5_AXI_DATA_WIDTH/8-1:0]   s5_axi_wstrb       ,
   input  wire                               s5_axi_wlast       ,
   input  wire                               s5_axi_wvalid      ,
   output wire                               s5_axi_wready      ,
   output wire [C_S5_AXI_ID_WIDTH-1:0]       s5_axi_bid         ,
   output wire [1:0]                         s5_axi_bresp       ,
   output wire                               s5_axi_bvalid      ,
   input  wire                               s5_axi_bready      ,
   input  wire [C_S5_AXI_ID_WIDTH-1:0]       s5_axi_arid        ,
   input  wire [C_S5_AXI_ADDR_WIDTH-1:0]     s5_axi_araddr      ,
   input  wire [7:0]                         s5_axi_arlen       ,
   input  wire [2:0]                         s5_axi_arsize      ,
   input  wire [1:0]                         s5_axi_arburst     ,
   input  wire [0:0]                         s5_axi_arlock      ,
   input  wire [3:0]                         s5_axi_arcache     ,
   input  wire [2:0]                         s5_axi_arprot      ,
   input  wire [3:0]                         s5_axi_arqos       ,
   input  wire                               s5_axi_arvalid     ,
   output wire                               s5_axi_arready     ,
   output wire [C_S5_AXI_ID_WIDTH-1:0]       s5_axi_rid         ,
   output wire [C_S5_AXI_DATA_WIDTH-1:0]     s5_axi_rdata       ,
   output wire [1:0]                         s5_axi_rresp       ,
   output wire                               s5_axi_rlast       ,
   output wire                               s5_axi_rvalid      ,
   input  wire                               s5_axi_rready
   );

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////
// Barrel Left Shift Octal
function [17:0] blso (
  input [17:0] a,
  input integer shift,
  input integer width
);
begin : func_blso
  integer i;
  integer w;
  integer s;
  w = width*3;
  s = (shift*3) % w;
  blso = 18'o000000;
  for (i = 0; i < w; i = i + 1) begin
    blso[i] = a[(i+w-s)%w];
    //bls[i] = 1'b1;
  end
end
endfunction

// For a given port_config, port_enable and slot, calculate the round robin
// arbitration that would be generated by the gui.
function [17:0] rr (
  input [5:0] port_enable,
  input integer port_config,
  input integer slot_num
);
begin : func_rr
  integer i;
  integer max_ports;
  integer num_ports;
  integer port_cnt;

  case (port_config)
    1: max_ports = 6;
    2: max_ports = 4;
    3: max_ports = 3;
    4: max_ports = 2;
    5: max_ports = 1;
// synthesis translate_off
    default : $display("ERROR: Port Config can't be %d", port_config);
// synthesis translate_on
  endcase

  num_ports = 0;
  for (i = 0; i < max_ports; i = i + 1) begin
    if (port_enable[i] == 1'b1) begin
      num_ports = num_ports + 1;
    end
  end

  rr = 18'o000000;
  port_cnt = 0;

  for (i = (num_ports-1); i >= 0; i = i - 1) begin
    while (port_enable[port_cnt] != 1'b1) begin
      port_cnt = port_cnt + 1;
    end
    rr[i*3 +: 3] = port_cnt[2:0];
    port_cnt = port_cnt +1;
  end


  rr = blso(rr, slot_num, num_ports);
end
endfunction

function [17:0] convert_arb_slot (
  input [5:0]   port_enable,
  input integer port_config,
  input [17:0]  mig_arb_slot
);
begin : func_convert_arb_slot
  integer i;
  integer num_ports;
  integer mig_port_num;
  reg [17:0] port_map;
  num_ports = 0;

  // Enumerated port configuration for ease of use
  case (port_config)
    1: port_map = 18'o543210;
    2: port_map = 18'o774210;
    3: port_map = 18'o777420;
    4: port_map = 18'o777720;
    5: port_map = 18'o777770;
// synthesis translate_off
    default : $display ("ERROR: Invalid Port Configuration.");
// synthesis translate_on
  endcase

  // Count the number of ports
  for (i = 0; i < 6; i = i + 1) begin
    if (port_enable[i] == 1'b1) begin
      num_ports = num_ports + 1;
    end
  end

  // Map the ports from the MIG GUI to the MCB Wrapper
  for (i = 0; i < 6; i = i + 1) begin
    if (i < num_ports) begin
      mig_port_num = mig_arb_slot[3*(num_ports-i-1) +: 3];
      convert_arb_slot[3*i +: 3] = port_map[3*mig_port_num +: 3];
    end else begin
      convert_arb_slot[3*i +: 3] = 3'b111;
    end
  end
end
endfunction

// Function to calculate the number of time slots automatically based on the
// number of ports used.  Will choose 10 if the number of valid ports is 5,
// otherwise it will be 12.
function integer calc_num_time_slots (
  input [5:0]   port_enable,
  input integer port_config
);
begin : func_calc_num_tim_slots
  integer num_ports;
  integer i;
  num_ports = 0;
  for (i = 0; i < 6; i = i + 1) begin
    if (port_enable[i] == 1'b1) begin
      num_ports = num_ports + 1;
    end
  end
  calc_num_time_slots = (port_config == 1 && num_ports == 5) ? 10 : 12;
end
endfunction
////////////////////////////////////////////////////////////////////////////////
// Local Parameters
////////////////////////////////////////////////////////////////////////////////
  localparam P_S0_AXI_ADDRMASK = C_S0_AXI_BASEADDR ^ C_S0_AXI_HIGHADDR;
  localparam P_S1_AXI_ADDRMASK = C_S1_AXI_BASEADDR ^ C_S1_AXI_HIGHADDR;
  localparam P_S2_AXI_ADDRMASK = C_S2_AXI_BASEADDR ^ C_S2_AXI_HIGHADDR;
  localparam P_S3_AXI_ADDRMASK = C_S3_AXI_BASEADDR ^ C_S3_AXI_HIGHADDR;
  localparam P_S4_AXI_ADDRMASK = C_S4_AXI_BASEADDR ^ C_S4_AXI_HIGHADDR;
  localparam P_S5_AXI_ADDRMASK = C_S5_AXI_BASEADDR ^ C_S5_AXI_HIGHADDR;
  localparam P_PORT_CONFIG     = (C_PORT_CONFIG == "B32_B32_B32_B32") ? 2 :
                                 (C_PORT_CONFIG == "B64_B32_B32"    ) ? 3 :
                                 (C_PORT_CONFIG == "B64_B64"        ) ? 4 :
                                 (C_PORT_CONFIG == "B128"           ) ? 5 :
                                 1; // B32_B32_x32_x32_x32_x32 case
  localparam P_ARB_NUM_TIME_SLOTS = (C_ARB_ALGORITHM == 0) ? calc_num_time_slots(C_PORT_ENABLE, P_PORT_CONFIG) : C_ARB_NUM_TIME_SLOTS;
  localparam P_0_ARB_TIME_SLOT_0 =  (C_ARB_ALGORITHM == 0) ? rr(C_PORT_ENABLE, P_PORT_CONFIG, 0 ) : C_ARB_TIME_SLOT_0 ;
  localparam P_0_ARB_TIME_SLOT_1 =  (C_ARB_ALGORITHM == 0) ? rr(C_PORT_ENABLE, P_PORT_CONFIG, 1 ) : C_ARB_TIME_SLOT_1 ;
  localparam P_0_ARB_TIME_SLOT_2 =  (C_ARB_ALGORITHM == 0) ? rr(C_PORT_ENABLE, P_PORT_CONFIG, 2 ) : C_ARB_TIME_SLOT_2 ;
  localparam P_0_ARB_TIME_SLOT_3 =  (C_ARB_ALGORITHM == 0) ? rr(C_PORT_ENABLE, P_PORT_CONFIG, 3 ) : C_ARB_TIME_SLOT_3 ;
  localparam P_0_ARB_TIME_SLOT_4 =  (C_ARB_ALGORITHM == 0) ? rr(C_PORT_ENABLE, P_PORT_CONFIG, 4 ) : C_ARB_TIME_SLOT_4 ;
  localparam P_0_ARB_TIME_SLOT_5 =  (C_ARB_ALGORITHM == 0) ? rr(C_PORT_ENABLE, P_PORT_CONFIG, 5 ) : C_ARB_TIME_SLOT_5 ;
  localparam P_0_ARB_TIME_SLOT_6 =  (C_ARB_ALGORITHM == 0) ? rr(C_PORT_ENABLE, P_PORT_CONFIG, 6 ) : C_ARB_TIME_SLOT_6 ;
  localparam P_0_ARB_TIME_SLOT_7 =  (C_ARB_ALGORITHM == 0) ? rr(C_PORT_ENABLE, P_PORT_CONFIG, 7 ) : C_ARB_TIME_SLOT_7 ;
  localparam P_0_ARB_TIME_SLOT_8 =  (C_ARB_ALGORITHM == 0) ? rr(C_PORT_ENABLE, P_PORT_CONFIG, 8 ) : C_ARB_TIME_SLOT_8 ;
  localparam P_0_ARB_TIME_SLOT_9 =  (C_ARB_ALGORITHM == 0) ? rr(C_PORT_ENABLE, P_PORT_CONFIG, 9 ) : C_ARB_TIME_SLOT_9 ;
  localparam P_0_ARB_TIME_SLOT_10 = (C_ARB_ALGORITHM == 0) ? rr(C_PORT_ENABLE, P_PORT_CONFIG, 10) : C_ARB_TIME_SLOT_10;
  localparam P_0_ARB_TIME_SLOT_11 = (C_ARB_ALGORITHM == 0) ? rr(C_PORT_ENABLE, P_PORT_CONFIG, 11) : C_ARB_TIME_SLOT_11;
  localparam P_ARB_TIME_SLOT_0 =  convert_arb_slot(C_PORT_ENABLE, P_PORT_CONFIG, P_0_ARB_TIME_SLOT_0);
  localparam P_ARB_TIME_SLOT_1 =  convert_arb_slot(C_PORT_ENABLE, P_PORT_CONFIG, P_0_ARB_TIME_SLOT_1);
  localparam P_ARB_TIME_SLOT_2 =  convert_arb_slot(C_PORT_ENABLE, P_PORT_CONFIG, P_0_ARB_TIME_SLOT_2);
  localparam P_ARB_TIME_SLOT_3 =  convert_arb_slot(C_PORT_ENABLE, P_PORT_CONFIG, P_0_ARB_TIME_SLOT_3);
  localparam P_ARB_TIME_SLOT_4 =  convert_arb_slot(C_PORT_ENABLE, P_PORT_CONFIG, P_0_ARB_TIME_SLOT_4);
  localparam P_ARB_TIME_SLOT_5 =  convert_arb_slot(C_PORT_ENABLE, P_PORT_CONFIG, P_0_ARB_TIME_SLOT_5);
  localparam P_ARB_TIME_SLOT_6 =  convert_arb_slot(C_PORT_ENABLE, P_PORT_CONFIG, P_0_ARB_TIME_SLOT_6);
  localparam P_ARB_TIME_SLOT_7 =  convert_arb_slot(C_PORT_ENABLE, P_PORT_CONFIG, P_0_ARB_TIME_SLOT_7);
  localparam P_ARB_TIME_SLOT_8 =  convert_arb_slot(C_PORT_ENABLE, P_PORT_CONFIG, P_0_ARB_TIME_SLOT_8);
  localparam P_ARB_TIME_SLOT_9 =  convert_arb_slot(C_PORT_ENABLE, P_PORT_CONFIG, P_0_ARB_TIME_SLOT_9);
  localparam P_ARB_TIME_SLOT_10 = convert_arb_slot(C_PORT_ENABLE, P_PORT_CONFIG, P_0_ARB_TIME_SLOT_10);
  localparam P_ARB_TIME_SLOT_11 = convert_arb_slot(C_PORT_ENABLE, P_PORT_CONFIG, P_0_ARB_TIME_SLOT_11);

////////////////////////////////////////////////////////////////////////////////
// Wires/Reg declarations
////////////////////////////////////////////////////////////////////////////////
  wire [C_S0_AXI_ADDR_WIDTH-1:0] s0_axi_araddr_i;
  wire [C_S0_AXI_ADDR_WIDTH-1:0] s0_axi_awaddr_i;
  wire                           p0_arb_en_i;
  wire                           p0_cmd_clk_i;
  wire                           p0_cmd_en_i;
  wire [2:0]                     p0_cmd_instr_i;
  wire [5:0]                     p0_cmd_bl_i;
  wire [29:0]                    p0_cmd_byte_addr_i;
  wire                           p0_cmd_empty_i;
  wire                           p0_cmd_full_i;
  wire                           p0_wr_clk_i;
  wire                           p0_wr_en_i;
  wire [C_P0_MASK_SIZE-1:0]      p0_wr_mask_i;
  wire [C_P0_DATA_PORT_SIZE-1:0] p0_wr_data_i;
  wire                           p0_wr_full_i;
  wire                           p0_wr_empty_i;
  wire [6:0]                     p0_wr_count_i;
  wire                           p0_wr_underrun_i;
  wire                           p0_wr_error_i;
  wire                           p0_rd_clk_i;
  wire                           p0_rd_en_i;
  wire [C_P0_DATA_PORT_SIZE-1:0] p0_rd_data_i;
  wire                           p0_rd_full_i;
  wire                           p0_rd_empty_i;
  wire [6:0]                     p0_rd_count_i;
  wire                           p0_rd_overflow_i;
  wire                           p0_rd_error_i;

  wire [C_S1_AXI_ADDR_WIDTH-1:0] s1_axi_araddr_i;
  wire [C_S1_AXI_ADDR_WIDTH-1:0] s1_axi_awaddr_i;
  wire                           p1_arb_en_i;
  wire                           p1_cmd_clk_i;
  wire                           p1_cmd_en_i;
  wire [2:0]                     p1_cmd_instr_i;
  wire [5:0]                     p1_cmd_bl_i;
  wire [29:0]                    p1_cmd_byte_addr_i;
  wire                           p1_cmd_empty_i;
  wire                           p1_cmd_full_i;
  wire                           p1_wr_clk_i;
  wire                           p1_wr_en_i;
  wire [C_P1_MASK_SIZE-1:0]      p1_wr_mask_i;
  wire [C_P1_DATA_PORT_SIZE-1:0] p1_wr_data_i;
  wire                           p1_wr_full_i;
  wire                           p1_wr_empty_i;
  wire [6:0]                     p1_wr_count_i;
  wire                           p1_wr_underrun_i;
  wire                           p1_wr_error_i;
  wire                           p1_rd_clk_i;
  wire                           p1_rd_en_i;
  wire [C_P1_DATA_PORT_SIZE-1:0] p1_rd_data_i;
  wire                           p1_rd_full_i;
  wire                           p1_rd_empty_i;
  wire [6:0]                     p1_rd_count_i;
  wire                           p1_rd_overflow_i;
  wire                           p1_rd_error_i;

  wire [C_S2_AXI_ADDR_WIDTH-1:0] s2_axi_araddr_i;
  wire [C_S2_AXI_ADDR_WIDTH-1:0] s2_axi_awaddr_i;
  wire                           p2_arb_en_i;
  wire                           p2_cmd_clk_i;
  wire                           p2_cmd_en_i;
  wire [2:0]                     p2_cmd_instr_i;
  wire [5:0]                     p2_cmd_bl_i;
  wire [29:0]                    p2_cmd_byte_addr_i;
  wire                           p2_cmd_empty_i;
  wire                           p2_cmd_full_i;
  wire                           p2_wr_clk_i;
  wire                           p2_wr_en_i;
  wire [3:0]                     p2_wr_mask_i;
  wire [31:0]                    p2_wr_data_i;
  wire                           p2_wr_full_i;
  wire                           p2_wr_empty_i;
  wire [6:0]                     p2_wr_count_i;
  wire                           p2_wr_underrun_i;
  wire                           p2_wr_error_i;
  wire                           p2_rd_clk_i;
  wire                           p2_rd_en_i;
  wire [31:0]                    p2_rd_data_i;
  wire                           p2_rd_full_i;
  wire                           p2_rd_empty_i;
  wire [6:0]                     p2_rd_count_i;
  wire                           p2_rd_overflow_i;
  wire                           p2_rd_error_i;

  wire [C_S3_AXI_ADDR_WIDTH-1:0] s3_axi_araddr_i;
  wire [C_S3_AXI_ADDR_WIDTH-1:0] s3_axi_awaddr_i;
  wire                           p3_arb_en_i;
  wire                           p3_cmd_clk_i;
  wire                           p3_cmd_en_i;
  wire [2:0]                     p3_cmd_instr_i;
  wire [5:0]                     p3_cmd_bl_i;
  wire [29:0]                    p3_cmd_byte_addr_i;
  wire                           p3_cmd_empty_i;
  wire                           p3_cmd_full_i;
  wire                           p3_wr_clk_i;
  wire                           p3_wr_en_i;
  wire [3:0]                     p3_wr_mask_i;
  wire [31:0]                    p3_wr_data_i;
  wire                           p3_wr_full_i;
  wire                           p3_wr_empty_i;
  wire [6:0]                     p3_wr_count_i;
  wire                           p3_wr_underrun_i;
  wire                           p3_wr_error_i;
  wire                           p3_rd_clk_i;
  wire                           p3_rd_en_i;
  wire [31:0]                    p3_rd_data_i;
  wire                           p3_rd_full_i;
  wire                           p3_rd_empty_i;
  wire [6:0]                     p3_rd_count_i;
  wire                           p3_rd_overflow_i;
  wire                           p3_rd_error_i;

  wire [C_S4_AXI_ADDR_WIDTH-1:0] s4_axi_araddr_i;
  wire [C_S4_AXI_ADDR_WIDTH-1:0] s4_axi_awaddr_i;
  wire                           p4_arb_en_i;
  wire                           p4_cmd_clk_i;
  wire                           p4_cmd_en_i;
  wire [2:0]                     p4_cmd_instr_i;
  wire [5:0]                     p4_cmd_bl_i;
  wire [29:0]                    p4_cmd_byte_addr_i;
  wire                           p4_cmd_empty_i;
  wire                           p4_cmd_full_i;
  wire                           p4_wr_clk_i;
  wire                           p4_wr_en_i;
  wire [3:0]                     p4_wr_mask_i;
  wire [31:0]                    p4_wr_data_i;
  wire                           p4_wr_full_i;
  wire                           p4_wr_empty_i;
  wire [6:0]                     p4_wr_count_i;
  wire                           p4_wr_underrun_i;
  wire                           p4_wr_error_i;
  wire                           p4_rd_clk_i;
  wire                           p4_rd_en_i;
  wire [31:0]                    p4_rd_data_i;
  wire                           p4_rd_full_i;
  wire                           p4_rd_empty_i;
  wire [6:0]                     p4_rd_count_i;
  wire                           p4_rd_overflow_i;
  wire                           p4_rd_error_i;

  wire [C_S5_AXI_ADDR_WIDTH-1:0] s5_axi_araddr_i;
  wire [C_S5_AXI_ADDR_WIDTH-1:0] s5_axi_awaddr_i;
  wire                           p5_arb_en_i;
  wire                           p5_cmd_clk_i;
  wire                           p5_cmd_en_i;
  wire [2:0]                     p5_cmd_instr_i;
  wire [5:0]                     p5_cmd_bl_i;
  wire [29:0]                    p5_cmd_byte_addr_i;
  wire                           p5_cmd_empty_i;
  wire                           p5_cmd_full_i;
  wire                           p5_wr_clk_i;
  wire                           p5_wr_en_i;
  wire [3:0]                     p5_wr_mask_i;
  wire [31:0]                    p5_wr_data_i;
  wire                           p5_wr_full_i;
  wire                           p5_wr_empty_i;
  wire [6:0]                     p5_wr_count_i;
  wire                           p5_wr_underrun_i;
  wire                           p5_wr_error_i;
  wire                           p5_rd_clk_i;
  wire                           p5_rd_en_i;
  wire [31:0]                    p5_rd_data_i;
  wire                           p5_rd_full_i;
  wire                           p5_rd_empty_i;
  wire [6:0]                     p5_rd_count_i;
  wire                           p5_rd_overflow_i;
  wire                           p5_rd_error_i;

  wire                           ioclk0;
  wire                           ioclk180;
  wire                           pll_ce_0_i;
  wire                           pll_ce_90_i;

  generate
    if (C_MCB_USE_EXTERNAL_BUFPLL == 0) begin : gen_spartan6_bufpll_mcb
      // Instantiate the PLL for MCB.
      BUFPLL_MCB #
      (
      .DIVIDE   (2),
      .LOCK_SRC ("LOCK_TO_0")
      )
      bufpll_0
        (
        .IOCLK0       (ioclk0),
        .IOCLK1       (ioclk180),
        .GCLK         (ui_clk),
        .LOCKED       (pll_lock),
        .LOCK         (pll_lock_bufpll_o),
        .SERDESSTROBE0(pll_ce_0_i),
        .SERDESSTROBE1(pll_ce_90_i),
        .PLLIN0       (sysclk_2x),
        .PLLIN1       (sysclk_2x_180)
        );
      end else begin : gen_spartan6_no_bufpll_mcb
        // Use external bufpll_mcb.
        assign pll_ce_0_i   = pll_ce_0;
        assign pll_ce_90_i  = pll_ce_90;
        assign ioclk0     = sysclk_2x;
        assign ioclk180   = sysclk_2x_180;
        assign pll_lock_bufpll_o = pll_lock;
      end
  endgenerate

  assign sysclk_2x_bufpll_o     = ioclk0;
  assign sysclk_2x_180_bufpll_o = ioclk180;
  assign pll_ce_0_bufpll_o      = pll_ce_0_i;
  assign pll_ce_90_bufpll_o     = pll_ce_90_i;

mcb_raw_wrapper #
   (
   .C_MEMCLK_PERIOD           ( C_MEMCLK_PERIOD           ),
   .C_PORT_ENABLE             ( C_PORT_ENABLE             ),
   .C_MEM_ADDR_ORDER          ( C_MEM_ADDR_ORDER          ),
   .C_USR_INTERFACE_MODE      ( C_USR_INTERFACE_MODE      ),
   .C_ARB_NUM_TIME_SLOTS      ( P_ARB_NUM_TIME_SLOTS      ),
   .C_ARB_TIME_SLOT_0         ( P_ARB_TIME_SLOT_0         ),
   .C_ARB_TIME_SLOT_1         ( P_ARB_TIME_SLOT_1         ),
   .C_ARB_TIME_SLOT_2         ( P_ARB_TIME_SLOT_2         ),
   .C_ARB_TIME_SLOT_3         ( P_ARB_TIME_SLOT_3         ),
   .C_ARB_TIME_SLOT_4         ( P_ARB_TIME_SLOT_4         ),
   .C_ARB_TIME_SLOT_5         ( P_ARB_TIME_SLOT_5         ),
   .C_ARB_TIME_SLOT_6         ( P_ARB_TIME_SLOT_6         ),
   .C_ARB_TIME_SLOT_7         ( P_ARB_TIME_SLOT_7         ),
   .C_ARB_TIME_SLOT_8         ( P_ARB_TIME_SLOT_8         ),
   .C_ARB_TIME_SLOT_9         ( P_ARB_TIME_SLOT_9         ),
   .C_ARB_TIME_SLOT_10        ( P_ARB_TIME_SLOT_10        ),
   .C_ARB_TIME_SLOT_11        ( P_ARB_TIME_SLOT_11        ),
   .C_PORT_CONFIG             ( C_PORT_CONFIG             ),
   .C_MEM_TRAS                ( C_MEM_TRAS                ),
   .C_MEM_TRCD                ( C_MEM_TRCD                ),
   .C_MEM_TREFI               ( C_MEM_TREFI               ),
   .C_MEM_TRFC                ( C_MEM_TRFC                ),
   .C_MEM_TRP                 ( C_MEM_TRP                 ),
   .C_MEM_TWR                 ( C_MEM_TWR                 ),
   .C_MEM_TRTP                ( C_MEM_TRTP                ),
   .C_MEM_TWTR                ( C_MEM_TWTR                ),
   .C_NUM_DQ_PINS             ( C_NUM_DQ_PINS             ),
   .C_MEM_TYPE                ( C_MEM_TYPE                ),
   .C_MEM_DENSITY             ( C_MEM_DENSITY             ),
   .C_MEM_BURST_LEN           ( C_MEM_BURST_LEN           ),
   .C_MEM_CAS_LATENCY         ( C_MEM_CAS_LATENCY         ),
   .C_MEM_ADDR_WIDTH          ( C_MEM_ADDR_WIDTH          ),
   .C_MEM_BANKADDR_WIDTH      ( C_MEM_BANKADDR_WIDTH      ),
   .C_MEM_NUM_COL_BITS        ( C_MEM_NUM_COL_BITS        ),
   .C_MEM_DDR3_CAS_LATENCY    ( C_MEM_DDR3_CAS_LATENCY    ),
   .C_MEM_MOBILE_PA_SR        ( C_MEM_MOBILE_PA_SR        ),
   .C_MEM_DDR1_2_ODS          ( C_MEM_DDR1_2_ODS          ),
   .C_MEM_DDR3_ODS            ( C_MEM_DDR3_ODS            ),
   .C_MEM_DDR2_RTT            ( C_MEM_DDR2_RTT            ),
   .C_MEM_DDR3_RTT            ( C_MEM_DDR3_RTT            ),
   .C_MEM_MDDR_ODS            ( C_MEM_MDDR_ODS            ),
   .C_MEM_DDR2_DIFF_DQS_EN    ( C_MEM_DDR2_DIFF_DQS_EN    ),
   .C_MEM_DDR2_3_PA_SR        ( C_MEM_DDR2_3_PA_SR        ),
   .C_MEM_DDR3_CAS_WR_LATENCY ( C_MEM_DDR3_CAS_WR_LATENCY ),
   .C_MEM_DDR3_AUTO_SR        ( C_MEM_DDR3_AUTO_SR        ),
   .C_MEM_DDR2_3_HIGH_TEMP_SR ( C_MEM_DDR2_3_HIGH_TEMP_SR ),
   .C_MEM_DDR3_DYN_WRT_ODT    ( C_MEM_DDR3_DYN_WRT_ODT    ),
   // Subtract 16 to stop TRFC violations.
   .C_MEM_TZQINIT_MAXCNT      ( C_MEM_TZQINIT_MAXCNT - 16 ),
   .C_MC_CALIB_BYPASS         ( C_MC_CALIB_BYPASS         ),
   .C_MC_CALIBRATION_RA       ( C_MC_CALIBRATION_RA       ),
   .C_MC_CALIBRATION_BA       ( C_MC_CALIBRATION_BA       ),
   .C_CALIB_SOFT_IP           ( C_CALIB_SOFT_IP           ),
   .C_SKIP_IN_TERM_CAL        ( C_SKIP_IN_TERM_CAL        ),
   .C_SKIP_DYNAMIC_CAL        ( C_SKIP_DYNAMIC_CAL        ),
   .C_SKIP_DYN_IN_TERM        ( C_SKIP_DYN_IN_TERM        ),
   .LDQSP_TAP_DELAY_VAL       ( LDQSP_TAP_DELAY_VAL       ),
   .UDQSP_TAP_DELAY_VAL       ( UDQSP_TAP_DELAY_VAL       ),
   .LDQSN_TAP_DELAY_VAL       ( LDQSN_TAP_DELAY_VAL       ),
   .UDQSN_TAP_DELAY_VAL       ( UDQSN_TAP_DELAY_VAL       ),
   .DQ0_TAP_DELAY_VAL         ( DQ0_TAP_DELAY_VAL         ),
   .DQ1_TAP_DELAY_VAL         ( DQ1_TAP_DELAY_VAL         ),
   .DQ2_TAP_DELAY_VAL         ( DQ2_TAP_DELAY_VAL         ),
   .DQ3_TAP_DELAY_VAL         ( DQ3_TAP_DELAY_VAL         ),
   .DQ4_TAP_DELAY_VAL         ( DQ4_TAP_DELAY_VAL         ),
   .DQ5_TAP_DELAY_VAL         ( DQ5_TAP_DELAY_VAL         ),
   .DQ6_TAP_DELAY_VAL         ( DQ6_TAP_DELAY_VAL         ),
   .DQ7_TAP_DELAY_VAL         ( DQ7_TAP_DELAY_VAL         ),
   .DQ8_TAP_DELAY_VAL         ( DQ8_TAP_DELAY_VAL         ),
   .DQ9_TAP_DELAY_VAL         ( DQ9_TAP_DELAY_VAL         ),
   .DQ10_TAP_DELAY_VAL        ( DQ10_TAP_DELAY_VAL        ),
   .DQ11_TAP_DELAY_VAL        ( DQ11_TAP_DELAY_VAL        ),
   .DQ12_TAP_DELAY_VAL        ( DQ12_TAP_DELAY_VAL        ),
   .DQ13_TAP_DELAY_VAL        ( DQ13_TAP_DELAY_VAL        ),
   .DQ14_TAP_DELAY_VAL        ( DQ14_TAP_DELAY_VAL        ),
   .DQ15_TAP_DELAY_VAL        ( DQ15_TAP_DELAY_VAL        ),
   .C_MC_CALIBRATION_CA       ( C_MC_CALIBRATION_CA       ),
   .C_MC_CALIBRATION_CLK_DIV  ( C_MC_CALIBRATION_CLK_DIV  ),
   .C_MC_CALIBRATION_MODE     ( C_MC_CALIBRATION_MODE     ),
   .C_MC_CALIBRATION_DELAY    ( C_MC_CALIBRATION_DELAY    ),
   // synthesis translate_off
   .C_SIMULATION              ( C_SIMULATION              ),
   // synthesis translate_on
   .C_P0_MASK_SIZE            ( C_P0_MASK_SIZE            ),
   .C_P0_DATA_PORT_SIZE       ( C_P0_DATA_PORT_SIZE       ),
   .C_P1_MASK_SIZE            ( C_P1_MASK_SIZE            ),
   .C_P1_DATA_PORT_SIZE       ( C_P1_DATA_PORT_SIZE       )
   )
   mcb_raw_wrapper_inst
   (
   .sysclk_2x                 ( ioclk0                    ),
   .sysclk_2x_180             ( ioclk180                  ),
   .pll_ce_0                  ( pll_ce_0_i                ),
   .pll_ce_90                 ( pll_ce_90_i               ),
   .pll_lock                  ( pll_lock_bufpll_o         ),
   .sys_rst                   ( sys_rst                   ),
   .p0_arb_en                 ( p0_arb_en_i               ),
   .p0_cmd_clk                ( p0_cmd_clk_i              ),
   .p0_cmd_en                 ( p0_cmd_en_i               ),
   .p0_cmd_instr              ( p0_cmd_instr_i            ),
   .p0_cmd_bl                 ( p0_cmd_bl_i               ),
   .p0_cmd_byte_addr          ( p0_cmd_byte_addr_i        ),
   .p0_cmd_empty              ( p0_cmd_empty_i            ),
   .p0_cmd_full               ( p0_cmd_full_i             ),
   .p0_wr_clk                 ( p0_wr_clk_i               ),
   .p0_wr_en                  ( p0_wr_en_i                ),
   .p0_wr_mask                ( p0_wr_mask_i              ),
   .p0_wr_data                ( p0_wr_data_i              ),
   .p0_wr_full                ( p0_wr_full_i              ),
   .p0_wr_empty               ( p0_wr_empty_i             ),
   .p0_wr_count               ( p0_wr_count_i             ),
   .p0_wr_underrun            ( p0_wr_underrun_i          ),
   .p0_wr_error               ( p0_wr_error_i             ),
   .p0_rd_clk                 ( p0_rd_clk_i               ),
   .p0_rd_en                  ( p0_rd_en_i                ),
   .p0_rd_data                ( p0_rd_data_i              ),
   .p0_rd_full                ( p0_rd_full_i              ),
   .p0_rd_empty               ( p0_rd_empty_i             ),
   .p0_rd_count               ( p0_rd_count_i             ),
   .p0_rd_overflow            ( p0_rd_overflow_i          ),
   .p0_rd_error               ( p0_rd_error_i             ),
   .p1_arb_en                 ( p1_arb_en_i               ),
   .p1_cmd_clk                ( p1_cmd_clk_i              ),
   .p1_cmd_en                 ( p1_cmd_en_i               ),
   .p1_cmd_instr              ( p1_cmd_instr_i            ),
   .p1_cmd_bl                 ( p1_cmd_bl_i               ),
   .p1_cmd_byte_addr          ( p1_cmd_byte_addr_i        ),
   .p1_cmd_empty              ( p1_cmd_empty_i            ),
   .p1_cmd_full               ( p1_cmd_full_i             ),
   .p1_wr_clk                 ( p1_wr_clk_i               ),
   .p1_wr_en                  ( p1_wr_en_i                ),
   .p1_wr_mask                ( p1_wr_mask_i              ),
   .p1_wr_data                ( p1_wr_data_i              ),
   .p1_wr_full                ( p1_wr_full_i              ),
   .p1_wr_empty               ( p1_wr_empty_i             ),
   .p1_wr_count               ( p1_wr_count_i             ),
   .p1_wr_underrun            ( p1_wr_underrun_i          ),
   .p1_wr_error               ( p1_wr_error_i             ),
   .p1_rd_clk                 ( p1_rd_clk_i               ),
   .p1_rd_en                  ( p1_rd_en_i                ),
   .p1_rd_data                ( p1_rd_data_i              ),
   .p1_rd_full                ( p1_rd_full_i              ),
   .p1_rd_empty               ( p1_rd_empty_i             ),
   .p1_rd_count               ( p1_rd_count_i             ),
   .p1_rd_overflow            ( p1_rd_overflow_i          ),
   .p1_rd_error               ( p1_rd_error_i             ),
   .p2_arb_en                 ( p2_arb_en_i               ),
   .p2_cmd_clk                ( p2_cmd_clk_i              ),
   .p2_cmd_en                 ( p2_cmd_en_i               ),
   .p2_cmd_instr              ( p2_cmd_instr_i            ),
   .p2_cmd_bl                 ( p2_cmd_bl_i               ),
   .p2_cmd_byte_addr          ( p2_cmd_byte_addr_i        ),
   .p2_cmd_empty              ( p2_cmd_empty_i            ),
   .p2_cmd_full               ( p2_cmd_full_i             ),
   .p2_wr_clk                 ( p2_wr_clk_i               ),
   .p2_wr_en                  ( p2_wr_en_i                ),
   .p2_wr_mask                ( p2_wr_mask_i              ),
   .p2_wr_data                ( p2_wr_data_i              ),
   .p2_wr_full                ( p2_wr_full_i              ),
   .p2_wr_empty               ( p2_wr_empty_i             ),
   .p2_wr_count               ( p2_wr_count_i             ),
   .p2_wr_underrun            ( p2_wr_underrun_i          ),
   .p2_wr_error               ( p2_wr_error_i             ),
   .p2_rd_clk                 ( p2_rd_clk_i               ),
   .p2_rd_en                  ( p2_rd_en_i                ),
   .p2_rd_data                ( p2_rd_data_i              ),
   .p2_rd_full                ( p2_rd_full_i              ),
   .p2_rd_empty               ( p2_rd_empty_i             ),
   .p2_rd_count               ( p2_rd_count_i             ),
   .p2_rd_overflow            ( p2_rd_overflow_i          ),
   .p2_rd_error               ( p2_rd_error_i             ),
   .p3_arb_en                 ( p3_arb_en_i               ),
   .p3_cmd_clk                ( p3_cmd_clk_i              ),
   .p3_cmd_en                 ( p3_cmd_en_i               ),
   .p3_cmd_instr              ( p3_cmd_instr_i            ),
   .p3_cmd_bl                 ( p3_cmd_bl_i               ),
   .p3_cmd_byte_addr          ( p3_cmd_byte_addr_i        ),
   .p3_cmd_empty              ( p3_cmd_empty_i            ),
   .p3_cmd_full               ( p3_cmd_full_i             ),
   .p3_wr_clk                 ( p3_wr_clk_i               ),
   .p3_wr_en                  ( p3_wr_en_i                ),
   .p3_wr_mask                ( p3_wr_mask_i              ),
   .p3_wr_data                ( p3_wr_data_i              ),
   .p3_wr_full                ( p3_wr_full_i              ),
   .p3_wr_empty               ( p3_wr_empty_i             ),
   .p3_wr_count               ( p3_wr_count_i             ),
   .p3_wr_underrun            ( p3_wr_underrun_i          ),
   .p3_wr_error               ( p3_wr_error_i             ),
   .p3_rd_clk                 ( p3_rd_clk_i               ),
   .p3_rd_en                  ( p3_rd_en_i                ),
   .p3_rd_data                ( p3_rd_data_i              ),
   .p3_rd_full                ( p3_rd_full_i              ),
   .p3_rd_empty               ( p3_rd_empty_i             ),
   .p3_rd_count               ( p3_rd_count_i             ),
   .p3_rd_overflow            ( p3_rd_overflow_i          ),
   .p3_rd_error               ( p3_rd_error_i             ),
   .p4_arb_en                 ( p4_arb_en_i               ),
   .p4_cmd_clk                ( p4_cmd_clk_i              ),
   .p4_cmd_en                 ( p4_cmd_en_i               ),
   .p4_cmd_instr              ( p4_cmd_instr_i            ),
   .p4_cmd_bl                 ( p4_cmd_bl_i               ),
   .p4_cmd_byte_addr          ( p4_cmd_byte_addr_i        ),
   .p4_cmd_empty              ( p4_cmd_empty_i            ),
   .p4_cmd_full               ( p4_cmd_full_i             ),
   .p4_wr_clk                 ( p4_wr_clk_i               ),
   .p4_wr_en                  ( p4_wr_en_i                ),
   .p4_wr_mask                ( p4_wr_mask_i              ),
   .p4_wr_data                ( p4_wr_data_i              ),
   .p4_wr_full                ( p4_wr_full_i              ),
   .p4_wr_empty               ( p4_wr_empty_i             ),
   .p4_wr_count               ( p4_wr_count_i             ),
   .p4_wr_underrun            ( p4_wr_underrun_i          ),
   .p4_wr_error               ( p4_wr_error_i             ),
   .p4_rd_clk                 ( p4_rd_clk_i               ),
   .p4_rd_en                  ( p4_rd_en_i                ),
   .p4_rd_data                ( p4_rd_data_i              ),
   .p4_rd_full                ( p4_rd_full_i              ),
   .p4_rd_empty               ( p4_rd_empty_i             ),
   .p4_rd_count               ( p4_rd_count_i             ),
   .p4_rd_overflow            ( p4_rd_overflow_i          ),
   .p4_rd_error               ( p4_rd_error_i             ),
   .p5_arb_en                 ( p5_arb_en_i               ),
   .p5_cmd_clk                ( p5_cmd_clk_i              ),
   .p5_cmd_en                 ( p5_cmd_en_i               ),
   .p5_cmd_instr              ( p5_cmd_instr_i            ),
   .p5_cmd_bl                 ( p5_cmd_bl_i               ),
   .p5_cmd_byte_addr          ( p5_cmd_byte_addr_i        ),
   .p5_cmd_empty              ( p5_cmd_empty_i            ),
   .p5_cmd_full               ( p5_cmd_full_i             ),
   .p5_wr_clk                 ( p5_wr_clk_i               ),
   .p5_wr_en                  ( p5_wr_en_i                ),
   .p5_wr_mask                ( p5_wr_mask_i              ),
   .p5_wr_data                ( p5_wr_data_i              ),
   .p5_wr_full                ( p5_wr_full_i              ),
   .p5_wr_empty               ( p5_wr_empty_i             ),
   .p5_wr_count               ( p5_wr_count_i             ),
   .p5_wr_underrun            ( p5_wr_underrun_i          ),
   .p5_wr_error               ( p5_wr_error_i             ),
   .p5_rd_clk                 ( p5_rd_clk_i               ),
   .p5_rd_en                  ( p5_rd_en_i                ),
   .p5_rd_data                ( p5_rd_data_i              ),
   .p5_rd_full                ( p5_rd_full_i              ),
   .p5_rd_empty               ( p5_rd_empty_i             ),
   .p5_rd_count               ( p5_rd_count_i             ),
   .p5_rd_overflow            ( p5_rd_overflow_i          ),
   .p5_rd_error               ( p5_rd_error_i             ),
   .mcbx_dram_addr            ( mcbx_dram_addr            ),
   .mcbx_dram_ba              ( mcbx_dram_ba              ),
   .mcbx_dram_ras_n           ( mcbx_dram_ras_n           ),
   .mcbx_dram_cas_n           ( mcbx_dram_cas_n           ),
   .mcbx_dram_we_n            ( mcbx_dram_we_n            ),
   .mcbx_dram_cke             ( mcbx_dram_cke             ),
   .mcbx_dram_clk             ( mcbx_dram_clk             ),
   .mcbx_dram_clk_n           ( mcbx_dram_clk_n           ),
   .mcbx_dram_dq              ( mcbx_dram_dq              ),
   .mcbx_dram_dqs             ( mcbx_dram_dqs             ),
   .mcbx_dram_dqs_n           ( mcbx_dram_dqs_n           ),
   .mcbx_dram_udqs            ( mcbx_dram_udqs            ),
   .mcbx_dram_udqs_n          ( mcbx_dram_udqs_n          ),
   .mcbx_dram_udm             ( mcbx_dram_udm             ),
   .mcbx_dram_ldm             ( mcbx_dram_ldm             ),
   .mcbx_dram_odt             ( mcbx_dram_odt             ),
   .mcbx_dram_ddr3_rst        ( mcbx_dram_ddr3_rst        ),
   .calib_recal               ( calib_recal               ),
   .rzq                       ( rzq                       ),
   .zio                       ( zio                       ),
   .ui_read                   ( ui_read                   ),
   .ui_add                    ( ui_add                    ),
   .ui_cs                     ( ui_cs                     ),
   .ui_clk                    ( ui_clk                    ),
   .ui_sdi                    ( ui_sdi                    ),
   .ui_addr                   ( ui_addr                   ),
   .ui_broadcast              ( ui_broadcast              ),
   .ui_drp_update             ( ui_drp_update             ),
   .ui_done_cal               ( ui_done_cal               ),
   .ui_cmd                    ( ui_cmd                    ),
   .ui_cmd_in                 ( ui_cmd_in                 ),
   .ui_cmd_en                 ( ui_cmd_en                 ),
   .ui_dqcount                ( ui_dqcount                ),
   .ui_dq_lower_dec           ( ui_dq_lower_dec           ),
   .ui_dq_lower_inc           ( ui_dq_lower_inc           ),
   .ui_dq_upper_dec           ( ui_dq_upper_dec           ),
   .ui_dq_upper_inc           ( ui_dq_upper_inc           ),
   .ui_udqs_inc               ( ui_udqs_inc               ),
   .ui_udqs_dec               ( ui_udqs_dec               ),
   .ui_ldqs_inc               ( ui_ldqs_inc               ),
   .ui_ldqs_dec               ( ui_ldqs_dec               ),
   .uo_data                   ( uo_data                   ),
   .uo_data_valid             ( uo_data_valid             ),
   .uo_done_cal               ( uo_done_cal               ),
   .uo_cmd_ready_in           ( uo_cmd_ready_in           ),
   .uo_refrsh_flag            ( uo_refrsh_flag            ),
   .uo_cal_start              ( uo_cal_start              ),
   .uo_sdo                    ( uo_sdo                    ),
   .status                    ( status                    ),
   .selfrefresh_enter         ( selfrefresh_enter         ),
   .selfrefresh_mode          ( selfrefresh_mode          )
   );

// P0 AXI Bridge Mux
  generate
    if (C_S0_AXI_ENABLE == 0) begin : P0_UI_MCB
      assign  p0_arb_en_i        =  p0_arb_en        ; //
      assign  p0_cmd_clk_i       =  p0_cmd_clk       ; //
      assign  p0_cmd_en_i        =  p0_cmd_en        ; //
      assign  p0_cmd_instr_i     =  p0_cmd_instr     ; // [2:0]
      assign  p0_cmd_bl_i        =  p0_cmd_bl        ; // [5:0]
      assign  p0_cmd_byte_addr_i =  p0_cmd_byte_addr ; // [29:0]
      assign  p0_cmd_empty       =  p0_cmd_empty_i   ; //
      assign  p0_cmd_full        =  p0_cmd_full_i    ; //
      assign  p0_wr_clk_i        =  p0_wr_clk        ; //
      assign  p0_wr_en_i         =  p0_wr_en         ; //
      assign  p0_wr_mask_i       =  p0_wr_mask       ; // [C_P0_MASK_SIZE-1:0]
      assign  p0_wr_data_i       =  p0_wr_data       ; // [C_P0_DATA_PORT_SIZE-1:0]
      assign  p0_wr_full         =  p0_wr_full_i     ; //
      assign  p0_wr_empty        =  p0_wr_empty_i    ; //
      assign  p0_wr_count        =  p0_wr_count_i    ; // [6:0]
      assign  p0_wr_underrun     =  p0_wr_underrun_i ; //
      assign  p0_wr_error        =  p0_wr_error_i    ; //
      assign  p0_rd_clk_i        =  p0_rd_clk        ; //
      assign  p0_rd_en_i         =  p0_rd_en         ; //
      assign  p0_rd_data         =  p0_rd_data_i     ; // [C_P0_DATA_PORT_SIZE-1:0]
      assign  p0_rd_full         =  p0_rd_full_i     ; //
      assign  p0_rd_empty        =  p0_rd_empty_i    ; //
      assign  p0_rd_count        =  p0_rd_count_i    ; // [6:0]
      assign  p0_rd_overflow     =  p0_rd_overflow_i ; //
      assign  p0_rd_error        =  p0_rd_error_i    ; //
    end
    else begin : P0_UI_AXI
      assign  p0_arb_en_i        =  p0_arb_en;
      assign  s0_axi_araddr_i    = s0_axi_araddr & P_S0_AXI_ADDRMASK;
      assign  s0_axi_awaddr_i    = s0_axi_awaddr & P_S0_AXI_ADDRMASK;
      wire                     calib_done_synch;

      mcb_ui_top_synch #(
        .C_SYNCH_WIDTH          ( 1 )
      )
      axi_mcb_synch
      (
        .clk       ( s0_axi_aclk      ) ,
        .synch_in  ( uo_done_cal      ) ,
        .synch_out ( calib_done_synch )
      );
      axi_mcb #
        (
        .C_FAMILY                ( "spartan6"               ) ,
        .C_S_AXI_ID_WIDTH        ( C_S0_AXI_ID_WIDTH        ) ,
        .C_S_AXI_ADDR_WIDTH      ( C_S0_AXI_ADDR_WIDTH      ) ,
        .C_S_AXI_DATA_WIDTH      ( C_S0_AXI_DATA_WIDTH      ) ,
        .C_S_AXI_SUPPORTS_READ   ( C_S0_AXI_SUPPORTS_READ   ) ,
        .C_S_AXI_SUPPORTS_WRITE  ( C_S0_AXI_SUPPORTS_WRITE  ) ,
        .C_S_AXI_REG_EN0         ( C_S0_AXI_REG_EN0         ) ,
        .C_S_AXI_REG_EN1         ( C_S0_AXI_REG_EN1         ) ,
        .C_S_AXI_SUPPORTS_NARROW_BURST ( C_S0_AXI_SUPPORTS_NARROW_BURST ) ,
        .C_MCB_ADDR_WIDTH        ( 30                       ) ,
        .C_MCB_DATA_WIDTH        ( C_P0_DATA_PORT_SIZE      ) ,
        .C_STRICT_COHERENCY      ( C_S0_AXI_STRICT_COHERENCY    ) ,
        .C_ENABLE_AP             ( C_S0_AXI_ENABLE_AP           )
        )
        p0_axi_mcb
        (
        .aclk              ( s0_axi_aclk        ),
        .aresetn           ( s0_axi_aresetn     ),
        .s_axi_awid        ( s0_axi_awid        ),
        .s_axi_awaddr      ( s0_axi_awaddr_i    ),
        .s_axi_awlen       ( s0_axi_awlen       ),
        .s_axi_awsize      ( s0_axi_awsize      ),
        .s_axi_awburst     ( s0_axi_awburst     ),
        .s_axi_awlock      ( s0_axi_awlock      ),
        .s_axi_awcache     ( s0_axi_awcache     ),
        .s_axi_awprot      ( s0_axi_awprot      ),
        .s_axi_awqos       ( s0_axi_awqos       ),
        .s_axi_awvalid     ( s0_axi_awvalid     ),
        .s_axi_awready     ( s0_axi_awready     ),
        .s_axi_wdata       ( s0_axi_wdata       ),
        .s_axi_wstrb       ( s0_axi_wstrb       ),
        .s_axi_wlast       ( s0_axi_wlast       ),
        .s_axi_wvalid      ( s0_axi_wvalid      ),
        .s_axi_wready      ( s0_axi_wready      ),
        .s_axi_bid         ( s0_axi_bid         ),
        .s_axi_bresp       ( s0_axi_bresp       ),
        .s_axi_bvalid      ( s0_axi_bvalid      ),
        .s_axi_bready      ( s0_axi_bready      ),
        .s_axi_arid        ( s0_axi_arid        ),
        .s_axi_araddr      ( s0_axi_araddr_i    ),
        .s_axi_arlen       ( s0_axi_arlen       ),
        .s_axi_arsize      ( s0_axi_arsize      ),
        .s_axi_arburst     ( s0_axi_arburst     ),
        .s_axi_arlock      ( s0_axi_arlock      ),
        .s_axi_arcache     ( s0_axi_arcache     ),
        .s_axi_arprot      ( s0_axi_arprot      ),
        .s_axi_arqos       ( s0_axi_arqos       ),
        .s_axi_arvalid     ( s0_axi_arvalid     ),
        .s_axi_arready     ( s0_axi_arready     ),
        .s_axi_rid         ( s0_axi_rid         ),
        .s_axi_rdata       ( s0_axi_rdata       ),
        .s_axi_rresp       ( s0_axi_rresp       ),
        .s_axi_rlast       ( s0_axi_rlast       ),
        .s_axi_rvalid      ( s0_axi_rvalid      ),
        .s_axi_rready      ( s0_axi_rready      ),
        .mcb_cmd_clk       ( p0_cmd_clk_i       ),
        .mcb_cmd_en        ( p0_cmd_en_i        ),
        .mcb_cmd_instr     ( p0_cmd_instr_i     ),
        .mcb_cmd_bl        ( p0_cmd_bl_i        ),
        .mcb_cmd_byte_addr ( p0_cmd_byte_addr_i ),
        .mcb_cmd_empty     ( p0_cmd_empty_i     ),
        .mcb_cmd_full      ( p0_cmd_full_i      ),
        .mcb_wr_clk        ( p0_wr_clk_i        ),
        .mcb_wr_en         ( p0_wr_en_i         ),
        .mcb_wr_mask       ( p0_wr_mask_i       ),
        .mcb_wr_data       ( p0_wr_data_i       ),
        .mcb_wr_full       ( p0_wr_full_i       ),
        .mcb_wr_empty      ( p0_wr_empty_i      ),
        .mcb_wr_count      ( p0_wr_count_i      ),
        .mcb_wr_underrun   ( p0_wr_underrun_i   ),
        .mcb_wr_error      ( p0_wr_error_i      ),
        .mcb_rd_clk        ( p0_rd_clk_i        ),
        .mcb_rd_en         ( p0_rd_en_i         ),
        .mcb_rd_data       ( p0_rd_data_i       ),
        .mcb_rd_full       ( p0_rd_full_i       ),
        .mcb_rd_empty      ( p0_rd_empty_i      ),
        .mcb_rd_count      ( p0_rd_count_i      ),
        .mcb_rd_overflow   ( p0_rd_overflow_i   ),
        .mcb_rd_error      ( p0_rd_error_i      ),
        .mcb_calib_done    ( calib_done_synch   )
        );
    end
  endgenerate

// P1 AXI Bridge Mux
  generate
    if (C_S1_AXI_ENABLE == 0) begin : P1_UI_MCB
      assign  p1_arb_en_i        =  p1_arb_en        ; //
      assign  p1_cmd_clk_i       =  p1_cmd_clk       ; //
      assign  p1_cmd_en_i        =  p1_cmd_en        ; //
      assign  p1_cmd_instr_i     =  p1_cmd_instr     ; // [2:0]
      assign  p1_cmd_bl_i        =  p1_cmd_bl        ; // [5:0]
      assign  p1_cmd_byte_addr_i =  p1_cmd_byte_addr ; // [29:0]
      assign  p1_cmd_empty       =  p1_cmd_empty_i   ; //
      assign  p1_cmd_full        =  p1_cmd_full_i    ; //
      assign  p1_wr_clk_i        =  p1_wr_clk        ; //
      assign  p1_wr_en_i         =  p1_wr_en         ; //
      assign  p1_wr_mask_i       =  p1_wr_mask       ; // [C_P1_MASK_SIZE-1:0]
      assign  p1_wr_data_i       =  p1_wr_data       ; // [C_P1_DATA_PORT_SIZE-1:0]
      assign  p1_wr_full         =  p1_wr_full_i     ; //
      assign  p1_wr_empty        =  p1_wr_empty_i    ; //
      assign  p1_wr_count        =  p1_wr_count_i    ; // [6:0]
      assign  p1_wr_underrun     =  p1_wr_underrun_i ; //
      assign  p1_wr_error        =  p1_wr_error_i    ; //
      assign  p1_rd_clk_i        =  p1_rd_clk        ; //
      assign  p1_rd_en_i         =  p1_rd_en         ; //
      assign  p1_rd_data         =  p1_rd_data_i     ; // [C_P1_DATA_PORT_SIZE-1:0]
      assign  p1_rd_full         =  p1_rd_full_i     ; //
      assign  p1_rd_empty        =  p1_rd_empty_i    ; //
      assign  p1_rd_count        =  p1_rd_count_i    ; // [6:0]
      assign  p1_rd_overflow     =  p1_rd_overflow_i ; //
      assign  p1_rd_error        =  p1_rd_error_i    ; //
    end
    else begin : P1_UI_AXI
      assign  p1_arb_en_i        =  p1_arb_en;
      assign  s1_axi_araddr_i    = s1_axi_araddr & P_S1_AXI_ADDRMASK;
      assign  s1_axi_awaddr_i    = s1_axi_awaddr & P_S1_AXI_ADDRMASK;
      wire                     calib_done_synch;

      mcb_ui_top_synch #(
        .C_SYNCH_WIDTH          ( 1 )
      )
      axi_mcb_synch
      (
        .clk                    ( s1_axi_aclk      ),
        .synch_in               ( uo_done_cal      ),
        .synch_out              ( calib_done_synch )
      );
      axi_mcb #
        (
        .C_FAMILY                ( "spartan6"               ) ,
        .C_S_AXI_ID_WIDTH        ( C_S1_AXI_ID_WIDTH        ) ,
        .C_S_AXI_ADDR_WIDTH      ( C_S1_AXI_ADDR_WIDTH      ) ,
        .C_S_AXI_DATA_WIDTH      ( C_S1_AXI_DATA_WIDTH      ) ,
        .C_S_AXI_SUPPORTS_READ   ( C_S1_AXI_SUPPORTS_READ   ) ,
        .C_S_AXI_SUPPORTS_WRITE  ( C_S1_AXI_SUPPORTS_WRITE  ) ,
        .C_S_AXI_REG_EN0         ( C_S1_AXI_REG_EN0         ) ,
        .C_S_AXI_REG_EN1         ( C_S1_AXI_REG_EN1         ) ,
        .C_S_AXI_SUPPORTS_NARROW_BURST ( C_S1_AXI_SUPPORTS_NARROW_BURST ) ,
        .C_MCB_ADDR_WIDTH        ( 30                       ) ,
        .C_MCB_DATA_WIDTH        ( C_P1_DATA_PORT_SIZE      ) ,
        .C_STRICT_COHERENCY      ( C_S1_AXI_STRICT_COHERENCY    ) ,
        .C_ENABLE_AP             ( C_S1_AXI_ENABLE_AP           )
        )
        p1_axi_mcb
        (
        .aclk              ( s1_axi_aclk        ),
        .aresetn           ( s1_axi_aresetn     ),
        .s_axi_awid        ( s1_axi_awid        ),
        .s_axi_awaddr      ( s1_axi_awaddr_i    ),
        .s_axi_awlen       ( s1_axi_awlen       ),
        .s_axi_awsize      ( s1_axi_awsize      ),
        .s_axi_awburst     ( s1_axi_awburst     ),
        .s_axi_awlock      ( s1_axi_awlock      ),
        .s_axi_awcache     ( s1_axi_awcache     ),
        .s_axi_awprot      ( s1_axi_awprot      ),
        .s_axi_awqos       ( s1_axi_awqos       ),
        .s_axi_awvalid     ( s1_axi_awvalid     ),
        .s_axi_awready     ( s1_axi_awready     ),
        .s_axi_wdata       ( s1_axi_wdata       ),
        .s_axi_wstrb       ( s1_axi_wstrb       ),
        .s_axi_wlast       ( s1_axi_wlast       ),
        .s_axi_wvalid      ( s1_axi_wvalid      ),
        .s_axi_wready      ( s1_axi_wready      ),
        .s_axi_bid         ( s1_axi_bid         ),
        .s_axi_bresp       ( s1_axi_bresp       ),
        .s_axi_bvalid      ( s1_axi_bvalid      ),
        .s_axi_bready      ( s1_axi_bready      ),
        .s_axi_arid        ( s1_axi_arid        ),
        .s_axi_araddr      ( s1_axi_araddr_i    ),
        .s_axi_arlen       ( s1_axi_arlen       ),
        .s_axi_arsize      ( s1_axi_arsize      ),
        .s_axi_arburst     ( s1_axi_arburst     ),
        .s_axi_arlock      ( s1_axi_arlock      ),
        .s_axi_arcache     ( s1_axi_arcache     ),
        .s_axi_arprot      ( s1_axi_arprot      ),
        .s_axi_arqos       ( s1_axi_arqos       ),
        .s_axi_arvalid     ( s1_axi_arvalid     ),
        .s_axi_arready     ( s1_axi_arready     ),
        .s_axi_rid         ( s1_axi_rid         ),
        .s_axi_rdata       ( s1_axi_rdata       ),
        .s_axi_rresp       ( s1_axi_rresp       ),
        .s_axi_rlast       ( s1_axi_rlast       ),
        .s_axi_rvalid      ( s1_axi_rvalid      ),
        .s_axi_rready      ( s1_axi_rready      ),
        .mcb_cmd_clk       ( p1_cmd_clk_i       ),
        .mcb_cmd_en        ( p1_cmd_en_i        ),
        .mcb_cmd_instr     ( p1_cmd_instr_i     ),
        .mcb_cmd_bl        ( p1_cmd_bl_i        ),
        .mcb_cmd_byte_addr ( p1_cmd_byte_addr_i ),
        .mcb_cmd_empty     ( p1_cmd_empty_i     ),
        .mcb_cmd_full      ( p1_cmd_full_i      ),
        .mcb_wr_clk        ( p1_wr_clk_i        ),
        .mcb_wr_en         ( p1_wr_en_i         ),
        .mcb_wr_mask       ( p1_wr_mask_i       ),
        .mcb_wr_data       ( p1_wr_data_i       ),
        .mcb_wr_full       ( p1_wr_full_i       ),
        .mcb_wr_empty      ( p1_wr_empty_i      ),
        .mcb_wr_count      ( p1_wr_count_i      ),
        .mcb_wr_underrun   ( p1_wr_underrun_i   ),
        .mcb_wr_error      ( p1_wr_error_i      ),
        .mcb_rd_clk        ( p1_rd_clk_i        ),
        .mcb_rd_en         ( p1_rd_en_i         ),
        .mcb_rd_data       ( p1_rd_data_i       ),
        .mcb_rd_full       ( p1_rd_full_i       ),
        .mcb_rd_empty      ( p1_rd_empty_i      ),
        .mcb_rd_count      ( p1_rd_count_i      ),
        .mcb_rd_overflow   ( p1_rd_overflow_i   ),
        .mcb_rd_error      ( p1_rd_error_i      ),
        .mcb_calib_done    ( calib_done_synch   )
        );
    end
  endgenerate

// P2 AXI Bridge Mux
  generate
    if (C_S2_AXI_ENABLE == 0) begin : P2_UI_MCB
      assign  p2_arb_en_i        =  p2_arb_en        ; //
      assign  p2_cmd_clk_i       =  p2_cmd_clk       ; //
      assign  p2_cmd_en_i        =  p2_cmd_en        ; //
      assign  p2_cmd_instr_i     =  p2_cmd_instr     ; // [2:0]
      assign  p2_cmd_bl_i        =  p2_cmd_bl        ; // [5:0]
      assign  p2_cmd_byte_addr_i =  p2_cmd_byte_addr ; // [29:0]
      assign  p2_cmd_empty       =  p2_cmd_empty_i   ; //
      assign  p2_cmd_full        =  p2_cmd_full_i    ; //
      assign  p2_wr_clk_i        =  p2_wr_clk        ; //
      assign  p2_wr_en_i         =  p2_wr_en         ; //
      assign  p2_wr_mask_i       =  p2_wr_mask       ; // [3:0]
      assign  p2_wr_data_i       =  p2_wr_data       ; // [31:0]
      assign  p2_wr_full         =  p2_wr_full_i     ; //
      assign  p2_wr_empty        =  p2_wr_empty_i    ; //
      assign  p2_wr_count        =  p2_wr_count_i    ; // [6:0]
      assign  p2_wr_underrun     =  p2_wr_underrun_i ; //
      assign  p2_wr_error        =  p2_wr_error_i    ; //
      assign  p2_rd_clk_i        =  p2_rd_clk        ; //
      assign  p2_rd_en_i         =  p2_rd_en         ; //
      assign  p2_rd_data         =  p2_rd_data_i     ; // [31:0]
      assign  p2_rd_full         =  p2_rd_full_i     ; //
      assign  p2_rd_empty        =  p2_rd_empty_i    ; //
      assign  p2_rd_count        =  p2_rd_count_i    ; // [6:0]
      assign  p2_rd_overflow     =  p2_rd_overflow_i ; //
      assign  p2_rd_error        =  p2_rd_error_i    ; //
    end
    else begin : P2_UI_AXI
      assign  p2_arb_en_i        =  p2_arb_en;
      assign  s2_axi_araddr_i    = s2_axi_araddr & P_S2_AXI_ADDRMASK;
      assign  s2_axi_awaddr_i    = s2_axi_awaddr & P_S2_AXI_ADDRMASK;
      wire                     calib_done_synch;

      mcb_ui_top_synch #(
        .C_SYNCH_WIDTH          ( 1 )
      )
      axi_mcb_synch
      (
        .clk                    ( s2_axi_aclk      ),
        .synch_in               ( uo_done_cal      ),
        .synch_out              ( calib_done_synch )
      );
      axi_mcb #
        (
        .C_FAMILY                ( "spartan6"               ) ,
        .C_S_AXI_ID_WIDTH        ( C_S2_AXI_ID_WIDTH        ) ,
        .C_S_AXI_ADDR_WIDTH      ( C_S2_AXI_ADDR_WIDTH      ) ,
        .C_S_AXI_DATA_WIDTH      ( 32                       ) ,
        .C_S_AXI_SUPPORTS_READ   ( C_S2_AXI_SUPPORTS_READ   ) ,
        .C_S_AXI_SUPPORTS_WRITE  ( C_S2_AXI_SUPPORTS_WRITE  ) ,
        .C_S_AXI_REG_EN0         ( C_S2_AXI_REG_EN0         ) ,
        .C_S_AXI_REG_EN1         ( C_S2_AXI_REG_EN1         ) ,
        .C_S_AXI_SUPPORTS_NARROW_BURST ( C_S2_AXI_SUPPORTS_NARROW_BURST ) ,
        .C_MCB_ADDR_WIDTH        ( 30                       ) ,
        .C_MCB_DATA_WIDTH        ( 32                       ) ,
        .C_STRICT_COHERENCY      ( C_S2_AXI_STRICT_COHERENCY    ) ,
        .C_ENABLE_AP             ( C_S2_AXI_ENABLE_AP           )
        )
        p2_axi_mcb
        (
        .aclk              ( s2_axi_aclk        ),
        .aresetn           ( s2_axi_aresetn     ),
        .s_axi_awid        ( s2_axi_awid        ),
        .s_axi_awaddr      ( s2_axi_awaddr_i    ),
        .s_axi_awlen       ( s2_axi_awlen       ),
        .s_axi_awsize      ( s2_axi_awsize      ),
        .s_axi_awburst     ( s2_axi_awburst     ),
        .s_axi_awlock      ( s2_axi_awlock      ),
        .s_axi_awcache     ( s2_axi_awcache     ),
        .s_axi_awprot      ( s2_axi_awprot      ),
        .s_axi_awqos       ( s2_axi_awqos       ),
        .s_axi_awvalid     ( s2_axi_awvalid     ),
        .s_axi_awready     ( s2_axi_awready     ),
        .s_axi_wdata       ( s2_axi_wdata       ),
        .s_axi_wstrb       ( s2_axi_wstrb       ),
        .s_axi_wlast       ( s2_axi_wlast       ),
        .s_axi_wvalid      ( s2_axi_wvalid      ),
        .s_axi_wready      ( s2_axi_wready      ),
        .s_axi_bid         ( s2_axi_bid         ),
        .s_axi_bresp       ( s2_axi_bresp       ),
        .s_axi_bvalid      ( s2_axi_bvalid      ),
        .s_axi_bready      ( s2_axi_bready      ),
        .s_axi_arid        ( s2_axi_arid        ),
        .s_axi_araddr      ( s2_axi_araddr_i    ),
        .s_axi_arlen       ( s2_axi_arlen       ),
        .s_axi_arsize      ( s2_axi_arsize      ),
        .s_axi_arburst     ( s2_axi_arburst     ),
        .s_axi_arlock      ( s2_axi_arlock      ),
        .s_axi_arcache     ( s2_axi_arcache     ),
        .s_axi_arprot      ( s2_axi_arprot      ),
        .s_axi_arqos       ( s2_axi_arqos       ),
        .s_axi_arvalid     ( s2_axi_arvalid     ),
        .s_axi_arready     ( s2_axi_arready     ),
        .s_axi_rid         ( s2_axi_rid         ),
        .s_axi_rdata       ( s2_axi_rdata       ),
        .s_axi_rresp       ( s2_axi_rresp       ),
        .s_axi_rlast       ( s2_axi_rlast       ),
        .s_axi_rvalid      ( s2_axi_rvalid      ),
        .s_axi_rready      ( s2_axi_rready      ),
        .mcb_cmd_clk       ( p2_cmd_clk_i       ),
        .mcb_cmd_en        ( p2_cmd_en_i        ),
        .mcb_cmd_instr     ( p2_cmd_instr_i     ),
        .mcb_cmd_bl        ( p2_cmd_bl_i        ),
        .mcb_cmd_byte_addr ( p2_cmd_byte_addr_i ),
        .mcb_cmd_empty     ( p2_cmd_empty_i     ),
        .mcb_cmd_full      ( p2_cmd_full_i      ),
        .mcb_wr_clk        ( p2_wr_clk_i        ),
        .mcb_wr_en         ( p2_wr_en_i         ),
        .mcb_wr_mask       ( p2_wr_mask_i       ),
        .mcb_wr_data       ( p2_wr_data_i       ),
        .mcb_wr_full       ( p2_wr_full_i       ),
        .mcb_wr_empty      ( p2_wr_empty_i      ),
        .mcb_wr_count      ( p2_wr_count_i      ),
        .mcb_wr_underrun   ( p2_wr_underrun_i   ),
        .mcb_wr_error      ( p2_wr_error_i      ),
        .mcb_rd_clk        ( p2_rd_clk_i        ),
        .mcb_rd_en         ( p2_rd_en_i         ),
        .mcb_rd_data       ( p2_rd_data_i       ),
        .mcb_rd_full       ( p2_rd_full_i       ),
        .mcb_rd_empty      ( p2_rd_empty_i      ),
        .mcb_rd_count      ( p2_rd_count_i      ),
        .mcb_rd_overflow   ( p2_rd_overflow_i   ),
        .mcb_rd_error      ( p2_rd_error_i      ),
        .mcb_calib_done    ( calib_done_synch   )
        );
    end
  endgenerate

// P3 AXI Bridge Mux
  generate
    if (C_S3_AXI_ENABLE == 0) begin : P3_UI_MCB
      assign  p3_arb_en_i        =  p3_arb_en        ; //
      assign  p3_cmd_clk_i       =  p3_cmd_clk       ; //
      assign  p3_cmd_en_i        =  p3_cmd_en        ; //
      assign  p3_cmd_instr_i     =  p3_cmd_instr     ; // [2:0]
      assign  p3_cmd_bl_i        =  p3_cmd_bl        ; // [5:0]
      assign  p3_cmd_byte_addr_i =  p3_cmd_byte_addr ; // [29:0]
      assign  p3_cmd_empty       =  p3_cmd_empty_i   ; //
      assign  p3_cmd_full        =  p3_cmd_full_i    ; //
      assign  p3_wr_clk_i        =  p3_wr_clk        ; //
      assign  p3_wr_en_i         =  p3_wr_en         ; //
      assign  p3_wr_mask_i       =  p3_wr_mask       ; // [3:0]
      assign  p3_wr_data_i       =  p3_wr_data       ; // [31:0]
      assign  p3_wr_full         =  p3_wr_full_i     ; //
      assign  p3_wr_empty        =  p3_wr_empty_i    ; //
      assign  p3_wr_count        =  p3_wr_count_i    ; // [6:0]
      assign  p3_wr_underrun     =  p3_wr_underrun_i ; //
      assign  p3_wr_error        =  p3_wr_error_i    ; //
      assign  p3_rd_clk_i        =  p3_rd_clk        ; //
      assign  p3_rd_en_i         =  p3_rd_en         ; //
      assign  p3_rd_data         =  p3_rd_data_i     ; // [31:0]
      assign  p3_rd_full         =  p3_rd_full_i     ; //
      assign  p3_rd_empty        =  p3_rd_empty_i    ; //
      assign  p3_rd_count        =  p3_rd_count_i    ; // [6:0]
      assign  p3_rd_overflow     =  p3_rd_overflow_i ; //
      assign  p3_rd_error        =  p3_rd_error_i    ; //
    end
    else begin : P3_UI_AXI
      assign  p3_arb_en_i        =  p3_arb_en;
      assign  s3_axi_araddr_i    = s3_axi_araddr & P_S3_AXI_ADDRMASK;
      assign  s3_axi_awaddr_i    = s3_axi_awaddr & P_S3_AXI_ADDRMASK;
      wire                     calib_done_synch;

      mcb_ui_top_synch #(
        .C_SYNCH_WIDTH          ( 1 )
      )
      axi_mcb_synch
      (
        .clk                    ( s3_axi_aclk      ),
        .synch_in               ( uo_done_cal      ),
        .synch_out              ( calib_done_synch )
      );

      axi_mcb #
        (
        .C_FAMILY                ( "spartan6"               ) ,
        .C_S_AXI_ID_WIDTH        ( C_S3_AXI_ID_WIDTH        ) ,
        .C_S_AXI_ADDR_WIDTH      ( C_S3_AXI_ADDR_WIDTH      ) ,
        .C_S_AXI_DATA_WIDTH      ( 32                       ) ,
        .C_S_AXI_SUPPORTS_READ   ( C_S3_AXI_SUPPORTS_READ   ) ,
        .C_S_AXI_SUPPORTS_WRITE  ( C_S3_AXI_SUPPORTS_WRITE  ) ,
        .C_S_AXI_REG_EN0         ( C_S3_AXI_REG_EN0         ) ,
        .C_S_AXI_REG_EN1         ( C_S3_AXI_REG_EN1         ) ,
        .C_S_AXI_SUPPORTS_NARROW_BURST ( C_S3_AXI_SUPPORTS_NARROW_BURST ) ,
        .C_MCB_ADDR_WIDTH        ( 30                       ) ,
        .C_MCB_DATA_WIDTH        ( 32                       ) ,
        .C_STRICT_COHERENCY      ( C_S3_AXI_STRICT_COHERENCY    ) ,
        .C_ENABLE_AP             ( C_S3_AXI_ENABLE_AP           )
        )
        p3_axi_mcb
        (
        .aclk              ( s3_axi_aclk        ),
        .aresetn           ( s3_axi_aresetn     ),
        .s_axi_awid        ( s3_axi_awid        ),
        .s_axi_awaddr      ( s3_axi_awaddr_i    ),
        .s_axi_awlen       ( s3_axi_awlen       ),
        .s_axi_awsize      ( s3_axi_awsize      ),
        .s_axi_awburst     ( s3_axi_awburst     ),
        .s_axi_awlock      ( s3_axi_awlock      ),
        .s_axi_awcache     ( s3_axi_awcache     ),
        .s_axi_awprot      ( s3_axi_awprot      ),
        .s_axi_awqos       ( s3_axi_awqos       ),
        .s_axi_awvalid     ( s3_axi_awvalid     ),
        .s_axi_awready     ( s3_axi_awready     ),
        .s_axi_wdata       ( s3_axi_wdata       ),
        .s_axi_wstrb       ( s3_axi_wstrb       ),
        .s_axi_wlast       ( s3_axi_wlast       ),
        .s_axi_wvalid      ( s3_axi_wvalid      ),
        .s_axi_wready      ( s3_axi_wready      ),
        .s_axi_bid         ( s3_axi_bid         ),
        .s_axi_bresp       ( s3_axi_bresp       ),
        .s_axi_bvalid      ( s3_axi_bvalid      ),
        .s_axi_bready      ( s3_axi_bready      ),
        .s_axi_arid        ( s3_axi_arid        ),
        .s_axi_araddr      ( s3_axi_araddr_i    ),
        .s_axi_arlen       ( s3_axi_arlen       ),
        .s_axi_arsize      ( s3_axi_arsize      ),
        .s_axi_arburst     ( s3_axi_arburst     ),
        .s_axi_arlock      ( s3_axi_arlock      ),
        .s_axi_arcache     ( s3_axi_arcache     ),
        .s_axi_arprot      ( s3_axi_arprot      ),
        .s_axi_arqos       ( s3_axi_arqos       ),
        .s_axi_arvalid     ( s3_axi_arvalid     ),
        .s_axi_arready     ( s3_axi_arready     ),
        .s_axi_rid         ( s3_axi_rid         ),
        .s_axi_rdata       ( s3_axi_rdata       ),
        .s_axi_rresp       ( s3_axi_rresp       ),
        .s_axi_rlast       ( s3_axi_rlast       ),
        .s_axi_rvalid      ( s3_axi_rvalid      ),
        .s_axi_rready      ( s3_axi_rready      ),
        .mcb_cmd_clk       ( p3_cmd_clk_i       ),
        .mcb_cmd_en        ( p3_cmd_en_i        ),
        .mcb_cmd_instr     ( p3_cmd_instr_i     ),
        .mcb_cmd_bl        ( p3_cmd_bl_i        ),
        .mcb_cmd_byte_addr ( p3_cmd_byte_addr_i ),
        .mcb_cmd_empty     ( p3_cmd_empty_i     ),
        .mcb_cmd_full      ( p3_cmd_full_i      ),
        .mcb_wr_clk        ( p3_wr_clk_i        ),
        .mcb_wr_en         ( p3_wr_en_i         ),
        .mcb_wr_mask       ( p3_wr_mask_i       ),
        .mcb_wr_data       ( p3_wr_data_i       ),
        .mcb_wr_full       ( p3_wr_full_i       ),
        .mcb_wr_empty      ( p3_wr_empty_i      ),
        .mcb_wr_count      ( p3_wr_count_i      ),
        .mcb_wr_underrun   ( p3_wr_underrun_i   ),
        .mcb_wr_error      ( p3_wr_error_i      ),
        .mcb_rd_clk        ( p3_rd_clk_i        ),
        .mcb_rd_en         ( p3_rd_en_i         ),
        .mcb_rd_data       ( p3_rd_data_i       ),
        .mcb_rd_full       ( p3_rd_full_i       ),
        .mcb_rd_empty      ( p3_rd_empty_i      ),
        .mcb_rd_count      ( p3_rd_count_i      ),
        .mcb_rd_overflow   ( p3_rd_overflow_i   ),
        .mcb_rd_error      ( p3_rd_error_i      ),
        .mcb_calib_done    ( calib_done_synch   )
        );
    end
  endgenerate

// P4 AXI Bridge Mux
  generate
    if (C_S4_AXI_ENABLE == 0) begin : P4_UI_MCB
      assign  p4_arb_en_i        =  p4_arb_en        ; //
      assign  p4_cmd_clk_i       =  p4_cmd_clk       ; //
      assign  p4_cmd_en_i        =  p4_cmd_en        ; //
      assign  p4_cmd_instr_i     =  p4_cmd_instr     ; // [2:0]
      assign  p4_cmd_bl_i        =  p4_cmd_bl        ; // [5:0]
      assign  p4_cmd_byte_addr_i =  p4_cmd_byte_addr ; // [29:0]
      assign  p4_cmd_empty       =  p4_cmd_empty_i   ; //
      assign  p4_cmd_full        =  p4_cmd_full_i    ; //
      assign  p4_wr_clk_i        =  p4_wr_clk        ; //
      assign  p4_wr_en_i         =  p4_wr_en         ; //
      assign  p4_wr_mask_i       =  p4_wr_mask       ; // [3:0]
      assign  p4_wr_data_i       =  p4_wr_data       ; // [31:0]
      assign  p4_wr_full         =  p4_wr_full_i     ; //
      assign  p4_wr_empty        =  p4_wr_empty_i    ; //
      assign  p4_wr_count        =  p4_wr_count_i    ; // [6:0]
      assign  p4_wr_underrun     =  p4_wr_underrun_i ; //
      assign  p4_wr_error        =  p4_wr_error_i    ; //
      assign  p4_rd_clk_i        =  p4_rd_clk        ; //
      assign  p4_rd_en_i         =  p4_rd_en         ; //
      assign  p4_rd_data         =  p4_rd_data_i     ; // [31:0]
      assign  p4_rd_full         =  p4_rd_full_i     ; //
      assign  p4_rd_empty        =  p4_rd_empty_i    ; //
      assign  p4_rd_count        =  p4_rd_count_i    ; // [6:0]
      assign  p4_rd_overflow     =  p4_rd_overflow_i ; //
      assign  p4_rd_error        =  p4_rd_error_i    ; //
    end
    else begin : P4_UI_AXI
      assign  p4_arb_en_i        =  p4_arb_en;
      assign  s4_axi_araddr_i    = s4_axi_araddr & P_S4_AXI_ADDRMASK;
      assign  s4_axi_awaddr_i    = s4_axi_awaddr & P_S4_AXI_ADDRMASK;
      wire                     calib_done_synch;

      mcb_ui_top_synch #(
        .C_SYNCH_WIDTH          ( 1 )
      )
      axi_mcb_synch
      (
        .clk                    ( s4_axi_aclk      ),
        .synch_in               ( uo_done_cal      ),
        .synch_out              ( calib_done_synch )
      );

      axi_mcb #
        (
        .C_FAMILY                ( "spartan6"               ) ,
        .C_S_AXI_ID_WIDTH        ( C_S4_AXI_ID_WIDTH        ) ,
        .C_S_AXI_ADDR_WIDTH      ( C_S4_AXI_ADDR_WIDTH      ) ,
        .C_S_AXI_DATA_WIDTH      ( 32                       ) ,
        .C_S_AXI_SUPPORTS_READ   ( C_S4_AXI_SUPPORTS_READ   ) ,
        .C_S_AXI_SUPPORTS_WRITE  ( C_S4_AXI_SUPPORTS_WRITE  ) ,
        .C_S_AXI_REG_EN0         ( C_S4_AXI_REG_EN0         ) ,
        .C_S_AXI_REG_EN1         ( C_S4_AXI_REG_EN1         ) ,
        .C_S_AXI_SUPPORTS_NARROW_BURST ( C_S4_AXI_SUPPORTS_NARROW_BURST ) ,
        .C_MCB_ADDR_WIDTH        ( 30                       ) ,
        .C_MCB_DATA_WIDTH        ( 32                       ) ,
        .C_STRICT_COHERENCY      ( C_S4_AXI_STRICT_COHERENCY    ) ,
        .C_ENABLE_AP             ( C_S4_AXI_ENABLE_AP           )
        )
        p4_axi_mcb
        (
        .aclk              ( s4_axi_aclk        ),
        .aresetn           ( s4_axi_aresetn     ),
        .s_axi_awid        ( s4_axi_awid        ),
        .s_axi_awaddr      ( s4_axi_awaddr_i    ),
        .s_axi_awlen       ( s4_axi_awlen       ),
        .s_axi_awsize      ( s4_axi_awsize      ),
        .s_axi_awburst     ( s4_axi_awburst     ),
        .s_axi_awlock      ( s4_axi_awlock      ),
        .s_axi_awcache     ( s4_axi_awcache     ),
        .s_axi_awprot      ( s4_axi_awprot      ),
        .s_axi_awqos       ( s4_axi_awqos       ),
        .s_axi_awvalid     ( s4_axi_awvalid     ),
        .s_axi_awready     ( s4_axi_awready     ),
        .s_axi_wdata       ( s4_axi_wdata       ),
        .s_axi_wstrb       ( s4_axi_wstrb       ),
        .s_axi_wlast       ( s4_axi_wlast       ),
        .s_axi_wvalid      ( s4_axi_wvalid      ),
        .s_axi_wready      ( s4_axi_wready      ),
        .s_axi_bid         ( s4_axi_bid         ),
        .s_axi_bresp       ( s4_axi_bresp       ),
        .s_axi_bvalid      ( s4_axi_bvalid      ),
        .s_axi_bready      ( s4_axi_bready      ),
        .s_axi_arid        ( s4_axi_arid        ),
        .s_axi_araddr      ( s4_axi_araddr_i    ),
        .s_axi_arlen       ( s4_axi_arlen       ),
        .s_axi_arsize      ( s4_axi_arsize      ),
        .s_axi_arburst     ( s4_axi_arburst     ),
        .s_axi_arlock      ( s4_axi_arlock      ),
        .s_axi_arcache     ( s4_axi_arcache     ),
        .s_axi_arprot      ( s4_axi_arprot      ),
        .s_axi_arqos       ( s4_axi_arqos       ),
        .s_axi_arvalid     ( s4_axi_arvalid     ),
        .s_axi_arready     ( s4_axi_arready     ),
        .s_axi_rid         ( s4_axi_rid         ),
        .s_axi_rdata       ( s4_axi_rdata       ),
        .s_axi_rresp       ( s4_axi_rresp       ),
        .s_axi_rlast       ( s4_axi_rlast       ),
        .s_axi_rvalid      ( s4_axi_rvalid      ),
        .s_axi_rready      ( s4_axi_rready      ),
        .mcb_cmd_clk       ( p4_cmd_clk_i       ),
        .mcb_cmd_en        ( p4_cmd_en_i        ),
        .mcb_cmd_instr     ( p4_cmd_instr_i     ),
        .mcb_cmd_bl        ( p4_cmd_bl_i        ),
        .mcb_cmd_byte_addr ( p4_cmd_byte_addr_i ),
        .mcb_cmd_empty     ( p4_cmd_empty_i     ),
        .mcb_cmd_full      ( p4_cmd_full_i      ),
        .mcb_wr_clk        ( p4_wr_clk_i        ),
        .mcb_wr_en         ( p4_wr_en_i         ),
        .mcb_wr_mask       ( p4_wr_mask_i       ),
        .mcb_wr_data       ( p4_wr_data_i       ),
        .mcb_wr_full       ( p4_wr_full_i       ),
        .mcb_wr_empty      ( p4_wr_empty_i      ),
        .mcb_wr_count      ( p4_wr_count_i      ),
        .mcb_wr_underrun   ( p4_wr_underrun_i   ),
        .mcb_wr_error      ( p4_wr_error_i      ),
        .mcb_rd_clk        ( p4_rd_clk_i        ),
        .mcb_rd_en         ( p4_rd_en_i         ),
        .mcb_rd_data       ( p4_rd_data_i       ),
        .mcb_rd_full       ( p4_rd_full_i       ),
        .mcb_rd_empty      ( p4_rd_empty_i      ),
        .mcb_rd_count      ( p4_rd_count_i      ),
        .mcb_rd_overflow   ( p4_rd_overflow_i   ),
        .mcb_rd_error      ( p4_rd_error_i      ),
        .mcb_calib_done    ( calib_done_synch   )
        );
    end
  endgenerate

// P5 AXI Bridge Mux
  generate
    if (C_S5_AXI_ENABLE == 0) begin : P5_UI_MCB
      assign  p5_arb_en_i        =  p5_arb_en        ; //
      assign  p5_cmd_clk_i       =  p5_cmd_clk       ; //
      assign  p5_cmd_en_i        =  p5_cmd_en        ; //
      assign  p5_cmd_instr_i     =  p5_cmd_instr     ; // [2:0]
      assign  p5_cmd_bl_i        =  p5_cmd_bl        ; // [5:0]
      assign  p5_cmd_byte_addr_i =  p5_cmd_byte_addr ; // [29:0]
      assign  p5_cmd_empty       =  p5_cmd_empty_i   ; //
      assign  p5_cmd_full        =  p5_cmd_full_i    ; //
      assign  p5_wr_clk_i        =  p5_wr_clk        ; //
      assign  p5_wr_en_i         =  p5_wr_en         ; //
      assign  p5_wr_mask_i       =  p5_wr_mask       ; // [3:0]
      assign  p5_wr_data_i       =  p5_wr_data       ; // [31:0]
      assign  p5_wr_full         =  p5_wr_full_i     ; //
      assign  p5_wr_empty        =  p5_wr_empty_i    ; //
      assign  p5_wr_count        =  p5_wr_count_i    ; // [6:0]
      assign  p5_wr_underrun     =  p5_wr_underrun_i ; //
      assign  p5_wr_error        =  p5_wr_error_i    ; //
      assign  p5_rd_clk_i        =  p5_rd_clk        ; //
      assign  p5_rd_en_i         =  p5_rd_en         ; //
      assign  p5_rd_data         =  p5_rd_data_i     ; // [31:0]
      assign  p5_rd_full         =  p5_rd_full_i     ; //
      assign  p5_rd_empty        =  p5_rd_empty_i    ; //
      assign  p5_rd_count        =  p5_rd_count_i    ; // [6:0]
      assign  p5_rd_overflow     =  p5_rd_overflow_i ; //
      assign  p5_rd_error        =  p5_rd_error_i    ; //
    end
    else begin : P5_UI_AXI
      assign  p5_arb_en_i        =  p5_arb_en;
      assign  s5_axi_araddr_i    = s5_axi_araddr & P_S5_AXI_ADDRMASK;
      assign  s5_axi_awaddr_i    = s5_axi_awaddr & P_S5_AXI_ADDRMASK;
      wire                     calib_done_synch;

      mcb_ui_top_synch #(
        .C_SYNCH_WIDTH          ( 1 )
      )
      axi_mcb_synch
      (
        .clk                    ( s5_axi_aclk      ),
        .synch_in               ( uo_done_cal      ),
        .synch_out              ( calib_done_synch )
      );

      axi_mcb #
        (
        .C_FAMILY                ( "spartan6"               ) ,
        .C_S_AXI_ID_WIDTH        ( C_S5_AXI_ID_WIDTH        ) ,
        .C_S_AXI_ADDR_WIDTH      ( C_S5_AXI_ADDR_WIDTH      ) ,
        .C_S_AXI_DATA_WIDTH      ( 32                       ) ,
        .C_S_AXI_SUPPORTS_READ   ( C_S5_AXI_SUPPORTS_READ   ) ,
        .C_S_AXI_SUPPORTS_WRITE  ( C_S5_AXI_SUPPORTS_WRITE  ) ,
        .C_S_AXI_REG_EN0         ( C_S5_AXI_REG_EN0         ) ,
        .C_S_AXI_REG_EN1         ( C_S5_AXI_REG_EN1         ) ,
        .C_S_AXI_SUPPORTS_NARROW_BURST ( C_S5_AXI_SUPPORTS_NARROW_BURST ) ,
        .C_MCB_ADDR_WIDTH        ( 30                       ) ,
        .C_MCB_DATA_WIDTH        ( 32                       ) ,
        .C_STRICT_COHERENCY      ( C_S5_AXI_STRICT_COHERENCY    ) ,
        .C_ENABLE_AP             ( C_S5_AXI_ENABLE_AP           )
        )
        p5_axi_mcb
        (
        .aclk              ( s5_axi_aclk        ),
        .aresetn           ( s5_axi_aresetn     ),
        .s_axi_awid        ( s5_axi_awid        ),
        .s_axi_awaddr      ( s5_axi_awaddr_i    ),
        .s_axi_awlen       ( s5_axi_awlen       ),
        .s_axi_awsize      ( s5_axi_awsize      ),
        .s_axi_awburst     ( s5_axi_awburst     ),
        .s_axi_awlock      ( s5_axi_awlock      ),
        .s_axi_awcache     ( s5_axi_awcache     ),
        .s_axi_awprot      ( s5_axi_awprot      ),
        .s_axi_awqos       ( s5_axi_awqos       ),
        .s_axi_awvalid     ( s5_axi_awvalid     ),
        .s_axi_awready     ( s5_axi_awready     ),
        .s_axi_wdata       ( s5_axi_wdata       ),
        .s_axi_wstrb       ( s5_axi_wstrb       ),
        .s_axi_wlast       ( s5_axi_wlast       ),
        .s_axi_wvalid      ( s5_axi_wvalid      ),
        .s_axi_wready      ( s5_axi_wready      ),
        .s_axi_bid         ( s5_axi_bid         ),
        .s_axi_bresp       ( s5_axi_bresp       ),
        .s_axi_bvalid      ( s5_axi_bvalid      ),
        .s_axi_bready      ( s5_axi_bready      ),
        .s_axi_arid        ( s5_axi_arid        ),
        .s_axi_araddr      ( s5_axi_araddr_i    ),
        .s_axi_arlen       ( s5_axi_arlen       ),
        .s_axi_arsize      ( s5_axi_arsize      ),
        .s_axi_arburst     ( s5_axi_arburst     ),
        .s_axi_arlock      ( s5_axi_arlock      ),
        .s_axi_arcache     ( s5_axi_arcache     ),
        .s_axi_arprot      ( s5_axi_arprot      ),
        .s_axi_arqos       ( s5_axi_arqos       ),
        .s_axi_arvalid     ( s5_axi_arvalid     ),
        .s_axi_arready     ( s5_axi_arready     ),
        .s_axi_rid         ( s5_axi_rid         ),
        .s_axi_rdata       ( s5_axi_rdata       ),
        .s_axi_rresp       ( s5_axi_rresp       ),
        .s_axi_rlast       ( s5_axi_rlast       ),
        .s_axi_rvalid      ( s5_axi_rvalid      ),
        .s_axi_rready      ( s5_axi_rready      ),
        .mcb_cmd_clk       ( p5_cmd_clk_i       ),
        .mcb_cmd_en        ( p5_cmd_en_i        ),
        .mcb_cmd_instr     ( p5_cmd_instr_i     ),
        .mcb_cmd_bl        ( p5_cmd_bl_i        ),
        .mcb_cmd_byte_addr ( p5_cmd_byte_addr_i ),
        .mcb_cmd_empty     ( p5_cmd_empty_i     ),
        .mcb_cmd_full      ( p5_cmd_full_i      ),
        .mcb_wr_clk        ( p5_wr_clk_i        ),
        .mcb_wr_en         ( p5_wr_en_i         ),
        .mcb_wr_mask       ( p5_wr_mask_i       ),
        .mcb_wr_data       ( p5_wr_data_i       ),
        .mcb_wr_full       ( p5_wr_full_i       ),
        .mcb_wr_empty      ( p5_wr_empty_i      ),
        .mcb_wr_count      ( p5_wr_count_i      ),
        .mcb_wr_underrun   ( p5_wr_underrun_i   ),
        .mcb_wr_error      ( p5_wr_error_i      ),
        .mcb_rd_clk        ( p5_rd_clk_i        ),
        .mcb_rd_en         ( p5_rd_en_i         ),
        .mcb_rd_data       ( p5_rd_data_i       ),
        .mcb_rd_full       ( p5_rd_full_i       ),
        .mcb_rd_empty      ( p5_rd_empty_i      ),
        .mcb_rd_count      ( p5_rd_count_i      ),
        .mcb_rd_overflow   ( p5_rd_overflow_i   ),
        .mcb_rd_error      ( p5_rd_error_i      ),
        .mcb_calib_done    ( calib_done_synch   )
        );
    end
  endgenerate

endmodule

