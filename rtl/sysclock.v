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
// sysclock.v
// Glider-specific clock generation
`timescale 1ns / 1ps

module sysclock(
    // Clock in ports
    input  wire clk_in,
    // Clock out ports
    output wire clk_ddr,
    output wire clk_sys,
    // Status and control signals
    input  wire reset,
    output wire locked
 );

    wire clk_in_buffered;

    // Input buffering
    //------------------------------------
    IBUFG clkin1_buf (
        .O (clk_in_buffered),
        .I (clk_in)
    );

    // Clocking primitive
    //------------------------------------

    // Instantiation of the DCM primitive
    //    * Unused inputs are tied off
    //    * Unused outputs are labeled unused
    wire        psdone_unused;
    wire        locked_int;
    wire [7:0]  status_int;
    wire clkfb;
    wire clk0;
    wire clkfx;

    DCM_SP #(
        .CLKDV_DIVIDE          (2.000),
        .CLKFX_DIVIDE          (2),
        .CLKFX_MULTIPLY        (20),
        .CLKIN_DIVIDE_BY_2     ("FALSE"),
        .CLKIN_PERIOD          (30.0),
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

        .RST                   (reset),
        // Unused pin- tie low
        .DSSEN                 (1'b0)
    );

    assign locked = locked_int;

    // Output buffering
    //-----------------------------------
    BUFG clkf_buf (
        .O (clkfb),
        .I (clk0)
    );

    // MIG generates its own BUFG, no needs for buffering here
    BUFG clkddr_buf (
        .O (clk_ddr),
        .I (clkfx)
    );
    //assign clk_ddr = clkfx;
    
    /*wire clk_3m;
    clk_div #(.WIDTH(4), .DIV(10)) clk_div(
        .i(clk_in_buffered),
        .o(clk_3m)
    );
   
    BUFG clksys_buf (
        .O (clk_sys),
        .I (clk_3m)
    );*/
    // System runs at input clock (33MHz)
    assign clk_sys = clk_in_buffered;

endmodule
