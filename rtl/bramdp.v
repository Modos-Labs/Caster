`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting
// 
// Create Date:    15:26:33 06/17/2022 
// Design Name:    caster
// Module Name:    bramdp 
// Project Name: 
// Target Devices:
// Tool versions: 
// Description: 
//   Generic dual port RAM, could be replaced with device specific implementation.
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module bramdp(
    input wire clka,
    input wire wea,
    input wire [13:0] addra,
    input wire [1:0] dina,
    output reg [1:0] douta,
    input wire clkb,
    input wire web,
    input wire [13:0] addrb,
    input wire [1:0] dinb,
    output reg [1:0] doutb
);

    reg [1:0] mem [0:16383];

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

endmodule
