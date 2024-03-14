// Copyright Modos / Wenting Zhang 2024
//
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2
//
// You may redistribute and modify this documentation and make products using
// it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl). This
// documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
// INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A
// PARTICULAR PURPOSE. Please see the CERN-OHL-P v2 for applicable conditions
//
// error_diffusion_kernel.v
// Diffusion kernel, fully combinational
// Includes the error adder, quantizer, and diffuser
// The names in the interface are with respect to the pixel being dithered.
// Pay attention when feeding registered pixels from previous cycle or parallel
// dither units.
//
`default_nettype none
`timescale 1ns / 1ps
module error_diffusion_kernel #(
    parameter INPUT_BITS = 8, // Documentation purpose, only use 8
    parameter OUTPUT_BITS = 4, // Dither down to 1-bpp or 4-bpp
    parameter ERROR_BITS = 9 // Documentation purpose, only use 9
) (
    input wire [INPUT_BITS-1:0] pixel_in,
    input wire [ERROR_BITS-1:0] err_line_buffer_in,
    input wire [ERROR_BITS-1:0] err_left_in,
    input wire [ERROR_BITS-1:0] err_bottom_left_in,
    input wire [ERROR_BITS-1:0] err_bottom_in,
    output wire [OUTPUT_BITS-1:0] pixel_out,
    output wire [ERROR_BITS-1:0] err_right_out,
    output wire [ERROR_BITS-1:0] err_bottom_left_out,
    output wire [ERROR_BITS-1:0] err_bottom_out,
    output wire [ERROR_BITS-1:0] err_bottom_right_out
);

    // Add input pixel with error
    /* verilator lint_off UNUSEDSIGNAL */
    wire [ERROR_BITS+1-1:0] err_adder =
            $signed(err_left_in) + $signed(err_line_buffer_in);
    /* verilator lint_on UNUSEDSIGNAL */
    wire [ERROR_BITS+1-1:0] pix_adder =
            $signed({{(ERROR_BITS-INPUT_BITS+1){1'b0}}, pixel_in}) +
            $signed(err_adder[ERROR_BITS+1-1:1]);

    // Quantizer
    // The quantizer should pick the closest color in the linear space.
    // For 1-bit output, bit truncation (using MSB) gives the correct result.
    // For 4-bit output, bit truncation yields the wrong result, but for timing
    // closure this is used instead of implenting it properly
    // While the pixels here are in the linear space, the
    // quantized points may or may not (depending on the screen calibration).
    // For error diffusion this is compensated by the feedback loop.
    // WARN: underflow and overflow detection would fail if adder is not 10 bits
    wire [7:0] pix_qlinear;
    generate
        if (OUTPUT_BITS == 1) begin: gen_quantizer_1bit
            wire pix_quantized =
                pix_adder[9] ? 1'b0 : // underflow
                pix_adder[8] ? 1'b1 : // overflow
                pix_adder[7];
            assign pixel_out = pix_quantized;
            assign pix_qlinear = pix_quantized ? 8'hff : 8'h00;
        end
        else if (OUTPUT_BITS == 4) begin: gen_quantizer_4bit
            wire [7:0] pix_clamped =
                pix_adder[9] ? 8'd0 : // underflow
                pix_adder[8] ? 8'd255 : // overflow
                pix_adder[7:0];
            linear_4b_quantizer linear_4b_quantizer (
                .in(pix_clamped),
                .index(pixel_out),
                .linear(pix_qlinear)
            );
        end
    endgenerate

    // Calculate error
    wire [ERROR_BITS+1-1:0] quant_err =
            $signed(pix_adder) - $signed({2'b0, pix_qlinear});

    // Distribute error
    /* verilator lint_off UNUSEDSIGNAL */
    wire [ERROR_BITS+4-1:0] err_r_mult = $signed(quant_err) * 8;
    wire [ERROR_BITS+4-1:0] err_bl_mult = $signed(quant_err) * 3;
    wire [ERROR_BITS+4-1:0] err_b_mult = $signed(quant_err) * 4;
    wire [ERROR_BITS+4-1:0] err_br_mult = $signed(quant_err) * 1;
    /* verilator lint_on UNUSEDSIGNAL */
    // Divide only by 8 (instead of 16) to get 10p1 fixed point format
    wire [ERROR_BITS+1-1:0] err_r_div = err_r_mult[ERROR_BITS+4-1:3];
    wire [ERROR_BITS+1-1:0] err_bl_div = err_bl_mult[ERROR_BITS+4-1:3];
    wire [ERROR_BITS+1-1:0] err_b_div = err_b_mult[ERROR_BITS+4-1:3];
    wire [ERROR_BITS+1-1:0] err_br_div = err_br_mult[ERROR_BITS+4-1:3];

    //    X r
    // bl b br

    //   .    r+X  `r
    // b+`bl br+`b `br

    // Accumulate the error from pixels on the left before writing to BRAM
    wire [ERROR_BITS+1-1:0] err_b_acc =
            $signed(err_b_div) +
            $signed({err_bottom_in[ERROR_BITS-1], err_bottom_in});
    wire [ERROR_BITS+1-1:0] err_bl_acc =
            $signed(err_bl_div) +
            $signed({err_bottom_left_in[ERROR_BITS-1], err_bottom_left_in});

    // Clamp and output
    clamp_signed #(.INPUT_BITS(ERROR_BITS+1), .OUTPUT_BITS(ERROR_BITS))
            err_r_clamp (.in(err_r_div), .out(err_right_out));
    clamp_signed #(.INPUT_BITS(ERROR_BITS+1), .OUTPUT_BITS(ERROR_BITS))
            err_b_clamp (.in(err_b_acc), .out(err_bottom_out));
    clamp_signed #(.INPUT_BITS(ERROR_BITS+1), .OUTPUT_BITS(ERROR_BITS))
            err_br_clamp (.in(err_br_div), .out(err_bottom_right_out)); 
    clamp_signed #(.INPUT_BITS(ERROR_BITS+1), .OUTPUT_BITS(ERROR_BITS))
            err_bl_clamp (.in(err_bl_acc), .out(err_bottom_left_out));

endmodule
`default_nettype wire
