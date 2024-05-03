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
// clk_div.v
// Basic clock divider
`timescale 1ns / 1ps
`default_nettype wire
module clk_div(
    input i,
    output reg o = 0
    );

    parameter WIDTH = 15, DIV = 1000;
    
    reg [WIDTH - 1:0] counter = 0;
    
    always @(posedge i)
    begin
        if (counter == (DIV / 2 - 1)) begin
            o <= ~o;
            counter <= 0;
        end
        else
            counter <= counter + 1'b1;
    end
endmodule
