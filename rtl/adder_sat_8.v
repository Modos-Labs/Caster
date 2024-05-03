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
// adder_sat_8.v
// Saturation adder, used in blue noise dithering
`timescale 1ns / 1ps
`default_nettype none
module adder_sat_8(
    input wire [7:0] a, // unsigned
    input wire [7:0] b, // signed
    output wire [7:0] c // unsigned
);

    wire [8:0] a_ext = {1'b0, a};
    wire [8:0] b_ext = {b[7], b};
    wire [8:0] add = a_ext + b_ext;
    assign c = add[8] ? (b[7] ? (8'h00) : (8'hFF)) : (add[7:0]);

endmodule
`default_nettype wire
