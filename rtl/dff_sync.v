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
// dff_sync.v
// Generic DFF chain synchronizer
`timescale 1ns / 1ps
module dff_sync(
    input wire i,
    input wire clko,
    output wire o
    );

    reg sync_dff_1, sync_dff_2;
    always @(posedge clko) begin
        sync_dff_1 <= i;
        sync_dff_2 <= sync_dff_1;
    end
    assign o = sync_dff_2;;

endmodule
