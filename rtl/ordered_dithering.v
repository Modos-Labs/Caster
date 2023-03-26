`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting
// 
// Create Date:    21:53:53 06/13/2022 
// Design Name:    caster
// Module Name:    ordered_dithering 
// Project Name: 
// Target Devices: generic
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ordered_dithering (
    input wire        clk,
    input wire        rst,
    input wire [31:0] vin,
    output reg [15:0] vout,
    input wire [2:0]  x_pos,
    input wire [2:0]  y_pos
);
    parameter COLORMODE = "DES";

    wire [15:0] vo_ordered;
    wire [3:0] b0, b1, b2, b3;

    generate
    if (COLORMODE == "MONO") begin
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
    else if (COLORMODE == "DES") begin
        assign b0 =
            (y_pos[2:0] == 3'd0) ? ((x_pos[1:0] == 3'd0) ? (4'd4) : (x_pos[1:0] == 3'd1) ? (4'd3) : (4'd7)) :
            (y_pos[2:0] == 3'd1) ? ((x_pos[1:0] == 3'd0) ? (4'd0) : (x_pos[1:0] == 3'd1) ? (4'd7) : (-4'd4)) :
            (y_pos[2:0] == 3'd2) ? ((x_pos[1:0] == 3'd0) ? (-4'd6) : (x_pos[1:0] == 3'd1) ? (4'd4) : (-4'd2)) :
            (y_pos[2:0] == 3'd3) ? ((x_pos[1:0] == 3'd0) ? (-4'd3) : (x_pos[1:0] == 3'd1) ? (4'd4) : (4'd0)) :
            (y_pos[2:0] == 3'd4) ? ((x_pos[1:0] == 3'd0) ? (-4'd4) : (x_pos[1:0] == 3'd1) ? (-4'd4) : (4'd5)) :
                                ((x_pos[1:0] == 3'd0) ? (-4'd7) : (x_pos[1:0] == 3'd1) ? (4'd1) : (-4'd6));
        assign b1 =
            (y_pos[2:0] == 3'd0) ? ((x_pos[1:0] == 3'd0) ? (4'd7) : (x_pos[1:0] == 3'd1) ? (-4'd3) : (4'd5)) :
            (y_pos[2:0] == 3'd1) ? ((x_pos[1:0] == 3'd0) ? (4'd3) : (x_pos[1:0] == 3'd1) ? (-4'd2) : (4'd5)) :
            (y_pos[2:0] == 3'd2) ? ((x_pos[1:0] == 3'd0) ? (-4'd6) : (x_pos[1:0] == 3'd1) ? (4'd0) : (4'd1)) :
            (y_pos[2:0] == 3'd3) ? ((x_pos[1:0] == 3'd0) ? (4'd0) : (x_pos[1:0] == 3'd1) ? (4'd3) : (4'd1)) :
            (y_pos[2:0] == 3'd4) ? ((x_pos[1:0] == 3'd0) ? (4'd0) : (x_pos[1:0] == 3'd1) ? (4'd0) : (-4'd7)) :
                                ((x_pos[1:0] == 3'd0) ? (-4'd2) : (x_pos[1:0] == 3'd1) ? (-4'd7) : (-4'd3));
        assign b2 =
            (y_pos[2:0] == 3'd0) ? ((x_pos[1:0] == 3'd0) ? (4'd7) : (x_pos[1:0] == 3'd1) ? (4'd4) : (4'd3)) :
            (y_pos[2:0] == 3'd1) ? ((x_pos[1:0] == 3'd0) ? (-4'd4) : (x_pos[1:0] == 3'd1) ? (4'd0) : (4'd7)) :
            (y_pos[2:0] == 3'd2) ? ((x_pos[1:0] == 3'd0) ? (-4'd2) : (x_pos[1:0] == 3'd1) ? (-4'd6) : (4'd4)) :
            (y_pos[2:0] == 3'd3) ? ((x_pos[1:0] == 3'd0) ? (4'd0) : (x_pos[1:0] == 3'd1) ? (-4'd3) : (4'd4)) :
            (y_pos[2:0] == 3'd4) ? ((x_pos[1:0] == 3'd0) ? (4'd5) : (x_pos[1:0] == 3'd1) ? (-4'd4) : (-4'd4)) :
                                ((x_pos[1:0] == 3'd0) ? (-4'd6) : (x_pos[1:0] == 3'd1) ? (-4'd7) : (4'd1));
        assign b3 =
            (y_pos[2:0] == 3'd0) ? ((x_pos[1:0] == 3'd0) ? (4'd5) : (x_pos[1:0] == 3'd1) ? (4'd7) : (-4'd3)) :
            (y_pos[2:0] == 3'd1) ? ((x_pos[1:0] == 3'd0) ? (4'd5) : (x_pos[1:0] == 3'd1) ? (4'd3) : (-4'd2)) :
            (y_pos[2:0] == 3'd2) ? ((x_pos[1:0] == 3'd0) ? (4'd1) : (x_pos[1:0] == 3'd1) ? (-4'd6) : (4'd0)) :
            (y_pos[2:0] == 3'd3) ? ((x_pos[1:0] == 3'd0) ? (4'd1) : (x_pos[1:0] == 3'd1) ? (4'd0) : (4'd3)) :
            (y_pos[2:0] == 3'd4) ? ((x_pos[1:0] == 3'd0) ? (-4'd7) : (x_pos[1:0] == 3'd1) ? (4'd0) : (4'd0)) :
                                ((x_pos[1:0] == 3'd0) ? (-4'd3) : (x_pos[1:0] == 3'd1) ? (-4'd2) : (-4'd7));
    end
    endgenerate
    wire [3:0] c0, c1, c2, c3;

    localparam BIAS = 9'd10;
    wire [8:0] a0 = {1'b0, vin[31:24]} + BIAS;
    wire [8:0] a1 = {1'b0, vin[23:16]} + BIAS;
    wire [8:0] a2 = {1'b0, vin[15:8]} + BIAS;
    wire [8:0] a3 = {1'b0, vin[7:0]} + BIAS;

    adder_sat adder_sat0 (a0[8:4], b0, c0);
    adder_sat adder_sat1 (a1[8:4], b1, c1);
    adder_sat adder_sat2 (a2[8:4], b2, c2);
    adder_sat adder_sat3 (a3[8:4], b3, c3);
    assign vo_ordered = {c0, c1, c2, c3};

    always @(posedge clk) begin
        vout <= vo_ordered;
    end

endmodule
`default_nettype wire
