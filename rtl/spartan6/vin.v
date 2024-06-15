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
// vin.v
// Board-level video input
// This module selects an active video input source and buffers the video
`timescale 1ns / 1ps
`default_nettype none
module vin(
    input  wire         rst,
    // DPI signals
    input  wire         dpi_vsync,
    input  wire         dpi_hsync,
    input  wire         dpi_pclk,
    input  wire         dpi_de,
    input  wire [23:0]  dpi_pixel,
    // FPD-Link signals
    input  wire         fpdlink_cp,
    input  wire         fpdlink_cn,
    input  wire [2:0]   fpdlink_odd_p,
    input  wire [2:0]   fpdlink_odd_n,
    input  wire [2:0]   fpdlink_even_p,
    input  wire [2:0]   fpdlink_even_n,
    // Output
    output wire         v_vsync,
    output wire         v_pclk,
    output wire [31:0]  v_pixel, // 4 pixels per clock, Y8
    output wire         v_valid,
    input  wire         v_ready,
    output wire [7:0]   debug
);

    wire v_fpdlink_vsync;
    wire v_fpdlink_hsync;
    wire v_fpdlink_pclk;
    wire v_fpdlink_de;
    wire [47:0] v_fpdlink_pixel;
    wire v_fpdlink_halfpclk;
    wire v_fpdlink_valid;

    vin_fpdlink #(
        .LANES(6),
        .CLK_INVERT(1'b1),
        .CH_INVERT(6'b011011)
    ) vin_fpdlink (
        .rst(rst),
        .fpdlink_cp(fpdlink_cp),
        .fpdlink_cn(fpdlink_cn),
        .fpdlink_odd_p(fpdlink_odd_p),
        .fpdlink_odd_n(fpdlink_odd_n),
        .fpdlink_even_p(fpdlink_even_p),
        .fpdlink_even_n(fpdlink_even_n),
        .v_vsync(v_fpdlink_vsync),
        .v_hsync(v_fpdlink_hsync),
        .v_pclk(v_fpdlink_pclk),
        .v_de(v_fpdlink_de),
        .v_pixel(v_fpdlink_pixel),
        .v_halfpclk(v_fpdlink_halfpclk),
        .v_valid(v_fpdlink_valid)
    );

    wire v_dpi_vsync;
    wire v_dpi_hsync;
    wire v_dpi_pclk;
    wire v_dpi_de;
    wire [47:0] v_dpi_pixel;
    wire v_dpi_halfpclk;
    wire v_dpi_valid;

    vin_dpi vin_dpi (
        .rst(rst),
        .dpi_vsync(dpi_vsync),
        .dpi_hsync(dpi_hsync),
        .dpi_pclk(dpi_pclk),
        .dpi_de(dpi_de),
        .dpi_pixel(dpi_pixel),
        .v_vsync(v_dpi_vsync),
        .v_hsync(v_dpi_hsync),
        .v_pclk(v_dpi_pclk),
        .v_de(v_dpi_de),
        .v_pixel(v_dpi_pixel),
        .v_halfpclk(v_dpi_halfpclk),
        .v_valid(v_dpi_valid)
    );
    
    assign debug[7:6] = dpi_pixel[23:22];
    assign debug[5:4] = v_dpi_pixel[47:46];

    // Mux between 2 inputs into the 1:2 FIFO
    // Prioritize FPD Link Input
    //wire vi_select = v_fpdlink_valid;
    wire vi_select = v_fpdlink_valid; // Always use FPD Link
    wire vi_vsync = vi_select ? v_fpdlink_vsync : v_dpi_vsync;
    wire vi_hsync = vi_select ? v_fpdlink_hsync : v_dpi_hsync; // HSYNC not used
    wire vi_de = vi_select ? v_fpdlink_de : v_dpi_de;
    wire [47:0] vi_pixel_rgb = vi_select ? v_fpdlink_pixel : v_dpi_pixel;
    wire fifo_full;
    wire fifo_empty;

    // Input clock mux
    wire vi_pclk;
    BUFGMUX iclk_mux (
        .S(vi_select),
        .I0(v_dpi_pclk),
        .I1(v_fpdlink_pclk),
        .O(vi_pclk)
    );
    //assign vi_pclk = v_fpdlink_pclk;

    // Input color mixer
    wire [15:0] vi_pixel;
    wire vi_wr_en;
    vin_colormixer vin_colormixer (
        .clk(vi_pclk),
        .in_vsync(vi_vsync),
        .in_hsync(vi_hsync),
        .in_color(vi_pixel_rgb),
        .in_valid(vi_de),
        .out_color(vi_pixel),
        .out_valid(vi_wr_en)
    );
    
    assign debug[3:2] = vi_pixel_rgb[47:46];
    assign debug[1:0] = vi_pixel[15:14];

    // Output clock mux
    BUFGMUX oclk_mux (
        .S(vi_select),
        .I0(v_dpi_halfpclk),
        .I1(v_fpdlink_halfpclk),
        .O(v_pclk)
    );
    /*BUFG oclk_bufg (
        .I(v_fpdlink_halfpclk),
        .O(v_pclk)
    );*/
    
    vi_fifo vi_fifo (
        .rst(v_vsync), // input rst, reset at each frame
        // Write port
        .wr_clk(vi_pclk), // input wr_clk
        .din(vi_pixel), // input [7 : 0] din
        .wr_en(vi_wr_en), // input wr_en
        .full(fifo_full), // output full, error
        // Read port
        .rd_clk(v_pclk), // input rd_clk
        .rd_en(v_ready), // input rd_en
        .dout(v_pixel), // output [15 : 0] dout
        .empty(fifo_empty) // output empty
    );

    assign v_valid = !fifo_empty;

    // Sync vs signal to clk_sys clock domain
    dff_sync vs_sync (
        .i(vi_vsync),
        .clko(v_pclk),
        .o(v_vsync)
    );

endmodule
