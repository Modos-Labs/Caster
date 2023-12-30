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
// degamma.v
// Approximately convert from sRGB color space (gamma = 2.2) to linear space
//
`default_nettype none
`timescale 1ns / 1ps
module degamma(
    input wire [5:0] in,
    output reg [7:0] out
);

    // Should only use 8 LUT6s.
    always @(in) begin
        case (in)
        6'd0: out = 8'd0;
        6'd1: out = 8'd0;
        6'd2: out = 8'd0;
        6'd3: out = 8'd0;
        6'd4: out = 8'd1;
        6'd5: out = 8'd1;
        6'd6: out = 8'd1;
        6'd7: out = 8'd2;
        6'd8: out = 8'd3;
        6'd9: out = 8'd4;
        6'd10: out = 8'd4;
        6'd11: out = 8'd5;
        6'd12: out = 8'd7;
        6'd13: out = 8'd8;
        6'd14: out = 8'd9;
        6'd15: out = 8'd11;
        6'd16: out = 8'd13;
        6'd17: out = 8'd14;
        6'd18: out = 8'd16;
        6'd19: out = 8'd18;
        6'd20: out = 8'd20;
        6'd21: out = 8'd23;
        6'd22: out = 8'd25;
        6'd23: out = 8'd28;
        6'd24: out = 8'd31;
        6'd25: out = 8'd33;
        6'd26: out = 8'd36;
        6'd27: out = 8'd40;
        6'd28: out = 8'd43;
        6'd29: out = 8'd46;
        6'd30: out = 8'd50;
        6'd31: out = 8'd54;
        6'd32: out = 8'd57;
        6'd33: out = 8'd61;
        6'd34: out = 8'd66;
        6'd35: out = 8'd70;
        6'd36: out = 8'd74;
        6'd37: out = 8'd79;
        6'd38: out = 8'd84;
        6'd39: out = 8'd89;
        6'd40: out = 8'd94;
        6'd41: out = 8'd99;
        6'd42: out = 8'd105;
        6'd43: out = 8'd110;
        6'd44: out = 8'd116;
        6'd45: out = 8'd122;
        6'd46: out = 8'd128;
        6'd47: out = 8'd134;
        6'd48: out = 8'd140;
        6'd49: out = 8'd147;
        6'd50: out = 8'd153;
        6'd51: out = 8'd160;
        6'd52: out = 8'd167;
        6'd53: out = 8'd174;
        6'd54: out = 8'd182;
        6'd55: out = 8'd189;
        6'd56: out = 8'd197;
        6'd57: out = 8'd205;
        6'd58: out = 8'd213;
        6'd59: out = 8'd221;
        6'd60: out = 8'd229;
        6'd61: out = 8'd238;
        6'd62: out = 8'd246;
        6'd63: out = 8'd255;
        endcase
    end

endmodule
`default_nettype wire
