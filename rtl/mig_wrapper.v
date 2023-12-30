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
// mig_wrapper.v
// This module simply wraps around the MIG
`default_nettype none
`timescale 1ns / 1ps
module mig_wrapper(
    // Clock and reset
    input  wire         clk_sys,
    output wire         clk_mif,
    input  wire         rst_in,
    output wire         sys_rst,
    // DDR RAM interface
    inout  wire [15:0]  ddr_dq,
    output wire [12:0]  ddr_a,
    output wire [2:0]   ddr_ba,
    output wire         ddr_ras_n,
    output wire         ddr_cas_n,
    output wire         ddr_we_n,
    output wire         ddr_odt,
    output wire         ddr_reset_n,
    output wire         ddr_cke,
    output wire         ddr_ldm,
    output wire         ddr_udm,
    inout  wire         ddr_udqs_p,
    inout  wire         ddr_udqs_n,
    inout  wire         ddr_ldqs_p,
    inout  wire         ddr_ldqs_n,
    output wire         ddr_ck_p,
    output wire         ddr_ck_n,
    inout  wire         ddr_rzq,
    inout  wire         ddr_zio,
    // Control interface
    output wire         ddr_calib_done,
    // User interface
    input  wire         mig_cmd_en,
    input  wire [2:0]   mig_cmd_instr,
    input  wire [5:0]   mig_cmd_bl,
    input  wire [29:0]  mig_cmd_byte_addr,
    output wire         mig_cmd_empty,
    output wire         mig_cmd_full,
    input  wire         mig_wr_en,
    input  wire [15:0]  mig_wr_mask,
    input  wire [127:0] mig_wr_data,
    output wire         mig_wr_empty,
    output wire         mig_wr_full,
    output wire [6:0]   mig_wr_count,
    output wire         mig_wr_underrun,
    input  wire         mig_rd_en,
    output wire [127:0] mig_rd_data,
    output wire         mig_rd_full,
    output wire         mig_rd_empty,
    output wire         mig_rd_overflow,
    output wire [6:0]   mig_rd_count,
    // Error
    output wire         error
);

    parameter SIMULATION = "FALSE";
    parameter CALIB_SOFT_IP = "TRUE";

    wire wr_error, rd_error;

    s6_ddr3 # (
        .C3_P0_MASK_SIZE(16),
        .C3_P0_DATA_PORT_SIZE(128),
        .DEBUG_EN(0),
        .C3_MEMCLK_PERIOD(3000),
        .C3_CALIB_SOFT_IP(CALIB_SOFT_IP),
        .C3_SIMULATION(SIMULATION),
        .C3_RST_ACT_LOW(0),
        .C3_INPUT_CLK_TYPE("SINGLE_ENDED"),
        .C3_MEM_ADDR_ORDER("ROW_BANK_COLUMN"),
        .C3_NUM_DQ_PINS(16),
        .C3_MEM_ADDR_WIDTH(13),
        .C3_MEM_BANKADDR_WIDTH(3)
    )
    s6_ddr3 (
        .c3_sys_clk             (clk_sys),
        .c3_sys_rst_i           (rst_in),

        .mcb3_dram_dq           (ddr_dq),
        .mcb3_dram_a            (ddr_a),
        .mcb3_dram_ba           (ddr_ba),
        .mcb3_dram_ras_n        (ddr_ras_n),
        .mcb3_dram_cas_n        (ddr_cas_n),
        .mcb3_dram_we_n         (ddr_we_n),
        .mcb3_dram_odt          (ddr_odt),
        .mcb3_dram_cke          (ddr_cke),
        .mcb3_dram_ck           (ddr_ck_p),
        .mcb3_dram_ck_n         (ddr_ck_n),
        .mcb3_dram_dqs          (ddr_ldqs_p),
        .mcb3_dram_dqs_n        (ddr_ldqs_n),
        .mcb3_dram_udqs         (ddr_udqs_p),
        .mcb3_dram_udqs_n       (ddr_udqs_n),
        .mcb3_dram_udm          (ddr_udm),
        .mcb3_dram_dm           (ddr_ldm),
        .mcb3_dram_reset_n      (ddr_reset_n),
        .c3_clk0		        (clk_mif),
        .c3_rst0		        (sys_rst),
        .c3_calib_done          (ddr_calib_done),
        .mcb3_rzq               (ddr_rzq),
        .c3_p0_cmd_clk          (clk_mif),
        .c3_p0_cmd_en           (mig_cmd_en),
        .c3_p0_cmd_instr        (mig_cmd_instr),
        .c3_p0_cmd_bl           (mig_cmd_bl),
        .c3_p0_cmd_byte_addr    (mig_cmd_byte_addr),
        .c3_p0_cmd_empty        (mig_cmd_empty),
        .c3_p0_cmd_full         (mig_cmd_full),
        .c3_p0_wr_clk           (clk_mif),
        .c3_p0_wr_en            (mig_wr_en),
        .c3_p0_wr_mask          (mig_wr_mask),
        .c3_p0_wr_data          (mig_wr_data),
        .c3_p0_wr_full          (mig_wr_full),
        .c3_p0_wr_empty         (mig_wr_empty),
        .c3_p0_wr_count         (mig_wr_count),
        .c3_p0_wr_underrun      (mig_wr_underrun),
        .c3_p0_wr_error         (wr_error),
        .c3_p0_rd_clk           (clk_mif),
        .c3_p0_rd_en            (mig_rd_en),
        .c3_p0_rd_data          (mig_rd_data),
        .c3_p0_rd_full          (mig_rd_full),
        .c3_p0_rd_empty         (mig_rd_empty),
        .c3_p0_rd_count         (mig_rd_count),
        .c3_p0_rd_overflow      (mig_rd_overflow),
        .c3_p0_rd_error         (rd_error)
    );

    assign error = wr_error || rd_error;

endmodule
