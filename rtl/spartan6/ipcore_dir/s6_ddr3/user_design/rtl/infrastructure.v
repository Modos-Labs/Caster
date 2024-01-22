//*****************************************************************************
// (c) Copyright 2010 Xilinx, Inc. All rights reserved.
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
// \   \   \/     Version            : %version
//  \   \         Application        : MIG
//  /   /         Filename           : infrastructure.v
// /___/   /\     Date Last Modified : $Date: 2011/06/02 07:17:09 $
// \   \  /  \    Date Created       : Mon Mar 2 2009
//  \___\/\___\
//
//Device           : Spartan-6
//Design Name      : DDR/DDR2/DDR3/LPDDR
//Purpose          : Clock generation/distribution and reset synchronization
//Reference        :
//Revision History :
//*****************************************************************************


`timescale 1ns/1ps

module infrastructure #
  (
   parameter C_INCLK_PERIOD    = 2500,
   parameter C_RST_ACT_LOW      = 1,
   parameter C_INPUT_CLK_TYPE   = "DIFFERENTIAL",
   parameter C_CLKOUT0_DIVIDE   = 1,
   parameter C_CLKOUT1_DIVIDE   = 1,
   parameter C_CLKOUT2_DIVIDE   = 16,
   parameter C_CLKOUT3_DIVIDE   = 8,
   parameter C_CLKFBOUT_MULT    = 2,
   parameter C_DIVCLK_DIVIDE    = 1
   
   )
  (
   input  sys_clk_p,
   input  sys_clk_n,
   input  sys_clk,
   input  sys_rst_i,
   output clk0,
   output rst0,
   output async_rst,
   output sysclk_2x,
   output sysclk_2x_180,
   output mcb_drp_clk,
   output pll_ce_0,
   output pll_ce_90,
   output pll_lock

   );

  // # of clock cycles to delay deassertion of reset. Needs to be a fairly
  // high number not so much for metastability protection, but to give time
  // for reset (i.e. stable clock cycles) to propagate through all state
  // machines and to all control signals (i.e. not all control signals have
  // resets, instead they rely on base state logic being reset, and the effect
  // of that reset propagating through the logic). Need this because we may not
  // be getting stable clock cycles while reset asserted (i.e. since reset
  // depends on PLL/DCM lock status)

  localparam RST_SYNC_NUM = 25;
  localparam CLK_PERIOD_NS = C_INCLK_PERIOD / 1000.0;
  localparam CLK_PERIOD_INT = C_INCLK_PERIOD/1000;

  wire                       clk_2x_0;
  wire                       clk_2x_180;
  wire                       clk0_bufg;
  wire                       clk0_bufg_in;
  wire                       mcb_drp_clk_bufg_in;
  wire                       clkfbout_clkfbin;
  wire                       locked;
  reg [RST_SYNC_NUM-1:0]     rst0_sync_r    /* synthesis syn_maxfan = 10 */;
  wire                       rst_tmp;
  reg                        powerup_pll_locked;
  reg 			     syn_clk0_powerup_pll_locked;

  wire                       sys_rst;
  wire                       bufpll_mcb_locked;
  wire sys_clk_ibufg;

  assign sys_rst = C_RST_ACT_LOW ? ~sys_rst_i: sys_rst_i;
  assign clk0        = clk0_bufg;
  assign pll_lock    = bufpll_mcb_locked;

  assign sys_clk_ibufg = sys_clk;

  //***************************************************************************
  // Global clock generation and distribution
  //***************************************************************************

    PLL_ADV #
        (
         .BANDWIDTH          ("OPTIMIZED"),
         .CLKIN1_PERIOD      (CLK_PERIOD_NS),
         .CLKIN2_PERIOD      (CLK_PERIOD_NS),
         .CLKOUT0_DIVIDE     (C_CLKOUT0_DIVIDE),
         .CLKOUT1_DIVIDE     (C_CLKOUT1_DIVIDE),
         .CLKOUT2_DIVIDE     (C_CLKOUT2_DIVIDE),
         .CLKOUT3_DIVIDE     (C_CLKOUT3_DIVIDE),
         .CLKOUT4_DIVIDE     (1),
         .CLKOUT5_DIVIDE     (1),
         .CLKOUT0_PHASE      (0.000),
         .CLKOUT1_PHASE      (180.000),
         .CLKOUT2_PHASE      (0.000),
         .CLKOUT3_PHASE      (0.000),
         .CLKOUT4_PHASE      (0.000),
         .CLKOUT5_PHASE      (0.000),
         .CLKOUT0_DUTY_CYCLE (0.500),
         .CLKOUT1_DUTY_CYCLE (0.500),
         .CLKOUT2_DUTY_CYCLE (0.500),
         .CLKOUT3_DUTY_CYCLE (0.500),
         .CLKOUT4_DUTY_CYCLE (0.500),
         .CLKOUT5_DUTY_CYCLE (0.500),
         .SIM_DEVICE         ("SPARTAN6"),
         .COMPENSATION       ("INTERNAL"),
         .DIVCLK_DIVIDE      (C_DIVCLK_DIVIDE),
         .CLKFBOUT_MULT      (C_CLKFBOUT_MULT),
         .CLKFBOUT_PHASE     (0.0),
         .REF_JITTER         (0.005000)
         )
        u_pll_adv
          (
           .CLKFBIN     (clkfbout_clkfbin),
           .CLKINSEL    (1'b1),
           .CLKIN1      (sys_clk_ibufg),
           .CLKIN2      (1'b0),
           .DADDR       (5'b0),
           .DCLK        (1'b0),
           .DEN         (1'b0),
           .DI          (16'b0),
           .DWE         (1'b0),
           .REL         (1'b0),
           .RST         (sys_rst),
           .CLKFBDCM    (),
           .CLKFBOUT    (clkfbout_clkfbin),
           .CLKOUTDCM0  (),
           .CLKOUTDCM1  (),
           .CLKOUTDCM2  (),
           .CLKOUTDCM3  (),
           .CLKOUTDCM4  (),
           .CLKOUTDCM5  (),
           .CLKOUT0     (clk_2x_0),
           .CLKOUT1     (clk_2x_180),
           .CLKOUT2     (clk0_bufg_in),
           .CLKOUT3     (mcb_drp_clk_bufg_in),
           .CLKOUT4     (),
           .CLKOUT5     (),
           .DO          (),
           .DRDY        (),
           .LOCKED      (locked)
           );

 

   BUFG U_BUFG_CLK0
    (
     .O (clk0_bufg),
     .I (clk0_bufg_in)
     );

   BUFGCE U_BUFG_CLK1
    (
     .O (mcb_drp_clk),
     .I (mcb_drp_clk_bufg_in),
     .CE (locked)
     );

  always @(posedge mcb_drp_clk , posedge sys_rst)
      if(sys_rst)
         powerup_pll_locked <= 1'b0;
       
      else if (bufpll_mcb_locked)
         powerup_pll_locked <= 1'b1;
         

  always @(posedge clk0_bufg , posedge sys_rst)
      if(sys_rst)
         syn_clk0_powerup_pll_locked <= 1'b0;
       
      else if (bufpll_mcb_locked)
         syn_clk0_powerup_pll_locked <= 1'b1;
         

  //***************************************************************************
  // Reset synchronization
  // NOTES:
  //   1. shut down the whole operation if the PLL hasn't yet locked (and
  //      by inference, this means that external SYS_RST_IN has been asserted -
  //      PLL deasserts LOCKED as soon as SYS_RST_IN asserted)
  //   2. asynchronously assert reset. This was we can assert reset even if
  //      there is no clock (needed for things like 3-stating output buffers).
  //      reset deassertion is synchronous.
  //   3. asynchronous reset only look at pll_lock from PLL during power up. After
  //      power up and pll_lock is asserted, the powerup_pll_locked will be asserted
  //      forever until sys_rst is asserted again. PLL will lose lock when FPGA 
  //      enters suspend mode. We don't want reset to MCB get
  //      asserted in the application that needs suspend feature.
  //***************************************************************************


  assign async_rst = sys_rst | ~powerup_pll_locked;
  // synthesis attribute max_fanout of rst0_sync_r is 10
  assign rst_tmp = sys_rst | ~syn_clk0_powerup_pll_locked;

  always @(posedge clk0_bufg or posedge rst_tmp)
    if (rst_tmp)
      rst0_sync_r <= {RST_SYNC_NUM{1'b1}};
    else
      // logical left shift by one (pads with 0)
      rst0_sync_r <= rst0_sync_r << 1;


  assign rst0    = rst0_sync_r[RST_SYNC_NUM-1];


BUFPLL_MCB BUFPLL_MCB1 
( .IOCLK0         (sysclk_2x),  
  .IOCLK1         (sysclk_2x_180),       
  .LOCKED         (locked),
  .GCLK           (mcb_drp_clk),
  .SERDESSTROBE0  (pll_ce_0), 
  .SERDESSTROBE1  (pll_ce_90), 
  .PLLIN0         (clk_2x_0),  
  .PLLIN1         (clk_2x_180),
  .LOCK           (bufpll_mcb_locked) 
  );


endmodule
