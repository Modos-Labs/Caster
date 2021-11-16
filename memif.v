`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting Zhang
// 
// Create Date:    03:07:27 11/09/2021 
// Design Name:    caster
// Module Name:    memif 
// Project Name: 
// Target Devices: spartan6
// Tool versions: 
// Description: 
//   The memif module reads the VRAM via the read port linearly through the whole
//   framebuffer, and writes the VRAM via the write port at the same time.
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module memif(
    // Clock and reset
    input  wire         clk_ddr,
    input  wire         clk_ddr_locked,
    output wire         clk_mif,
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
    input  wire         vsync,
    // Pixel output interface
    output wire [63:0]  pix_read,
    output wire         pix_read_valid,
    input  wire         pix_read_ready,
    // Pixel input interface
    input  wire [63:0]  pix_write,
    input  wire         pix_write_valid,
    output wire         pix_write_ready
    );

    // Clock for memory interface unit
    wire         ddr_calib_done;

    wire         mig_p0_cmd_en;
    wire [2:0]   mig_p0_cmd_instr;
    wire [5:0]   mig_p0_cmd_bl;
    wire [29:0]  mig_p0_cmd_byte_addr;
    wire         mig_p0_cmd_full;
    wire         mig_p0_wr_en;
    wire [7:0]   mig_p0_wr_mask;
    wire [63:0]  mig_p0_wr_data;
    wire         mig_p0_wr_full;
    wire [6:0]   mig_p0_wr_count;
    wire         mig_p0_rd_en;
    wire [63:0]  mig_p0_rd_data;
    wire         mig_p0_rd_empty;
    wire [6:0]   mig_p0_rd_count;

    wire         mig_p1_cmd_en;
    wire [2:0]   mig_p1_cmd_instr;
    wire [5:0]   mig_p1_cmd_bl;
    wire [29:0]  mig_p1_cmd_byte_addr;
    wire         mig_p1_cmd_full;
    wire         mig_p1_wr_en;
    wire [7:0]   mig_p1_wr_mask;
    wire [63:0]  mig_p1_wr_data;
    wire         mig_p1_wr_full;
    wire [6:0]   mig_p1_wr_count;
    wire         mig_p1_rd_en;
    wire [63:0]  mig_p1_rd_data;
    wire         mig_p1_rd_empty;
    wire [6:0]   mig_p1_rd_count;

    s6_ddr3 # (
        .C3_P0_MASK_SIZE(8),
        .C3_P0_DATA_PORT_SIZE(64),
        .C3_P1_MASK_SIZE(8),
        .C3_P1_DATA_PORT_SIZE(64),
        .DEBUG_EN(0),
        .C3_MEMCLK_PERIOD(3000),
        .C3_CALIB_SOFT_IP("TRUE"),
        .C3_SIMULATION("FALSE"),
        .C3_RST_ACT_LOW(0),
        .C3_INPUT_CLK_TYPE("SINGLE_ENDED"),
        .C3_MEM_ADDR_ORDER("ROW_BANK_COLUMN"),
        .C3_NUM_DQ_PINS(16),
        .C3_MEM_ADDR_WIDTH(13),
        .C3_MEM_BANKADDR_WIDTH(3)
    )
    s6_ddr3 (
        .c3_sys_clk             (clk_ddr),
        .c3_sys_rst_n           (clk_ddr_locked),

        .mcb3_dram_dq           (DDR_DQ),
        .mcb3_dram_a            (DDR_A),
        .mcb3_dram_ba           (DDR_BA),
        .mcb3_dram_ras_n        (DDR_RAS_N),
        .mcb3_dram_cas_n        (DDR_CAS_N),
        .mcb3_dram_we_n         (DDR_WE_N),
        .mcb3_dram_odt          (DDR_ODT),
        .mcb3_dram_cke          (DDR_CKE),
        .mcb3_dram_ck           (DDR_CK_P),
        .mcb3_dram_ck_n         (DDR_CK_N),
        .mcb3_dram_dqs          (DDR_LDQS_P),
        .mcb3_dram_dqs_n        (DDR_LDQS_N),
        .mcb3_dram_udqs         (DDR_UDQS_P),
        .mcb3_dram_udqs_n       (DDR_UDQS_N),
        .mcb3_dram_udm          (DDR_UDM),
        .mcb3_dram_dm           (DDR_LDM),
        .mcb3_dram_reset_n      (DDR_RESET_N),
        .c3_clk0		        (clk_mif),
        .c3_rst0		        (sys_rst),
        .c3_calib_done          (ddr_calib_done),
        .mcb3_rzq               (DDR_RZQ),
        .mcb3_zio               (DDR_ZIO),
        .c3_p0_cmd_clk          (clk_mif),
        .c3_p0_cmd_en           (mig_p0_cmd_en),
        .c3_p0_cmd_instr        (mig_p0_cmd_instr),
        .c3_p0_cmd_bl           (mig_p0_cmd_bl),
        .c3_p0_cmd_byte_addr    (mig_p0_cmd_byte_addr),
        .c3_p0_cmd_empty        (),
        .c3_p0_cmd_full         (mig_p0_cmd_full),
        .c3_p0_wr_clk           (clk_mif),
        .c3_p0_wr_en            (mig_p0_wr_en),
        .c3_p0_wr_mask          (mig_p0_wr_mask),
        .c3_p0_wr_data          (mig_p0_wr_data),
        .c3_p0_wr_full          (mig_p0_wr_full),
        .c3_p0_wr_empty         (),
        .c3_p0_wr_count         (mig_p0_wr_count),
        .c3_p0_wr_underrun      (),
        .c3_p0_wr_error         (),
        .c3_p0_rd_clk           (clk_mif),
        .c3_p0_rd_en            (mig_p0_rd_en),
        .c3_p0_rd_data          (mig_p0_rd_data),
        .c3_p0_rd_full          (),
        .c3_p0_rd_empty         (mig_p0_rd_empty),
        .c3_p0_rd_count         (mig_p0_rd_count),
        .c3_p0_rd_overflow      (),
        .c3_p0_rd_error         (),
        .c3_p1_cmd_clk          (clk_mif),
        .c3_p1_cmd_en           (mig_p1_cmd_en),
        .c3_p1_cmd_instr        (mig_p1_cmd_instr),
        .c3_p1_cmd_bl           (mig_p1_cmd_bl),
        .c3_p1_cmd_byte_addr    (mig_p1_cmd_byte_addr),
        .c3_p1_cmd_empty        (),
        .c3_p1_cmd_full         (mig_p1_cmd_full),
        .c3_p1_wr_clk           (clk_mif),
        .c3_p1_wr_en            (mig_p1_wr_en),
        .c3_p1_wr_mask          (mig_p1_wr_mask),
        .c3_p1_wr_data          (mig_p1_wr_data),
        .c3_p1_wr_full          (mig_p1_wr_full),
        .c3_p1_wr_empty         (),
        .c3_p1_wr_count         (mig_p1_wr_count),
        .c3_p1_wr_underrun      (),
        .c3_p1_wr_error         (),
        .c3_p1_rd_clk           (clk_mif),
        .c3_p1_rd_en            (mig_p1_rd_en),
        .c3_p1_rd_data          (mig_p1_rd_data),
        .c3_p1_rd_full          (),
        .c3_p1_rd_empty         (mig_p1_rd_empty),
        .c3_p1_rd_count         (mig_p1_rd_count),
        .c3_p1_rd_overflow      (),
        .c3_p1_rd_error         ()
    );

endmodule
