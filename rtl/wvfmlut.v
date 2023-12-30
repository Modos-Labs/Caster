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
// wvfmlut.v
// Waveform lookup table SRAM wrapper
`timescale 1ns / 1ps
`default_nettype none
module wvfmlut(
    input wire clk,
    // Write port
    input wire we,
    input wire [11:0] addr,
    input wire [7:0] din,
    // Read port A
    input wire [13:0] addra,
    output reg [1:0] douta,
    // Read port B
    input wire [13:0] addrb,
    output reg [1:0] doutb
);

    wire [7:0] bram_douta;
    wire [7:0] bram_doutb;

    bramdp #(
        .ABITS(12),
        .DBITS(8),
        .INITIALIZE(1),
        .INIT_FILE("default_waveform.mem")
    ) bramdp0 (
        .clka(clk),
        .wea(we),
        .addra(we ? addr : addra[13:2]),
        .dina(din),
        .douta(bram_douta),
        .clkb(clk),
        .web(1'b0),
        .addrb(addrb[13:2]),
        .dinb(8'b0),
        .doutb(bram_doutb)
    );

    assign douta =
        (addra[1:0] == 2'd0) ? bram_douta[1:0] :
        (addra[1:0] == 2'd1) ? bram_douta[3:2] :
        (addra[1:0] == 2'd2) ? bram_douta[5:4] :
        (addra[1:0] == 2'd3) ? bram_douta[7:6] : 2'bx;

    assign doutb =
        (addrb[1:0] == 2'd0) ? bram_doutb[1:0] :
        (addrb[1:0] == 2'd1) ? bram_doutb[3:2] :
        (addrb[1:0] == 2'd2) ? bram_doutb[5:4] :
        (addrb[1:0] == 2'd3) ? bram_doutb[7:6] : 2'bx;

endmodule
`default_nettype wire
