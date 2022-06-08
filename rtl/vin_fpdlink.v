`timescale 1ns / 1ps
`default_nettype none
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
module vin_fpdlink(
    input  wire         clk, // 33 MHz system clock input
    input  wire         rst,
    input  wire         fpdlink_cp,
    input  wire         fpdlink_cn,
    input  wire [2:0]   fpdlink_odd_p,
    input  wire [2:0]   fpdlink_odd_n,
    input  wire [2:0]   fpdlink_even_p,
    input  wire [2:0]   fpdlink_even_n,
    output wire         v_vsync,
    output wire         v_hsync,
    output wire         v_pclk,
    output wire         v_de,
    output wire [7:0]   v_pixel // 2 pixels per clock, Y4
);

    wire gclk;
    wire [41:0] fpdlink_din;
    wire vi_rst;

    fpdlink_serdes_in fpdlink_serdes_in (
        .rst(vi_rst),
        .cp(fpdlink_cp),
        .cn(fpdlink_cn),
        .dp({fpdlink_odd_p, fpdlink_even_p}),
        .dn({fpdlink_odd_n, fpdlink_even_n}),
        .gclk(gclk),
        .dout(fpdlink_din)
    );
    
    wire [5:0] r_odd = fpdlink_din[40:35];
    wire [5:0] g_odd = {fpdlink_din[32:28], fpdlink_din[41]};
    wire [5:0] b_odd = {fpdlink_din[24:21], fpdlink_din[34:33]};
    wire [5:0] r_even = fpdlink_din[19:14];
    wire [5:0] g_even = {fpdlink_din[11:7], fpdlink_din[20]};
    wire [5:0] b_even = {fpdlink_din[3:0], fpdlink_din[13:12]};
    
    // TODO: Better color to greyscale
    wire [3:0] y_odd;
    wire [3:0] y_even;
    
    rgb2y rgb2y_odd (.r(r_odd), .g(g_odd), .b(b_odd), .y(y_odd));
    rgb2y rgb2y_even (.r(r_even), .g(g_even), .b(b_even), .y(y_even));
    
    wire vsync = fpdlink_din[26];
    reg last_vsync;
    reg [3:0] fcnt;
    reg vsync_masking;
    // Ignore first 5 frames  
    always @(posedge v_pclk) begin
        if (vi_rst) begin
            fcnt <= 0;
            vsync_masking <= 1'b0;
            last_vsync <= 1'b0;
        end
        else begin
            last_vsync <= vsync;
            if (!last_vsync && vsync) begin
                if (fcnt < 5) begin
                    fcnt <= fcnt + 1;
                    vsync_masking <= 1'b0;
                end
                else begin
                    vsync_masking <= 1'b1;
                end
            end
        end
    end
    
    assign v_pclk = gclk;
    assign v_vsync = vsync & vsync_masking;
    assign v_hsync = fpdlink_din[25];
    assign v_de = fpdlink_din[27];
    assign v_pixel = {y_even, y_odd};
    
endmodule
