// Copyright Modos / Wenting Zhang 2023
//
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2
//
// You may redistribute and modify this documentation and make products using
// it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl). This
// documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
// INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A
// PARTICULAR PURPOSE. Please see the CERN-OHL-P v2 for applicable conditions
//
// rgb2y.v
// RGB value to luminance
`timescale 1ns / 1ps
`default_nettype none
module rgb2y(
    input wire [5:0] r,
    input wire [5:0] g,
    input wire [5:0] b,
    output wire [5:0] y
    );

    // Pretty much overkill.
    // Could just use simple shifter to save some DSP blocks.
    wire [13:0] r_mult = {8'd0, r} * 14'd77;
    wire [13:0] g_mult = {8'd0, g} * 14'd150;
    wire [13:0] b_mult = {8'd0, b} * 14'd29;

    wire [13:0] acc = r_mult + g_mult + b_mult;

    assign y = acc[13:8];

endmodule
`default_nettype wire
