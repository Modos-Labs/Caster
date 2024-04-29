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
// vin_fpdlink.v
// FPD-Link I video input
`timescale 1ns / 1ps
`default_nettype none
module vin_fpdlink(
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
    output wire [47:0]  v_pixel, // 2 pixels per clock, RGB888
    output wire         v_halfpclk,
    output wire         v_valid
);
    parameter COLORMODE = "DES";

    wire gclk;
    wire [41:0] fpdlink_din_unreg;
    reg [41:0] fpdlink_din;
    wire vi_rst;

    fpdlink_serdes_in fpdlink_serdes_in (
        .rstin(rst),
        .rst(vi_rst),
        .cp(fpdlink_cp),
        .cn(fpdlink_cn),
        .dp({fpdlink_odd_p, fpdlink_even_p}),
        .dn({fpdlink_odd_n, fpdlink_even_n}),
        .gclk(gclk),
        .halfgclk(v_halfpclk),
        .dout(fpdlink_din_unreg)
    );

    always @(posedge v_pclk) begin
        fpdlink_din <= fpdlink_din_unreg;
    end
    
    wire [5:0] r_odd = fpdlink_din[40:35];
    wire [5:0] g_odd = {fpdlink_din[32:28], fpdlink_din[41]};
    wire [5:0] b_odd = {fpdlink_din[24:21], fpdlink_din[34:33]};
    wire [5:0] r_even = fpdlink_din[19:14];
    wire [5:0] g_even = {fpdlink_din[11:7], fpdlink_din[20]};
    wire [5:0] b_even = {fpdlink_din[3:0], fpdlink_din[13:12]};

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
    assign v_pixel = {
        r_even, 2'b0,
        g_even, 2'b0,
        b_even, 2'b0,
        r_odd, 2'b0,
        g_odd, 2'b0,
        b_odd, 2'b0
    };

    assign v_valid = vi_rst;
    
endmodule
`default_nettype wire
