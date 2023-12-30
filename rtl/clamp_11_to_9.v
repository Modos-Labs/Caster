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
module clamp_11_to_9(
    input wire [10:0] in,
    output wire [8:0] out
);

    assign out =
        (in[10] && (in[9:8] != 2'b11)) ? 9'b100000000 : // underflow
        (!in[10] && (in[9:8] != 2'b00)) ? 9'b011111111 : // overflow
        {in[10], in[7:0]};

endmodule
`default_nettype wire
