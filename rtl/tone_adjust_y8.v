`timescale 1ns / 1ps
`default_nettype none

module tone_adjust_y8(
    input  wire        clk,
    input  wire [31:0] i_pixel,
    output wire [31:0] o_pixel,
    input  wire [7:0]  tone_addr,
    input  wire [7:0]  tone_wr,
    input  wire        tone_we
);

    wire [7:0] y0_dout_a;
    wire [7:0] y0_dout_b;
    wire [7:0] y1_dout_a;
    wire [7:0] y1_dout_b;

    wire [7:0] y0_addr_a = tone_we ? tone_addr : i_pixel[7:0];
    wire [7:0] y1_addr_a = tone_we ? tone_addr : i_pixel[23:16];

    mu_ram_2rw #(.AW(8), .DW(8)) tone_lut_mem0 (
        .clka(clk),
        .wea(tone_we),
        .addra(y0_addr_a),
        .dina(tone_wr),
        .douta(y0_dout_a),
        .clkb(clk),
        .web(1'b0),
        .addrb(i_pixel[15:8]),
        .dinb(8'd0),
        .doutb(y0_dout_b)
    );

    mu_ram_2rw #(.AW(8), .DW(8)) tone_lut_mem1 (
        .clka(clk),
        .wea(tone_we),
        .addra(y1_addr_a),
        .dina(tone_wr),
        .douta(y1_dout_a),
        .clkb(clk),
        .web(1'b0),
        .addrb(i_pixel[31:24]),
        .dinb(8'd0),
        .doutb(y1_dout_b)
    );

    assign o_pixel = {y1_dout_b, y1_dout_a, y0_dout_b, y0_dout_a};

endmodule
`default_nettype wire
