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
// vin_internal.v
// Internal video signal generator
`default_nettype none
`timescale 1ns / 1ps
module vin_internal(
    input  wire         clk, // 33 MHz system clock input
    input  wire         rst,
    output reg          v_vsync, // active high
    output reg          v_hsync, // active high
    output wire         v_pclk,
    output reg          v_de, // active high
    output wire [31:0]  v_pixel // 4 pixels per clock, Y8
); 
    assign v_pclk = clk;
    assign v_rst = rst;
    // TODO: Use settings from register file

//`define UXGA
`define SQCIF

`ifdef UXGA
    // Horizontal
    // All numbers are divided by 4
    parameter H_FP    = 2;   //Front porch
    parameter H_SYNC  = 8;   //Sync
    parameter H_BP    = 10;  //Back porch
    parameter H_ACT   = 400; //Active pixels
    // Vertical
    parameter V_FP    = 21;   //Front porch
    parameter V_SYNC  = 8;    //Sync
    parameter V_BP    = 6;    //Back porch
    parameter V_ACT   = 1200; //Active lines
`elsif SQCIF
    // This is for simualtion only
    parameter H_FP    = 2;
    parameter H_SYNC  = 3;
    parameter H_BP    = 4;
    parameter H_ACT   = 32;
    parameter V_FP    = 1;
    parameter V_SYNC  = 3;
    parameter V_BP    = 6;
    parameter V_ACT   = 96;
`endif

    parameter H_BLANK = H_FP + H_SYNC + H_BP; //Total blank length
    parameter H_TOTAL = H_FP + H_SYNC + H_BP + H_ACT; //Total line length
    
    parameter V_BLANK = V_FP + V_SYNC + V_BP; //Total blank length
    parameter V_TOTAL = V_FP + V_SYNC + V_BP + V_ACT; //Total field length

    reg [11:0] h_count;
    reg [11:0] v_count;
    wire [11:0] x;
    wire [11:0] y;
    
    // For pattern generation
    reg [8:0] frame_count;
    localparam FCNT_MAX = 480; // 8 sec
    
    always @(posedge v_pclk) begin
        if (v_rst) begin
            h_count <= 0;
            v_count <= 0;
            frame_count <= 0;
        end
        else begin
            if(h_count == H_TOTAL - 1) begin
                h_count <= 0;
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 0;
                    if (frame_count == FCNT_MAX - 1) begin
                        frame_count <= 0;
                    end
                    else begin
                        frame_count <= frame_count + 1;
                    end
                end
                else begin
                    v_count <= v_count + 1'b1;
                end
            end 
            else begin
                h_count <= h_count + 1'b1;
            end
        end
    end

    wire h_active = (h_count >= H_BLANK);
    wire v_active = (v_count >= V_BLANK);
    wire de = h_active && v_active;

    assign x = de ? (h_count - H_BLANK) : 12'd0;
    assign y = de ? (v_count - V_BLANK) : 12'd0;
    
    wire hs = ((h_count > H_FP) && (h_count <= H_FP + H_SYNC));
    wire vs = ((v_count > V_FP) && (v_count <= V_FP + V_SYNC));
    
    assign v_pixel = 32'hFFFFFFFF;
    
    // Buffer signal through DFF
    always @(posedge v_pclk) begin
        if (v_rst) begin
            v_hsync <= 1'b0;
            v_vsync <= 1'b0;
            v_de <= 1'b0;
        end
        else begin
            v_hsync <= hs;
            v_vsync <= vs;
            v_de <= de;
        end
    end

endmodule
