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
// vin_dvi.v
// DVI video input
`timescale 1ns / 1ps
`default_nettype none
module vin_dvi(
    input  wire         rst,
    output wire         rst_out,
    input  wire         dvi_cp,
    input  wire         dvi_cn,
    input  wire [2:0]   dvi_dp,
    input  wire [2:0]   dvi_dn,
    output reg          v_vsync,
    output reg          v_hsync,
    output reg          v_pclk,
    output reg          v_de,
    output wire [15:0]  v_pixel,
    output wire         dbg_pclk,
    output wire         dbg_hsync,
    output wire         dbg_vsync,
    output wire         dbg_de,
    output wire         dbg_pll_lck
);

    wire pclk, hsync, vsync, de;
    wire [7:0] red, green, blue;

    dvi_serdes_in dvi_serdes_in(
        .rstin(rst),
        .rst(rst_out),
        .dvi_cp(dvi_cp),
        .dvi_cn(dvi_cn),
        .dvi_dp(dvi_dp),
        .dvi_dn(dvi_dn),
        .pclk(pclk),
        .hsync(hsync),
        .vsync(vsync),
        .de(de),
        .red(red),
        .green(green),
        .blue(blue),
        .dbg_pll_lck(dbg_pll_lck)
    );

    wire [17:0] rgb666 = {red[7:2], green[7:2], blue[7:2]};
    reg [35:0] pixel_rgb;
    reg [1:0] ignore;
    wire ignored = ignore != 'd0;
    reg [17:0] pixbuf;
    reg last_de, last_vsync;
    always @(posedge pclk or posedge rst_out) begin
        if (rst_out) begin
            v_pclk <= 1'b0;
            v_de <= 1'b0;
            ignore <= 2'd3; // ignore first few frames
        end
        else begin
            if (vsync && !last_vsync && (ignore != 'd0)) begin
                ignore <= ignore - 'd1;
            end

            if ((de && !last_de) || v_pclk) begin
                // re-sync when de is first high
                pixbuf <= rgb666;
                v_pclk <= 1'b0;
            end
            else begin
                v_pclk <= 1'b1;
                v_de <= de && !ignored;
                pixel_rgb <= {pixbuf, rgb666};
                v_hsync <= hsync && !ignored;
                v_vsync <= vsync && !ignored;
            end
            
            last_de <= de;
            last_vsync <= vsync;
        end
    end

    rgb2y rgb2y_odd (
        .r(pixel_rgb[17:12]),
        .g(pixel_rgb[11:6]),
        .b(pixel_rgb[5:0]),
        .y(v_pixel[7:0])
    );

    rgb2y rgb2y_even (
        .r(pixel_rgb[35:30]),
        .g(pixel_rgb[29:24]),
        .b(pixel_rgb[23:18]),
        .y(v_pixel[15:8])
    );
    
    assign dbg_pclk = pclk;
    assign dbg_hsync = hsync;
    assign dbg_vsync = vsync;
    assign dbg_de = de;

endmodule
