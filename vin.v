`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting Zhang
// 
// Create Date:    03:43:30 11/09/2021 
// Design Name:    caster
// Module Name:    vin 
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
module vin(
    input  wire         rst,
    input  wire         dsi_cp,
    input  wire         dsi_cn,
    input  wire [3:0]   dsi_dp,
    input  wire [3:0]   dsi_dn,
    output wire         v_vsync,
    output wire         v_hsync,
    output wire         v_pclk,
    output wire [23:0]  v_pixel
);

    wire gclk;
    wire [31:0] dsi_din_unaligned;

    serdes_in serdes_in (
        .rst(rst),
        .cp(dsi_cp),
        .cn(dsi_cn),
        .dp(dsi_dp),
        .dn(dsi_dn),
        .gclk(gclk),
        .dout(dsi_din_unaligned)
    );
    
    wire [31:0] dsi_din_byte_aligned;
    wire [3:0] dsi_din_byte_valid;
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            mipi_byte_aligner mipi_byte_aligner(
                .clk(gclk),
                .rst(rst),
                .din(dsi_din_unaligned[i*8+7 -: 8]),
                .dout(dsi_din_byte_aligned[i*8+7 -: 8]),
                .valid(dsi_din_byte_valid[i])
            );
        end
    endgenerate
    
    wire [31:0] dsi_din_aligned;
    wire dsi_din_valid;
    wire aligner_error;
    
    mipi_lane_aligner mipi_lane_aligner(
        .clk(gclk),
        .rst(rst),
        .din(dsi_din_byte_aligned),
        .validin(dsi_din_byte_valid),
        .dout(dsi_din_aligned),
        .validout(dsi_din_valid),
        .error(aligner_error)
    );
    
    wire [31:0] dsi_packet;
    wire dsi_packet_valid;
    wire dsi_packet_header;
    
    mipi_rx_packet_slicer(
        .clk(gclk),
        .rst(rst),
        .din(dsi_din_aligned),
        .validin(dsi_din_valid),
        .dout(dsi_packet),
        .validout(dsi_packet_valid),
        .pktheader(dsi_packet_header)
    );

endmodule
