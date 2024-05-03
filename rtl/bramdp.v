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
// bramdp.v
// Generic dual port RAM, could be replaced with device specific implementation.
`timescale 1ns / 1ps
`default_nettype none
module bramdp #(
    parameter ABITS = 12,
    parameter DBITS = 8,
    parameter INITIALIZE = 0,
    parameter INIT_FILE = ""
) (
    input wire clka,
    input wire wea,
    input wire [ABITS-1:0] addra,
    input wire [DBITS-1:0] dina,
    output reg [DBITS-1:0] douta,
    input wire clkb,
    input wire web,
    input wire [ABITS-1:0] addrb,
    input wire [DBITS-1:0] dinb,
    output reg [DBITS-1:0] doutb
);

    localparam DEPTH = 1 << ABITS;
    reg [DBITS-1:0] mem [0:DEPTH-1];

    always @(posedge clka) begin
        if (wea)
            mem[addra] <= dina;
        else
            douta <= mem[addra];
    end

    always @(posedge clkb) begin
        if (web)
            mem[addrb] <= dinb;
        else
            doutb <= mem[addrb];
    end

    generate
        if (INITIALIZE == 1) begin: gen_bram_init
            initial begin
                $readmemh(INIT_FILE, mem);
            end
        end
    endgenerate

endmodule
