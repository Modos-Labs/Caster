`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:01:05 06/07/2022 
// Design Name: 
// Module Name:    rgb2y 
// Project Name: 
// Target Devices: 
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
module rgb2y(
    input wire [5:0] r,
    input wire [5:0] g,
    input wire [5:0] b,
    output wire [5:0] y
    );

    wire [13:0] r_mult = {8'd0, r} * 14'd77;
    wire [13:0] g_mult = {8'd0, g} * 14'd150;
    wire [13:0] b_mult = {8'd0, b} * 14'd29;

    wire [13:0] acc = r_mult + g_mult + b_mult;

    assign y = acc[13:8];

endmodule
`default_nettype wire
