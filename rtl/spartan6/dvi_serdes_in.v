// dvi_serdes_in.v
// DVI 1:10 TMDS deserializer based on XAPP495.
// This file is not covered under CERN-OHL-P.

// Original Author: Bob Feng
// Disclaimer:
// LIMITED WARRANTY AND DISCLAMER. These designs are
// provided to you "as is". Xilinx and its licensors makeand you
// receive no warranties or conditions, express, implied,
// statutory or otherwise, and Xilinx specificallydisclaims any
// implied warranties of merchantability, non-infringement,or
// fitness for a particular purpose. Xilinx does notwarrant that
// the functions contained in these designs will meet your
// requirements, or that the operation of these designswill be
// uninterrupted or error free, or that defects in theDesigns
// will be corrected. Furthermore, Xilinx does not warrantor
// make any representations regarding use or the results ofthe
// use of the designs in terms of correctness, accuracy,
// reliability, or otherwise.
//
// LIMITATION OF LIABILITY. In no event will Xilinx or its
// licensors be liable for any loss of data, lost profits,cost
// or procurement of substitute goods or services, or forany
// special, incidental, consequential, or indirect damages
// arising from the use or operation of the designs or
// accompanying documentation, however caused and on anytheory
// of liability. This limitation will apply even if Xilinx
// has been advised of the possibility of such damage. This
// limitation shall apply not-withstanding the failure ofthe
// essential purpose of any limited remedies herein.
//
// Copyright 2004 Xilinx, Inc.
// All rights reserved

`timescale 1ns / 1ps
`default_nettype none
module dvi_serdes_in(
    input  wire         rstin,
    output wire         rst,
    input  wire         dvi_cp,
    input  wire         dvi_cn,
    input  wire [2:0]   dvi_dp,
    input  wire [2:0]   dvi_dn,
    output wire         pclk,
    output wire         hsync,
    output wire         vsync,
    output wire         de,
    output wire [7:0]   red,
    output wire [7:0]   green,
    output wire [7:0]   blue,
    output wire         psalgnerr,
    output wire         dbg_pll_lck
);

    `define DVI_REVERSE_POL // Input signal has reversed polarity

    // Send TMDS clock to a differential buffer and then a BUFIO2
    // This is a required path in Spartan-6 feed a PLL CLKIN
    wire rxclkint;
    
    `ifdef DVI_REVERSE_POL
    IBUFDS_DIFF_OUT #(
        .IOSTANDARD("TMDS_33"),
        .DIFF_TERM("FALSE")
    ) ibuf_rxclk (
        .I(dvi_cn),
        .IB(dvi_cp),
        .O(),
        .OB(rxclkint)
    );
    `else
    IBUFDS #(
        .IOSTANDARD("TMDS_33"),
        .DIFF_TERM("FALSE")
    ) ibuf_rxclk (
        .I(dvi_cp),
        .IB(dvi_cn),
        .O(rxclkint)
    );
    `endif
    
    wire rxclk;
    BUFIO2 #(
        .DIVIDE_BYPASS("TRUE"),
        .DIVIDE(1)
    ) bufio_tmdsclk (
        .DIVCLK(rxclk),
        .IOCLK(),
        .SERDESSTROBE(),
        .I(rxclkint)
    );

    //wire tmdsclk;
    //BUFG tmdsclk_bufg (.I(rxclk), .O(tmdsclk));

    // PLL is used to generate three clocks:
    // 1. pclk:    same rate as TMDS clock
    // 2. pclkx2:  double rate of pclk used for 5:10 soft gear box and ISERDES DIVCLK
    // 3. pclkx10: 10x rate of pclk used as IO clock
    wire clkfbout, pllclk0, pllclk1, pllclk2, pll_lckd;
    PLL_BASE # (
        .CLKIN_PERIOD(10),
        .CLKFBOUT_MULT(10), //set VCO to 10x of CLKIN
        .CLKOUT0_DIVIDE(1),
        .CLKOUT1_DIVIDE(10),
        .CLKOUT2_DIVIDE(5),
        .COMPENSATION("INTERNAL")
    ) PLL_ISERDES (
        .CLKFBOUT(clkfbout),
        .CLKOUT0(pllclk0),
        .CLKOUT1(pllclk1),
        .CLKOUT2(pllclk2),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .LOCKED(pll_lckd),
        .CLKFBIN(clkfbout),
        .CLKIN(rxclk),
        .RST(rstin)
    );

    // Pixel Rate clock buffer
    BUFG pclkbufg (.I(pllclk1), .O(pclk));
    
    assign dbg_pll_lck = pll_lckd;

    // 2x pclk is going to be used to drive IOSERDES2 DIVCLK
    wire pclkx2;
    BUFG pclkx2bufg (.I(pllclk2), .O(pclkx2));

    // 10x pclk is used to drive IOCLK network so a bit rate reference
    // can be used by IOSERDES2
    wire bufpll_locked;
    wire pclkx10;
    wire serdesstrobe;
    BUFPLL #(.DIVIDE(5)) ioclk_buf (
        .PLLIN(pllclk0),
        .GCLK(pclkx2),
        .LOCKED(pll_lckd),
        .IOCLK(pclkx10),
        .SERDESSTROBE(serdesstrobe),
        .LOCK(bufpll_locked)
    );

    assign rst = ~bufpll_locked;

    wire blue_rdy, green_rdy, red_rdy;
    wire blue_vld, green_vld, red_vld;
    wire blue_psalgnerr, green_psalgnerr, red_psalgnerr;
    wire de_b, de_g, de_r;
    wire [9:0] sdout_blue, sdout_green, sdout_red;
    dvi_serdes_datain dvi_din_b (
        .reset        (rst),
        .pclk         (pclk),
        .pclkx2       (pclkx2),
        .pclkx10      (pclkx10),
        .serdesstrobe (serdesstrobe),
        .din_p        (dvi_dp[0]),
        .din_n        (dvi_dn[0]),
        .other_ch0_rdy(green_rdy),
        .other_ch1_rdy(red_rdy),
        .other_ch0_vld(green_vld),
        .other_ch1_vld(red_vld),

        .iamvld       (blue_vld),
        .iamrdy       (blue_rdy),
        .psalgnerr    (blue_psalgnerr),
        .c0           (hsync),
        .c1           (vsync),
        .de           (de_b),
        .sdout        (sdout_blue),
        .dout         (blue)
    );

    dvi_serdes_datain dvi_din_g (
        .reset        (rst),
        .pclk         (pclk),
        .pclkx2       (pclkx2),
        .pclkx10      (pclkx10),
        .serdesstrobe (serdesstrobe),
        .din_p        (dvi_dp[1]),
        .din_n        (dvi_dn[1]),
        .other_ch0_rdy(blue_rdy),
        .other_ch1_rdy(red_rdy),
        .other_ch0_vld(blue_vld),
        .other_ch1_vld(red_vld),

        .iamvld       (green_vld),
        .iamrdy       (green_rdy),
        .psalgnerr    (green_psalgnerr),
        .c0           (),
        .c1           (),
        .de           (de_g),
        .sdout        (sdout_green),
        .dout         (green)
    );

    dvi_serdes_datain dvi_din_r (
        .reset        (rst),
        .pclk         (pclk),
        .pclkx2       (pclkx2),
        .pclkx10      (pclkx10),
        .serdesstrobe (serdesstrobe),
        .din_p        (dvi_dp[2]),
        .din_n        (dvi_dn[2]),
        .other_ch0_rdy(blue_rdy),
        .other_ch1_rdy(green_rdy),
        .other_ch0_vld(blue_vld),
        .other_ch1_vld(green_vld),

        .iamvld       (red_vld),
        .iamrdy       (red_rdy),
        .psalgnerr    (red_psalgnerr),
        .c0           (),
        .c1           (),
        .de           (de_r),
        .sdout        (sdout_red),
        .dout         (red)
    );

    assign de = de_b;
    assign psalgnerr = red_psalgnerr | blue_psalgnerr | green_psalgnerr;

endmodule
`default_nettype wire