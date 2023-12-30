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
// error_diffusion_dithering.v
// Error diffusion dithering implementation. Y8 input, Y4 or Y1 output.
// Uses 1 dual-port RAM for error line buffer, at 9bpp. (1 4Kx9 BRAM36)
//
`default_nettype none
`timescale 1ns / 1ps
module error_diffusion_dithering #(
    parameter BPP = 4 // 1 or 4
) (
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    input wire in_valid,
    input wire hsync,
    input wire vsync,
    output reg [3:0] out
);

    // Error uses 8p1 fixed point format, range -256 (-128) to 255 (127.5)
    // Note to the 
    localparam ERROR_BITS = 9;
    localparam INPUT_BITS = 8;
    localparam EB_ABITS = 12;
    localparam EB_DBITS = ERROR_BITS;

    // error buffer (eb)
    wire [EB_ABITS-1:0] eb_rptr;
    wire [EB_DBITS-1:0] eb_rd;
    wire [EB_ABITS-1:0] eb_wptr;
    wire eb_we;
    wire [EB_DBITS-1:0] eb_wr;
    bramdp #(
        .ABITS(EB_ABITS),
        .DBITS(EB_DBITS)
    ) error_buffer (
        .clka(clk),
        .wea(eb_we),
        .addra(eb_wptr),
        .dina(eb_wr),
        .douta(),
        .clkb(clk),
        .web(1'b0),
        .addrb(eb_rptr),
        .dinb('d0),
        .doutb(eb_rd)
    );

    reg first_line;
    reg line_valid;
    reg [11:0] x_counter;
    // delayed by 1 clk
    reg s1_valid;
    reg [11:0] s1_x_counter;
    // delayed by 2 clks
    reg s2_valid;
    reg [11:0] s2_x_counter;
    
    reg [ERROR_BITS-1:0] err_bl; // bottom left, for WB
    reg [ERROR_BITS-1:0] err_r; // right
    reg [ERROR_BITS-1:0] err_b; // bottom
    reg [ERROR_BITS-1:0] err_br; // bottom right

    // Suppress error buffer for the first line (last line from previous frame)
    wire [ERROR_BITS-1:0] err_eb = first_line ? 'd0 : eb_rd;

    wire [11:0] x_counter_inc = x_counter + 'd1;

    wire [ERROR_BITS+1-1:0] err_adder = $signed(err_r) + $signed(err_eb);
    wire [ERROR_BITS+1-1:0] pix_adder =
            $signed({{(ERROR_BITS-INPUT_BITS+1){1'b0}}, in}) +
            $signed(err_adder[ERROR_BITS+1-1:1]);

    // Quantizer
    // The quantizer should pick the closest color in the linear space.
    // For 1-bit output, bit truncation (using MSB) gives the correct result.
    // For 4-bit output, a coarse LUT is used for the purpose. 
    // While the pixels here are in the linear space, the
    // quantized points may or may not (depending on the screen calibration).
    // For error diffusion this is compensated by the feedback loop.
    wire [3:0] pix_quant_in_range;
    generate
        if (BPP == 1) begin
            assign pix_quant_in_range = {4{pix_adder[7]}};
        end
        else if (BPP == 4) begin
            // TODO
            assign pix_quant_in_range = pix_adder[7:4];
        end
    endgenerate
    // WARN: This detection would fail if adder is not 10 bits
    wire [3:0] pix_quantized =
            pix_adder[9] ? 4'd0 : // underflow
            pix_adder[8] ? 4'd15 : // overflow
            pix_quant_in_range;
    
    // Convert back to linear scale
    wire [7:0] pix_qlinear;
    generate
        if (BPP == 1) begin
            assign pix_qlinear = pix_quantized[7] ? 8'hff : 8'h00;
        end
        else if (BPP == 4) begin
            // Easier to just use degamma again
            degamma quant_degamma (
                .in({pix_quantized, pix_quantized[3:2]}),
                .out(pix_qlinear)
            );
        end
    endgenerate

    // Calculate error
    wire [ERROR_BITS+2-1:0] quant_err = $signed(pix_adder) - $signed({2'b0, pix_qlinear});

    // Distribute error
    wire [ERROR_BITS+5-1:0] err_r_mult = $signed(quant_err) * 7;
    wire [ERROR_BITS+5-1:0] err_bl_mult = $signed(quant_err) * 3;
    wire [ERROR_BITS+5-1:0] err_b_mult = $signed(quant_err) * 5;
    wire [ERROR_BITS+5-1:0] err_br_mult = $signed(quant_err) * 1;
    // Divide only by 8 (instead of 16) to get 10p1 fixed point format
    wire [ERROR_BITS+2-1:0] err_r_div = err_r_mult[ERROR_BITS+5-1:3];
    wire [ERROR_BITS+2-1:0] err_bl_div = err_bl_mult[ERROR_BITS+5-1:3];
    wire [ERROR_BITS+2-1:0] err_b_div = err_b_mult[ERROR_BITS+5-1:3];
    wire [ERROR_BITS+2-1:0] err_br_div = err_br_mult[ERROR_BITS+5-1:3];
    
    //    X r
    // bl b br

    //   .    r+X  `r
    // b+`bl br+`b `br

    wire [ERROR_BITS-1:0] err_r_next;
    clamp_11_to_9 err_r_clamp (.in(err_r_div), .out(err_r_next));
    
    wire [ERROR_BITS+2-1:0] err_b_acc = $signed(err_b_div) + $signed({err_br[ERROR_BITS-1], err_br});
    wire [ERROR_BITS-1:0] err_b_next;
    clamp_11_to_9 err_b_clamp (.in(err_b_acc), .out(err_b_next));
    
    wire [ERROR_BITS-1:0] err_br_next;
    clamp_11_to_9 err_br_clamp (.in(err_br_div), .out(err_br_next));
    
    wire [ERROR_BITS+2-1:0] err_bl_acc = $signed(err_bl_div) + $signed({err_b[ERROR_BITS-1], err_b});
    wire [ERROR_BITS-1:0] err_bl_next;
    clamp_11_to_9 err_bl_clamp (.in(err_bl_acc), .out(err_bl_next));

    assign eb_we = s2_valid; // intentionally dropping 1st pixel
    assign eb_wptr = s2_x_counter;
    assign eb_wr = err_bl;

    assign eb_rptr = in_valid ? x_counter_inc : 'd0;

    // cycle -1: valid = 0, rptr = 0, wptr = 0, we = 0
    // cycle  0: valid = 1, rptr = 1, wptr = 0, we = 0 (pix -1 wb calculated)
    // cycle  1: valid = 1, rptr = 2, wptr = 0, we = 0 (pix 0 wb calculated)
    // cycle  2: valid = 1, rptr = 3, wptr = 0, we = 1 (pix 0 wb registered)

    always @(posedge clk) begin
        
        if (vsync) begin
            line_valid <= 1'b0;
            first_line <= 1'b1;
            x_counter <= 'd0;
        end
        else if (hsync) begin
            line_valid <= 1'b0;
            if (line_valid)
                first_line <= 1'b0;
            x_counter <= 'd0;
        end
        else begin
            if (in_valid)
                line_valid <= 1'b1;
            if (in_valid || line_valid)
                x_counter <= x_counter_inc;
        end
        
        // Pipeline registers
        s1_valid <= in_valid;
        s1_x_counter <= x_counter;
        s2_valid <= s1_valid;
        s2_x_counter <= s1_x_counter;

        // Error buffers
        if (hsync) begin
            err_r <= 'd0;
            err_bl <= 'd0;
            err_b <= 'd0;
            err_br <= 'd0;
        end
        else if (in_valid) begin
            err_r <= err_r_next;
            err_bl <= err_bl_next;
            err_b <= err_b_next;
            err_br <= err_br_next;
        end

        // Output
        out <= pix_quantized;

        if (rst) begin
            s1_valid <= 1'b0;
            s2_valid <= 1'b0;
        end
    end


endmodule
`default_nettype wire
