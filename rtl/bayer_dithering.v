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
// bayer_dithering.v
// Bayer dithering implementation, 1 cycle latency
`timescale 1ns / 1ps
`default_nettype none
module bayer_dithering (
    input wire        clk,
    input wire [31:0] vin,
    output reg [3:0]  vout,
    /* verilator lint_off UNUSEDSIGNAL */
    // Not all bits used in MONO mode
    input wire [2:0]  x_pos,
    input wire [2:0]  y_pos
    /* verilator lint_on UNUSEDSIGNAL */
);
    parameter COLORMODE = "DES";

    wire [3:0] vo_ordered;
    wire [3:0] b0, b1, b2, b3;

    generate
    if (COLORMODE == "MONO") begin: gen_mono_dither
        assign b0 =
            (y_pos[1:0] == 2'b00) ? (-4'd8) :
            (y_pos[1:0] == 2'b01) ? (4'd4) :
            (y_pos[1:0] == 2'b10) ? (-4'd5) :
                                    (4'd7);
        assign b1 =
            (y_pos[1:0] == 2'b00) ? (4'd0) :
            (y_pos[1:0] == 2'b01) ? (-4'd4) :
            (y_pos[1:0] == 2'b10) ? (4'd3) :
                                    (-4'd1);
        assign b2 =
            (y_pos[1:0] == 2'b00) ? (-4'd6) :
            (y_pos[1:0] == 2'b01) ? (4'd6) :
            (y_pos[1:0] == 2'b10) ? (-4'd7) :
                                    (4'd5);
        assign b3 =
            (y_pos[1:0] == 2'b00) ? (4'd2) :
            (y_pos[1:0] == 2'b01) ? (-4'd2) :
            (y_pos[1:0] == 2'b10) ? (4'd1) :
                                    (-4'd3);
    end
    else if (COLORMODE == "DES") begin: gen_des_dither
        assign b0 =
            (y_pos[2:0] == 3'd0) ? ((x_pos[1:0] == 3'd0) ? (-4'd7) : (x_pos[1:0] == 3'd1) ? ( 4'd7) : ( 4'd0)) :
            (y_pos[2:0] == 3'd1) ? ((x_pos[1:0] == 3'd0) ? (-4'd7) : (x_pos[1:0] == 3'd1) ? ( 4'd0) : ( 4'd0)) :
                                   ((x_pos[1:0] == 3'd0) ? (-4'd7) : (x_pos[1:0] == 3'd1) ? ( 4'd7) : ( 4'd7));
        assign b1 =
            (y_pos[2:0] == 3'd0) ? ((x_pos[1:0] == 3'd0) ? ( 4'd7) : (x_pos[1:0] == 3'd1) ? ( 4'd0) : (-4'd7)) :
            (y_pos[2:0] == 3'd1) ? ((x_pos[1:0] == 3'd0) ? ( 4'd0) : (x_pos[1:0] == 3'd1) ? ( 4'd0) : (-4'd7)) :
                                   ((x_pos[1:0] == 3'd0) ? ( 4'd7) : (x_pos[1:0] == 3'd1) ? ( 4'd7) : (-4'd7));
        assign b2 =
            (y_pos[2:0] == 3'd0) ? ((x_pos[1:0] == 3'd0) ? ( 4'd0) : (x_pos[1:0] == 3'd1) ? (-4'd7) : ( 4'd7)) :
            (y_pos[2:0] == 3'd1) ? ((x_pos[1:0] == 3'd0) ? ( 4'd0) : (x_pos[1:0] == 3'd1) ? (-4'd7) : ( 4'd0)) :
                                   ((x_pos[1:0] == 3'd0) ? ( 4'd7) : (x_pos[1:0] == 3'd1) ? (-4'd7) : ( 4'd7));
        assign b3 =
            (y_pos[2:0] == 3'd0) ? ((x_pos[1:0] == 3'd0) ? (-4'd7) : (x_pos[1:0] == 3'd1) ? ( 4'd7) : ( 4'd0)) :
            (y_pos[2:0] == 3'd1) ? ((x_pos[1:0] == 3'd0) ? (-4'd7) : (x_pos[1:0] == 3'd1) ? ( 4'd0) : ( 4'd0)) :
                                   ((x_pos[1:0] == 3'd0) ? (-4'd7) : (x_pos[1:0] == 3'd1) ? ( 4'd7) : ( 4'd7));
    end
    else if (COLORMODE == "RGBW") begin: gen_rgbw_dither
        assign b0 =
            (x_pos[0] == 1'b0) ? (
                (y_pos[2:1] == 2'b00) ? (-4'd8) :
                (y_pos[2:1] == 2'b01) ? (4'd4) :
                (y_pos[2:1] == 2'b10) ? (-4'd5) :
                                        (4'd7)) :
                ((y_pos[2:1] == 2'b00) ? (-4'd6) :
                (y_pos[2:1] == 2'b01) ? (4'd6) :
                (y_pos[2:1] == 2'b10) ? (-4'd7) :
                                        (4'd5));
        assign b2 =
            (x_pos[0] == 1'b0) ? (
                (y_pos[2:1] == 2'b00) ? (4'd0) :
                (y_pos[2:1] == 2'b01) ? (-4'd4) :
                (y_pos[2:1] == 2'b10) ? (4'd3) :
                                        (-4'd1)) :
                ((y_pos[2:1] == 2'b00) ? (4'd2) :
                (y_pos[2:1] == 2'b01) ? (-4'd2) :
                (y_pos[2:1] == 2'b10) ? (4'd1) :
                                        (-4'd3));
        assign b1 = b0;
        assign b3 = b2;
    end
    endgenerate

    localparam BIAS = 9'd10;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [3:0] c0, c1, c2, c3;
    wire [8:0] a0 = {1'b0, vin[31:24]} + BIAS;
    wire [8:0] a1 = {1'b0, vin[23:16]} + BIAS;
    wire [8:0] a2 = {1'b0, vin[15:8]} + BIAS;
    wire [8:0] a3 = {1'b0, vin[7:0]} + BIAS;
    /* verilator lint_on UNUSEDSIGNAL */

    adder_sat adder_sat0 (a0[8:4], b0, c0);
    adder_sat adder_sat1 (a1[8:4], b1, c1);
    adder_sat adder_sat2 (a2[8:4], b2, c2);
    adder_sat adder_sat3 (a3[8:4], b3, c3);
    assign vo_ordered = {c0[3], c1[3], c2[3], c3[3]};

    always @(posedge clk) begin
        vout <= vo_ordered;
    end

endmodule
`default_nettype wire
