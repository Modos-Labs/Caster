`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting
// 
// Create Date:    10:05:23 06/13/2022 
// Design Name:    caster
// Module Name:    adder_sat
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
module adder_sat(
    input wire [3:0] a, // unsigned
    input wire [3:0] b, // signed
    output wire [3:0] c // unsigned
);

    wire [4:0] a_ext = {1'b0, a};
    wire [4:0] b_ext = {b[3], b};
    wire [4:0] add = a_ext + b_ext;
    assign c = add[4] ? (b[3] ? (4'h0) : (4'hF)) : (add[3:0]);

endmodule
