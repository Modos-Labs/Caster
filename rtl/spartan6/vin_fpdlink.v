// Copyright Modos / Wenting Zhang 2023
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
    output wire [15:0]  v_pixel // 2 pixels per clock, Y8
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
    
    wire [7:0] y_odd;
    wire [7:0] y_even;
    
    generate
    if (COLORMODE=="MONO") begin: color_mono
        rgb2y rgb2y_odd (.r(r_odd), .g(g_odd), .b(b_odd), .y(y_odd));
        rgb2y rgb2y_even (.r(r_even), .g(g_even), .b(b_even), .y(y_even));
    end
    else if (COLORMODE=="DES") begin: color_des
        reg [1:0] c_cnt_x;
        reg [1:0] c_cnt_y;
        reg hs_last;
        reg first_line;
        always @(posedge v_pclk) begin
            hs_last <= v_hsync;
            if (!hs_last && v_hsync) begin
                if (v_vsync) begin
                    c_cnt_y <= 2'd1;
                    c_cnt_x <= 2'd0;
                    first_line <= 1'b1;
                end
                else if (!first_line) begin
                    c_cnt_x <= c_cnt_y;
                    if (c_cnt_y == 2'd2) begin
                        c_cnt_y <= 2'd0;
                    end
                    else begin
                        c_cnt_y <= c_cnt_y + 1;
                    end
                end
            end
            else if (v_de) begin
                first_line <= 1'b0;
                if (c_cnt_x == 2'd2) begin
                    c_cnt_x <= 2'd0;
                end
                else begin
                    c_cnt_x <= c_cnt_x + 1;
                end
            end
        end
        assign y_odd[7:2] = (c_cnt_x == 2'd0) ? (b_odd) :
                (c_cnt_x == 2'd1) ? (r_odd) : (g_odd);
        assign y_even[7:2] = (c_cnt_x == 2'd0) ? (r_even) :
                (c_cnt_x == 2'd1) ? (g_even) : (b_even);
        assign y_odd[1:0] = y_odd[7:6];
        assign y_even[1:0] = y_even[7:6];
    end
    endgenerate
    
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
`default_nettype wire
