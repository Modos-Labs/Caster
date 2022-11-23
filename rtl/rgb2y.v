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
    output wire [3:0] y
    );

    wire [5:0] y_add = {2'b0, r[5:2]} + {1'b0, g[5:1]} + {2'b0, b[5:2]};
    assign y = y_add[5:2];

endmodule
`default_nettype wire
