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
// adder_sat.v
// Saturation adder, used in ordered dithering
`timescale 1ns / 1ps
`default_nettype none
module adder_sat(
    input wire [4:0] a, // unsigned
    input wire [3:0] b, // signed
    output wire [3:0] c // unsigned
);

    //wire [4:0] a_ext = {1'b0, a};
    wire [4:0] a_ext = a;
    wire [4:0] b_ext = {b[3], b};
    wire [4:0] add = a_ext + b_ext;
    assign c = add[4] ? (b[3] ? (4'h0) : (4'hF)) : (add[3:0]);

endmodule
`default_nettype wire
