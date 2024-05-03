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
// blue_noise_dithering.v
// Blue noise dithering implementation, 1 cycle latency
`timescale 1ns / 1ps
`default_nettype none
module blue_noise_dithering #(
    parameter OUTPUT_BITS = 1 // 1 or 4
) (
    input wire                      clk,
    input wire [31:0]               vin,
    output reg [OUTPUT_BITS*4-1:0]  vout,
    input wire [3:0]                x_pos,
    input wire [5:0]                y_pos
);

    // Noise attenuation, in bits
    localparam NOISE_ATTEN = (OUTPUT_BITS == 1) ? 'd0 : 'd4;

    wire [OUTPUT_BITS*4-1:0] vo_dithered;
    /* verilator lint_off UNUSEDSIGNAL */
    // Lower 4 bits are not used in 4bpp mode
    wire [7:0] b0, b1, b2, b3;
    // Lower 4 bits are not used
    wire [7:0] c0, c1, c2, c3;
    /* verilator lint_on UNUSEDSIGNAL */

    wire [9:0] addr_hi = {y_pos, x_pos};

    bramdp #(
        .ABITS(12),
        .DBITS(8),
        .INITIALIZE(1),
        .INIT_FILE("noise.mem")
    ) bramdp0 (
        .clka(clk),
        .wea(1'b0),
        .addra({addr_hi, 2'd0}),
        .dina(8'b0),
        .douta(b0),
        .clkb(clk),
        .web(1'b0),
        .addrb({addr_hi, 2'd1}),
        .dinb(8'b0),
        .doutb(b1)
    );

    bramdp #(
        .ABITS(12),
        .DBITS(8),
        .INITIALIZE(1),
        .INIT_FILE("noise.mem")
    ) bramdp1 (
        .clka(clk),
        .wea(1'b0),
        .addra({addr_hi, 2'd2}),
        .dina(8'b0),
        .douta(b2),
        .clkb(clk),
        .web(1'b0),
        .addrb({addr_hi, 2'd3}),
        .dinb(8'b0),
        .doutb(b3)
    );

    wire [7:0] a0 = vin[31:24];
    wire [7:0] a1 = vin[23:16];
    wire [7:0] a2 = vin[15:8];
    wire [7:0] a3 = vin[7:0];

    adder_sat_8 adder_sat0 (a0, {{NOISE_ATTEN{b0[7]}}, b0[7:NOISE_ATTEN]}, c0);
    adder_sat_8 adder_sat1 (a1, {{NOISE_ATTEN{b1[7]}}, b1[7:NOISE_ATTEN]}, c1);
    adder_sat_8 adder_sat2 (a2, {{NOISE_ATTEN{b2[7]}}, b2[7:NOISE_ATTEN]}, c2);
    adder_sat_8 adder_sat3 (a3, {{NOISE_ATTEN{b3[7]}}, b3[7:NOISE_ATTEN]}, c3);
    assign vo_dithered = {
        c0[7-:OUTPUT_BITS],
        c1[7-:OUTPUT_BITS],
        c2[7-:OUTPUT_BITS],
        c3[7-:OUTPUT_BITS]
    };

    always @(posedge clk) begin
        vout <= vo_dithered;
    end

endmodule
`default_nettype wire
