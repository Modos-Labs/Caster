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
`default_nettype none
`timescale 1ns / 1ps
module clamp_signed #(
    parameter INPUT_BITS = 11,
    parameter OUTPUT_BITS = 9
) (
    input wire [INPUT_BITS-1:0] in,
    output wire [OUTPUT_BITS-1:0] out
);

    localparam BIT_DIFF = INPUT_BITS - OUTPUT_BITS;

    wire underflow = in[INPUT_BITS-1] &&
            (in[INPUT_BITS-2:OUTPUT_BITS-1] != {BIT_DIFF{1'b1}});
    wire overflow = !in[INPUT_BITS-1] &&
            (in[INPUT_BITS-2:OUTPUT_BITS-1] != {BIT_DIFF{1'b0}});

    assign out =
        underflow ? {1'b1, {(OUTPUT_BITS-1){1'b0}}} :
        overflow ? {1'b0, {(OUTPUT_BITS-1){1'b1}}} :
        {in[INPUT_BITS-1], in[OUTPUT_BITS-2:0]};

endmodule
`default_nettype wire
