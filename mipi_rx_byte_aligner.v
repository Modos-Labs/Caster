`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting Zhang
// 
// Create Date:    23:46:32 11/10/2021 
// Design Name:    caster
// Module Name:    mipi_rx_byte_aligner 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//   Detect SoT pattern in the lane and produce byte aligned output
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mipi_byte_aligner(
    input  wire         clk,
    input  wire         rst,
    input  wire [7:0]   din,
    output reg  [7:0]   dout,
    output reg          valid
    );

    reg [2:0] offset;
    reg [7:0] din_last;
    wire [15:0] buffer = {din, din_last};
    
    reg [3:0] i;
    
    always @(posedge clk) begin
        if (rst) begin
            din_last <= 8'h0;
            valid <= 1'b0;
            offset <= 3'h0;
            dout <= 8'h0;
        end
        else begin
            din_last <= din;
            if (!valid) begin
                for (i = 0; i < 8; i = i + 1'b1) begin
                    if (buffer[i +: 8] == 8'hB8) begin
                        offset <= i[2:0];
                        dout <= 8'hB8;
                        valid <= 1'b1;
                    end
                end
            end
            else begin
                dout <= buffer[offset +: 8];
            end
        end
    end

endmodule
