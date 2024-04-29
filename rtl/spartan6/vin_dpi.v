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
// vin_dpi.v
// DPI video input
// This module down converts the input pixel rate by 2
`timescale 1ns / 1ps
`default_nettype none
module vin_dpi(
    input  wire         rst,
    input  wire         dpi_vsync,
    input  wire         dpi_hsync,
    input  wire         dpi_pclk,
    input  wire         dpi_de,
    input  wire [23:0]  dpi_pixel,
    output reg          v_vsync,
    output reg          v_hsync,
    output reg          v_pclk,
    output reg          v_de,
    output reg  [47:0]  v_pixel,
    output wire         v_halfpclk,
    output wire         v_valid
);

    wire locked_int;
    wire [7:0] status_int;
    wire clkfb;
    wire clk0;
    wire clkfx;

    DCM_SP #(
        .CLKDV_DIVIDE          (2.000),
        .CLKFX_DIVIDE          (8),
        .CLKFX_MULTIPLY        (2),
        .CLKIN_DIVIDE_BY_2     ("FALSE"),
        .CLKIN_PERIOD          (6.0), // 166MHz max
        .CLKOUT_PHASE_SHIFT    ("NONE"),
        .CLK_FEEDBACK          ("1X"),
        .DESKEW_ADJUST         ("SYSTEM_SYNCHRONOUS"),
        .PHASE_SHIFT           (0),
        .STARTUP_WAIT          ("FALSE")
    )
    dcm_sp_inst (
        // Input clock
        .CLKIN                 (clk_in_buffered),
        .CLKFB                 (clkfb),
        // Output clocks
        .CLK0                  (clk0),
        .CLK90                 (),
        .CLK180                (),
        .CLK270                (),
        .CLK2X                 (),
        .CLK2X180              (),
        .CLKFX                 (clkfx),
        .CLKFX180              (),
        .CLKDV                 (),
        // Ports for dynamic phase shift
        .PSCLK                 (1'b0),
        .PSEN                  (1'b0),
        .PSINCDEC              (1'b0),
        .PSDONE                (),
        // Other control and status signals
        .LOCKED                (locked_int),
        .STATUS                (status_int),

        .RST                   (rst),
        // Unused pin- tie low
        .DSSEN                 (1'b0)
    );

    BUFG clkf_buf (
        .O (clkfb),
        .I (clk0)
    );

    wire vi_rst = !locked_int;
    assign v_valid = locked_int;

    // Register all inputs first
    wire pclk = clk0;
    reg hsync, vsync, de
    reg [23:0] pixelin;
    always @(posedge pclk) begin
        hsync <= dpi_hsync;
        vsync <= dpi_vsync;
        de <= dpi_de;
        pixelin <= dpi_pixel;
    end

    // The user should buffer the clock with BUFG / BUFGMUX
    assign v_halfpclk = clkfx;

    reg [1:0] ignore;
    wire ignored = ignore != 'd0;
    reg [23:0] pixbuf;
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
                pixbuf <= pixelin;
                v_pclk <= 1'b0;
            end
            else begin
                v_pclk <= 1'b1;
                v_de <= de && !ignored;
                v_pixel <= {pixbuf, pixelin};
                v_hsync <= hsync && !ignored;
                v_vsync <= vsync && !ignored;
            end
            
            last_de <= de;
            last_vsync <= vsync;
        end
    end

endmodule
