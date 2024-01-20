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
    parameter INPUT_BITS = 8, // Fixed 8, only 6 MSBs are used
    parameter OUTPUT_BITS = 4, // 1 or 4
    parameter PIXEL_RATE = 4, // pixels per cycle
	 parameter PIXEL_RATE_LOG2 = 2 // $clog2(PIXEL_RATE) is not supported by ISE
) (
    input wire clk,
    input wire rst,
    input wire [INPUT_BITS*PIXEL_RATE-1:0] in,
    input wire in_valid,
    input wire hsync,
    input wire vsync,
    output wire [OUTPUT_BITS*PIXEL_RATE-1:0] out
);

    // Error uses 8p1 fixed point format, range -256 (-128) to 255 (127.5)
    // Note to the 
    localparam ERROR_BITS = 9;
    localparam EB_ABITS = 12 / PIXEL_RATE_LOG2;
    localparam EB_DBITS = ERROR_BITS * PIXEL_RATE;

    // input/output shuffle
    wire [INPUT_BITS*PIXEL_RATE-1:0] in_r;
    wire [OUTPUT_BITS*PIXEL_RATE-1:0] out_r;
    reg [INPUT_BITS*PIXEL_RATE-1:0] s1_in_r_reg;

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
    reg [EB_ABITS-1:0] x_counter;
    // delayed by 1 clk
    reg s1_valid;
    reg [EB_ABITS-1:0] s1_x_counter;
    // delayed by 2 clks
    reg s2_valid;
    reg [EB_ABITS-1:0] s2_x_counter;
    // delayed by 3 clks
    reg s3_valid;
    reg [EB_ABITS-1:0] s3_x_counter;
    
    // The wb buffer functions like a shift register, for the first cycle only
    // 3 pixels are valid and for the last cycle only 1 pixel is valid. For all
    // cycles in the middle, 4 pixels are valid.
    // 1st cycle [ P03 P02 P01 P00 --- --- --- ]
    // 2nd cycle [ P13 P12 P11 P10 P03 P02 P01 ]
    reg [ERROR_BITS*(PIXEL_RATE*2-1)-1:0] err_bl; // bottom left, write back buffer
    reg [ERROR_BITS-1:0] err_r; // right
    reg [ERROR_BITS-1:0] err_b; // bottom
    reg [ERROR_BITS-1:0] err_br; // bottom right

    // Suppress error buffer for the first line (last line from previous frame)
    wire [ERROR_BITS*PIXEL_RATE-1:0] err_eb = first_line ? 'd0 : eb_rd;
    reg [ERROR_BITS*PIXEL_RATE-1:0] s1_err_eb_reg;

    wire [EB_ABITS-1:0] x_counter_inc = x_counter + 'd1;

    // Outputs kernel
    wire [ERROR_BITS*PIXEL_RATE-1:0] err_r_out;
    wire [ERROR_BITS*PIXEL_RATE-1:0] err_bl_out;
    wire [ERROR_BITS*PIXEL_RATE-1:0] err_b_out;
    wire [ERROR_BITS*PIXEL_RATE-1:0] err_br_out;
    wire [OUTPUT_BITS*PIXEL_RATE-1:0] quant_out;

    wire [ERROR_BITS*(PIXEL_RATE*2-1)-1:0] err_bl_next;
    wire [ERROR_BITS-1:0] err_r_next;
    wire [ERROR_BITS-1:0] err_b_next;
    wire [ERROR_BITS-1:0] err_br_next;

    // For readability
    `define CUR_PIX     i*ERROR_BITS+:ERROR_BITS
    `define PREV_PIX    (i-1)*ERROR_BITS+:ERROR_BITS
    `define LAST_PIX    (PIXEL_RATE-1)*ERROR_BITS+:ERROR_BITS

    genvar i;
    generate
        for (i = 0; i < PIXEL_RATE; i = i + 1) begin: gen_kernel
            // This logic runs at 1 cycle later than input becomes valid
            error_diffusion_kernel #(
                .INPUT_BITS(INPUT_BITS),
                .OUTPUT_BITS(OUTPUT_BITS),
                .ERROR_BITS(ERROR_BITS)
            ) kernel (
                .pixel_in(s1_in_r_reg[i*INPUT_BITS+:INPUT_BITS]),
                .err_line_buffer_in(s1_err_eb_reg[`CUR_PIX]),
                .err_left_in((i == 0) ? err_r : err_r_out[`PREV_PIX]),
                .err_bottom_left_in((i == 0) ? err_b : err_b_out[`PREV_PIX]),
                .err_bottom_in((i == 0) ? err_br : err_br_out[`PREV_PIX]),
                .pixel_out(quant_out[i*OUTPUT_BITS+:OUTPUT_BITS]),
                .err_right_out(err_r_out[`CUR_PIX]),
                .err_bottom_left_out(err_bl_out[`CUR_PIX]),
                .err_bottom_out(err_b_out[`CUR_PIX]),
                .err_bottom_right_out(err_br_out[`CUR_PIX])
            );
        end
    endgenerate

    // Assign register next value
    assign err_bl_next = {err_bl_out, err_bl[ERROR_BITS*PIXEL_RATE+:(PIXEL_RATE-1)*ERROR_BITS]};
    // For bl, other pixels output are assigned in the generate for loop
    assign err_r_next = err_r_out[`LAST_PIX];
    assign err_b_next = err_b_out[`LAST_PIX];
    assign err_br_next = err_br_out[`LAST_PIX];

    assign eb_we = s3_valid; // intentionally dropping 1st pixel/ cycle
    assign eb_wptr = s3_x_counter;
    assign eb_wr = err_bl[ERROR_BITS*PIXEL_RATE-1:0];

    // Assign IO shuffle
    generate for (i = 0; i < PIXEL_RATE; i = i + 1) begin: gen_io_shuffle
        assign in_r[i*INPUT_BITS+:INPUT_BITS] =
                in[(PIXEL_RATE-1-i)*INPUT_BITS+:INPUT_BITS];
        assign out_r[i*OUTPUT_BITS+:OUTPUT_BITS] =
                quant_out[(PIXEL_RATE-1-i)*OUTPUT_BITS+:OUTPUT_BITS];
    end endgenerate

    assign out = out_r; // Output is not bufferred

    // For debugging visibility
    // wire [ERROR_BITS-1:0] eb_wr_expanded [0:PIXEL_RATE-1];
    // generate for (i = 0; i < PIXEL_RATE; i += 1)
    //     assign eb_wr_expanded[i] = eb_wr[i*ERROR_BITS+:ERROR_BITS];
    // endgenerate

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
        s3_valid <= s2_valid;
        s3_x_counter <= s2_x_counter;

        s1_in_r_reg <= in_r;
        s1_err_eb_reg <= err_eb;

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

        if (rst) begin
            s1_valid <= 1'b0;
            s2_valid <= 1'b0;
            s1_err_eb_reg <= 'd0;
        end
    end


endmodule
`default_nettype wire
