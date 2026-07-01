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
    output wire         v_pclk,      // 1/2 dpi_pclk's frequency
    output reg          v_de,
    output reg  [35:0]  v_pixel,
    output wire         v_halfpclk,  // 1/4 dpi_pclk's frequency
    output wire         v_valid
);

    wire locked_int;
    wire [7:0] status_int;

    wire clk_1x_dcm;
    wire clk_div2_dcm;
    wire clk_div4_dcm;

    wire clk_1x;
    wire clk_div2;
    wire clk_div4;

    wire dpi_pclk_buf;

    IBUFG pclkin_buf (
        .O (dpi_pclk_buf),
        .I (dpi_pclk)
    );

    // =========================================================================
    // CLOCK GENERATION (Source Synchronous)
    // =========================================================================
    DCM_SP #(
        .CLKDV_DIVIDE          (2.000),   // CLKDV = 1/2 of input
        .CLKFX_DIVIDE          (8),       // CLKFX = input * (2/8) = 1/4 of input
        .CLKFX_MULTIPLY        (2),
        .CLKIN_DIVIDE_BY_2     ("FALSE"),
        .CLKIN_PERIOD          (6.0),     // 166MHz max
        .CLKOUT_PHASE_SHIFT    ("NONE"),
        .CLK_FEEDBACK          ("1X"),
        .DESKEW_ADJUST         ("SOURCE_SYNCHRONOUS"), // 0-skew capture
        .PHASE_SHIFT           (0),
        .STARTUP_WAIT          ("FALSE")
    )
    dcm_sp_inst (
        .CLKIN                 (dpi_pclk_buf),
        .CLKFB                 (clk_1x),
        .CLK0                  (clk_1x_dcm),
        .CLK90                 (),
        .CLK180                (),
        .CLK270                (),
        .CLK2X                 (),
        .CLK2X180              (),
        .CLKFX                 (clk_div4_dcm), // 1/4x output
        .CLKFX180              (),
        .CLKDV                 (clk_div2_dcm), // 1/2x output
        .PSCLK                 (1'b0),
        .PSEN                  (1'b0),
        .PSINCDEC              (1'b0),
        .PSDONE                (),
        .LOCKED                (locked_int),
        .STATUS                (status_int),
        .RST                   (rst),
        .DSSEN                 (1'b0)
    );

    // Buffer 1: The feedback and 1x capture clock
    BUFG clkf_buf (
        .O (clk_1x),
        .I (clk_1x_dcm)
    );

    // Buffer 2: The 0.5x clock (v_pclk domain)
    BUFG clkdv_buf (
        .O (clk_div2),
        .I (clk_div2_dcm)
    );


    // We don't need BUFG here because it will be added by this module's user
    // // Buffer 3: The 0.25x clock (v_halfpclk domain)
    // BUFG clkfx_buf (
    //     .O (clk_div4),
    //     .I (clk_div4_dcm)
    // );

    wire vi_rst = !locked_int;
    assign v_valid = locked_int;

    assign v_pclk     = clk_div2;
    assign v_halfpclk = clk_div4_dcm;  // user code is expected to add BUFG


    // =========================================================================
    // FAST DOMAIN PIPELINE (clk_1x)
    // =========================================================================
    (* IOB = "TRUE" *) reg        de_n;
    (* IOB = "TRUE" *) reg        hsync_n;
    (* IOB = "TRUE" *) reg        vsync_n;
    (* IOB = "TRUE" *) reg [17:0] p_n;

    reg        de_n1, hsync_n1, vsync_n1;
    reg [17:0] p_n1;

    reg        de_n2, hsync_n2, vsync_n2;
    reg [17:0] p_n2;

    always @(posedge clk_1x) begin
        // Shift Stage N
        de_n    <= dpi_de;
        hsync_n <= dpi_hsync;
        vsync_n <= dpi_vsync;
        p_n     <= dpi_pixel[17:0];

        // Shift Stage N-1
        de_n1    <= de_n;
        hsync_n1 <= hsync_n;
        vsync_n1 <= vsync_n;
        p_n1     <= p_n;

        // Shift Stage N-2
        de_n2    <= de_n1;
        hsync_n2 <= hsync_n1;
        vsync_n2 <= vsync_n1;
        p_n2     <= p_n1;
    end

    // =========================================================================
    // SLOW DOMAIN PHASE DETECTION & DATA OUTPUT (clk_div2)
    // =========================================================================
    reg offset_mode;

    // Combinatorial phase detection
    wire current_mode = (de_n == 1'b1  && de_n1 == 1'b0) ? 1'b1 : // Offset detected
                        (de_n1 == 1'b1 && de_n2 == 1'b0) ? 1'b0 : // No offset detected
                        offset_mode;                              // Maintain state

    reg [1:0] ignore;
    wire ignored = (ignore != 2'd0);
    reg last_vsync;

    always @(posedge clk_div2 or posedge vi_rst) begin
        if (vi_rst) begin
            v_de        <= 1'b0;
            v_hsync     <= 1'b0;
            v_vsync     <= 1'b0;
            v_pixel     <= 36'd0;
            ignore      <= 2'd3;
            offset_mode <= 1'b0;
            last_vsync  <= 1'b0;
        end
        else begin
            // Lock in the alignment mode for the duration of the video line
            offset_mode <= current_mode;

            if (current_mode == 1'b1) begin
                // Offset Mode: Use older pixels (N-2) and (N-1)
                last_vsync <= vsync_n2;
                if (vsync_n2 && !last_vsync && (ignore != 2'd0)) begin
                    ignore <= ignore - 2'd1;
                end

                v_pixel <= {p_n2, p_n1};
                v_de    <= de_n2 && !ignored;
                v_hsync <= hsync_n2 && !ignored;
                v_vsync <= vsync_n2 && !ignored;
            end else begin
                // No-Offset Mode: Use newer pixels (N-1) and (N)
                last_vsync <= vsync_n1;
                if (vsync_n1 && !last_vsync && (ignore != 2'd0)) begin
                    ignore <= ignore - 2'd1;
                end

                v_pixel <= {p_n1, p_n};
                v_de    <= de_n1 && !ignored;
                v_hsync <= hsync_n1 && !ignored;
                v_vsync <= vsync_n1 && !ignored;
            end
        end
    end

endmodule

`default_nettype wire
