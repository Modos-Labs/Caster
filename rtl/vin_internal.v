`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:32:21 05/31/2022 
// Design Name: 
// Module Name:    vin_internal 
// Project Name: 
// Target Devices: generic
// Tool versions: 
// Description: 
//   Generate a video stream for testing purposes
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module vin_internal(
    input  wire         clk, // 33 MHz system clock input
    input  wire         rst,
    output reg          v_vsync, // active high
    output reg          v_hsync, // active high
    output wire         v_pclk,
    output reg          v_de, // active high
    output reg  [7:0]   v_pixel // 2 pixels per clock, Y4
);
    
    // 33MHz to ~81MHz PLL (162MHz standard UXGA 60Hz timing)
    wire clkfbout;
    wire clkout0;
    wire pll_locked;
    
    PLL_BASE #(
        .BANDWIDTH              ("OPTIMIZED"),
        .CLK_FEEDBACK           ("CLKFBOUT"),
        .COMPENSATION           ("INTERNAL"),
        .DIVCLK_DIVIDE          (1),
        .CLKFBOUT_MULT          (17),
        .CLKFBOUT_PHASE         (0.000),
        .CLKOUT0_DIVIDE         (7),
        .CLKOUT0_PHASE          (0.000),
        .CLKOUT0_DUTY_CYCLE     (0.500),
        .CLKIN_PERIOD           (30.003),
        .REF_JITTER             (0.010))
    pll_base_inst (
        // Output clocks
        .CLKFBOUT              (clkfbout),
        .CLKOUT0               (clkout0),
        .CLKOUT1               (),
        .CLKOUT2               (),
        .CLKOUT3               (),
        .CLKOUT4               (),
        .CLKOUT5               (),
        // Status and control signals
        .LOCKED                (pll_locked),
        .RST                   (1'b0),
         // Input clock control
        .CLKFBIN               (clkfbout),
        .CLKIN                 (clk));

    BUFG pclk_buf (
        .O(v_pclk),
        .I(clkout0));

    reg locked = 1'b0;
    reg v_rst = 1'b0;
    always @(posedge v_pclk) begin
        if ((!locked) && (pll_locked)) begin
            v_rst <= 1'b1;
        end
        else begin
            v_rst <= 1'b0;
        end
        locked <= pll_locked;
    end

//`define UXGA
`define SQCIF

`ifdef UXGA
    // Horizontal
    // All numbers are divided by 2
    parameter H_FP    = 32;  //Front porch
    parameter H_SYNC  = 96;  //Sync
    parameter H_BP    = 152; //Back porch
    parameter H_ACT   = 800; //Active pixels
    // Vertical
    parameter V_FP    = 1;    //Front porch
    parameter V_SYNC  = 3;    //Sync
    parameter V_BP    = 46;   //Back porch
    parameter V_ACT   = 1200; //Active lines
`elsif SQCIF
    // This is for simualtion only
    parameter H_FP    = 4;
    parameter H_SYNC  = 6;
    parameter H_BP    = 8;
    parameter H_ACT   = 64;
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
    
    wire [7:0] pixel = 
        (frame_count < 9'd120) ? (
        ((x[0] ^ y[1]) ? 8'hFF : 8'h00)) : (
        (frame_count < 9'd240) ? (
        ((x[1] ^ y[2]) ? 8'hFF : 8'h00)) : (
        (frame_count < 9'd360) ? (
        ((x[2] ^ y[3]) ? 8'hFF : 8'h00)) : (
        ((x[3] ^ y[4]) ? 8'hFF : 8'h00))));
    
    // Buffer signal through DFF
    always @(posedge v_pclk) begin
        if (v_rst) begin
            v_hsync <= 1'b0;
            v_vsync <= 1'b0;
            v_de <= 1'b0;
            v_pixel <= 8'h00;
        end
        else begin
            v_hsync <= hs;
            v_vsync <= vs;
            v_de <= de;
            v_pixel <= pixel;
        end
    end

endmodule
