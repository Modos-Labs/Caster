`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    03:10:32 11/16/2021 
// Design Name: 
// Module Name:    mipi_dsi_decoder 
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
module mipi_dsi_decoder(
    input  wire         clk,
    input  wire         rst,
    input  wire  [31:0] packet,
    input  wire         packet_valid,
    input  wire         packet_header,
    output reg          error,
    output reg          vs,
    output reg          hs,
    output reg   [31:0] pixel, // always output 2 RGB565 pixels
    output reg          de, // line enable signal, always valid during a line
    output reg          valid // pixel valid signal
    );

    reg [2:0] pixel_type;
    localparam PTYPE_NONE = 3'd0;
    localparam PTYPE_16BPP = 3'd1;
    localparam PTYPE_18BPP = 3'd2;
    localparam PTYPE_18BPP_LOOSE = 3'd3;
    localparam PTYPE_24BPP = 3'd4;

    always @(posedge clk) begin
        if (rst) begin
            vs <= 1'b0;
            hs <= 1'b0;
            pixel <= 32'b0;
            de <= 1'b0;
            valid <= 1'b0;
            pixel_type <= 1'b0;
            error <= 1'b0;
        end
        else begin
            if (packet_valid) begin
                if (packet_header) begin
                    case (packet[29:24])
                    6'h01: vs <= 1'b1;
                    6'h11: vs <= 1'b0;
                    6'h21: hs <= 1'b1;
                    6'h31: hs <= 1'b0;
                    6'h19: begin de <= 1'b0; pixel_type <= PTYPE_NONE; end
                    6'h0e: begin de <= 1'b1; pixel_type <= PTYPE_16BPP; end
                    6'h1e: begin de <= 1'b1; pixel_type <= PTYPE_18BPP; end
                    6'h2e: begin de <= 1'b1; pixel_type <= PTYPE_18BPP_LOOSE;end
                    6'h3e: begin de <= 1'b1; pixel_type <= PTYPE_24BPP; end
                    default: error <= 1'b1;
                    endcase
                    valid <= 1'b0;
                end
                else begin
                    case (pixel_type)
                    PTYPE_NONE: valid <= 1'b0;
                    PTYPE_16BPP: begin pixel <= packet; valid <= 1'b1; end
                    PTYPE_18BPP: begin pixel <= 0; valid <= 1'b0; end // not supported
                    PTYPE_18BPP_LOOSE: begin pixel <= 0; valid <= 1'b0; end // not supported
                    PTYPE_24BPP: begin pixel <= 0; valid <= 1'b0; end // not supported
                    endcase
                end
            end
        end
    end

endmodule
