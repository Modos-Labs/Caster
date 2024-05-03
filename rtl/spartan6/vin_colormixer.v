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
// vin_colormixer.v
// Process input color depending on the screen type (mono, kaleido, des etc.) 
`timescale 1ns / 1ps
`default_nettype none
module vin_colormixer(
    input  wire         clk,
    input  wire         in_vsync,
    input  wire         in_hsync,
    input  wire [47:0]  in_color,
    input  wire         in_valid,
    output reg  [15:0]  out_color,
    output reg          out_valid
);

    wire [5:0] r_even = in_color[47:42];
    wire [5:0] g_even = in_color[39:34];
    wire [5:0] b_even = in_color[31:26];
    wire [5:0] r_odd = in_color[23:18];
    wire [5:0] g_odd = in_color[15:10];
    wire [5:0] b_odd = in_color[7:2];

    wire [7:0] y_odd;
    wire [7:0] y_even;

    // Processing for mono
    rgb2y rgb2y_odd (.r(r_odd), .g(g_odd), .b(b_odd), .y(y_odd));
    rgb2y rgb2y_even (.r(r_even), .g(g_even), .b(b_even), .y(y_even));
//    `else
//        // Processing for DES
//        reg [1:0] c_cnt_x;
//        reg [1:0] c_cnt_y;
//        reg hs_last;
//        reg first_line;
//        always @(posedge clk) begin
//            hs_last <= in_hsync;
//            if (!hs_last && in_hsync) begin
//                if (in_vsync) begin
//                    c_cnt_y <= 2'd1;
//                    c_cnt_x <= 2'd0;
//                    first_line <= 1'b1;
//                end
//                else if (!first_line) begin
//                    c_cnt_x <= c_cnt_y;
//                    if (c_cnt_y == 2'd2) begin
//                        c_cnt_y <= 2'd0;
//                    end
//                    else begin
//                        c_cnt_y <= c_cnt_y + 1;
//                    end
//                end
//            end
//            else if (in_valid) begin
//                first_line <= 1'b0;
//                if (c_cnt_x == 2'd2) begin
//                    c_cnt_x <= 2'd0;
//                end
//                else begin
//                    c_cnt_x <= c_cnt_x + 1;
//                end
//            end
//        end
//        assign y_odd[7:2] = (c_cnt_x == 2'd0) ? (b_odd) :
//                (c_cnt_x == 2'd1) ? (r_odd) : (g_odd);
//        assign y_even[7:2] = (c_cnt_x == 2'd0) ? (r_even) :
//                (c_cnt_x == 2'd1) ? (g_even) : (b_even);
//        assign y_odd[1:0] = y_odd[7:6];
//        assign y_even[1:0] = y_even[7:6];
//    `endif

    always @(posedge clk) begin
        out_valid <= in_valid;
        out_color = {y_even, y_odd};
    end

endmodule
`default_nettype wire
