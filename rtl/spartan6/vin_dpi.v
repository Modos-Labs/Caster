// Copyright Wenting Zhang 2024
//
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2
//
// You may redistribute and modify this documentation and make products using
// it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl). This
// documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
// INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A
// PARTICULAR PURPOSE. Please see the CERN-OHL-P v2 for applicable conditions
//
// vin_dpi.v
// DPI video input
// This module down converts the input pixel rate by 2
`timescale 1ns / 1ps
`default_nettype none
module vin_dpi(
    input  wire         rst,
    input  wire         dpi_vsync,
    input  wire         dpi_hsync,
    input  wire         dpi_pclk,
    input  wire         dpi_de,
    input  wire [17:0]  dpi_pixel,
    output reg          v_vsync,
    output reg          v_hsync,
    output wire         v_pclk,
    output reg          v_de,
    output reg  [35:0]  v_pixel,
    output wire         v_halfpclk,
    output wire         v_valid
);

    wire locked_int;
    wire [7:0] status_int;
    wire clk0_buf;
    wire clk0;
    wire clk180_buf;
    wire clk180;
    wire clkfx;
    wire dpi_pclk_buf;
    IBUFG pclkin_buf (
        .O (dpi_pclk_buf),
        .I (dpi_pclk)
    );

    DCM_SP #(
        .CLKDV_DIVIDE          (2.000),
        .CLKFX_DIVIDE          (4),
        .CLKFX_MULTIPLY        (2),
        .CLKIN_DIVIDE_BY_2     ("FALSE"),
        .CLKIN_PERIOD          (6.0), // 166MHz max
        .CLKOUT_PHASE_SHIFT    ("NONE"),
        .CLK_FEEDBACK          ("1X"),
        .DESKEW_ADJUST         ("SYSTEM_SYNCHRONOUS"),
        .PHASE_SHIFT           (0),
        .STARTUP_WAIT          ("FALSE")
    )
    dcm_sp_inst (
        // Input clock
        .CLKIN                 (dpi_pclk_buf),
        .CLKFB                 (clk0_buf),
        // Output clocks
        .CLK0                  (clk0),
        .CLK90                 (),
        .CLK180                (clk180),
        .CLK270                (),
        .CLK2X                 (),
        .CLK2X180              (),
        .CLKFX                 (clkfx),
        .CLKFX180              (),
        .CLKDV                 (),
        // Ports for dynamic phase shift
        .PSCLK                 (1'b0),
        .PSEN                  (1'b0),
        .PSINCDEC              (1'b0),
        .PSDONE                (),
        // Other control and status signals
        .LOCKED                (locked_int),
        .STATUS                (status_int),

        .RST                   (rst),
        // Unused pin- tie low
        .DSSEN                 (1'b0)
    );

    BUFG clk0_bufg (
        .O (clk0_buf),
        .I (clk0)
    );
    
    BUFG clk180_bufg (
        .O(clk180_buf),
        .I(clk180)
    );

    wire vi_rst = !locked_int;
    assign v_valid = locked_int;

    wire [20:0] insig = {dpi_hsync, dpi_vsync, dpi_de, dpi_pixel};
    wire [20:0] outsig_r;
    wire [20:0] outsig_f;
    genvar i;
    generate for (i = 0; i < 21; i = i + 1) begin
        IDDR2 #(
            .DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
            .INIT_Q0(1'b0), // Sets initial state of the Q0 output to 1'b0 or 1'b1
            .INIT_Q1(1'b0), // Sets initial state of the Q1 output to 1'b0 or 1'b1
            .SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
        ) iddr2_hsync (
            .Q0(outsig_r[i]), // 1-bit output captured with C0 clock
            .Q1(outsig_f[i]), // 1-bit output captured with C1 clock
            .C0(clk0_buf), // 1-bit clock input
            .C1(clk180_buf), // 1-bit clock input
            .CE(1'b1), // 1-bit clock enable input
            .D(insig[i]),   // 1-bit DDR data input
            .R(1'b0),   // 1-bit reset input
            .S(1'b0)    // 1-bit set input
        );
    end
    endgenerate
    
    wire bhsync = outsig_r[20];
    wire bvsync = outsig_r[19];
    wire bde = outsig_r[18];
    //wire [17:0] bpixelin = outsig[17:0];
    wire [17:0] bpixelin_r = outsig_r[17:0];
    wire [17:0] bpixelin_f = outsig_f[17:0];

    always @(posedge clk0_buf) begin
        v_hsync <= bhsync;
        v_vsync <= bvsync;
        v_de <= bde;
        v_pixel <= {bpixelin_f, bpixelin_r};
    end
    
    assign v_pclk = clk0;

    // The user should buffer the clock with BUFG / BUFGMUX
    assign v_halfpclk = clkfx;

endmodule
`default_nettype wire
