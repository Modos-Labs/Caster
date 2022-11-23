`default_nettype none
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
    input  wire         vsync,
    // Pixel output interface
    output wire [127:0] pix_read,
    output wire         pix_read_valid,
    input  wire         pix_read_ready,
    // Pixel input interface
    input  wire [127:0] pix_write,
    input  wire         pix_write_valid,
    output wire         pix_write_ready,
    // Debug output
    output wire         error,
    output wire         cmp_data_valid
    );
    
    parameter SIMULATION = "FALSE";
    parameter CALIB_SOFT_IP = "TRUE";

    parameter MAX_ADDRESS = 1600*1200*2; // UXGA, 16 bit per pixel

    localparam BYTE_PER_WORD = 16; // 128 bit bus
    localparam BURST_LENGTH = 16; // Should be at least 2
    localparam BYTE_PER_CMD = BYTE_PER_WORD * BURST_LENGTH;
    
    reg          mig_p0_cmd_en;
    reg  [2:0]   mig_p0_cmd_instr;
    wire [5:0]   mig_p0_cmd_bl;
    reg  [29:0]  mig_p0_cmd_byte_addr;
    wire         mig_p0_cmd_full;
    reg          mig_p0_wr_en;
    wire [15:0]  mig_p0_wr_mask;
    wire [127:0] mig_p0_wr_data;
    wire         mig_p0_wr_full;
    wire [6:0]   mig_p0_wr_count; // unused
    wire         mig_p0_rd_en;
    wire [127:0] mig_p0_rd_data;
    wire         mig_p0_rd_empty;
    wire [6:0]   mig_p0_rd_count; // unused
    
    /*wire         mig_p0_cmd_en;
    wire [2:0]   mig_p0_cmd_instr;
    wire [5:0]   mig_p0_cmd_bl;
    wire [29:0]  mig_p0_cmd_byte_addr;
    wire         mig_p0_cmd_full;
    wire         mig_p0_wr_en;
    wire [15:0]  mig_p0_wr_mask;
    wire [127:0] mig_p0_wr_data;
    wire         mig_p0_wr_full;
    wire [6:0]   mig_p0_wr_count;
    wire         mig_p0_rd_en;
    wire [127:0] mig_p0_rd_data;
    wire         mig_p0_rd_empty;
    wire [6:0]   mig_p0_rd_count;*/

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
        .c3_p0_rd_error         ()
    );

    /*parameter C3_HW_TESTING           = "FALSE";
    parameter C3_NUM_DQ_PINS          = 16;
    localparam C3_MEM_BURST_LEN        = 8;
    localparam C3_MEM_NUM_COL_BITS     = 10;
    localparam C3_SMALL_DEVICE         = "FALSE";
    localparam C3_PORT_ENABLE              = 6'b000001;
    localparam C3_P0_PORT_MODE             =  "BI_MODE";
    localparam C3_P1_PORT_MODE             =  "NONE";
    localparam C3_P2_PORT_MODE             =  "NONE";
    localparam C3_P3_PORT_MODE             =  "NONE";
    localparam C3_P4_PORT_MODE             =  "NONE";
    localparam C3_P5_PORT_MODE             =  "NONE";

    parameter C3_P0_MASK_SIZE           = 16;
    parameter C3_P0_DATA_PORT_SIZE      = 128;
   localparam C3_p0_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000400;
   localparam C3_p0_DATA_MODE                       = 4'b0010;
   localparam C3_p0_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h02ffffff:32'h000007ff;
   localparam C3_p0_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hfc000000:32'hfffff800;
   localparam C3_p0_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000400;
   localparam C3_p1_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h03000000:32'h00000400;
   localparam C3_p1_DATA_MODE                       = 4'b0010;
   localparam C3_p1_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h04ffffff:32'h000005ff;
   localparam C3_p1_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hf8000000:32'hfffff000;
   localparam C3_p1_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h03000000:32'h00000400;
   localparam C3_p2_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000600;
   localparam C3_p2_DATA_MODE                       = 4'b0010;
   localparam C3_p2_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h06ffffff:32'h000007ff;
   localparam C3_p2_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hf8000000:32'hfffff000;
   localparam C3_p2_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000600;
   localparam C3_p3_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000700;
   localparam C3_p3_DATA_MODE                       = 4'b0010;
   localparam C3_p3_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h02ffffff:32'h000008ff;
   localparam C3_p3_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hfc000000:32'hfffff000;
   localparam C3_p3_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000700;
   localparam C3_p4_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000500;
   localparam C3_p4_DATA_MODE                       = 4'b0010;
   localparam C3_p4_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h06ffffff:32'h000006ff;
   localparam C3_p4_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hf8000000:32'hfffff800;
   localparam C3_p4_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000500;
   localparam C3_p5_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000500;
   localparam C3_p5_DATA_MODE                       = 4'b0010;
   localparam C3_p5_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h06ffffff:32'h000006ff;
   localparam C3_p5_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hf8000000:32'hfffff800;
   localparam C3_p5_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000500;

    wire c3_error;
    wire                              c3_cmp_error;
    wire                              c3_cmp_data_valid;
    wire  [31:0]                      c3_cmp_data;
    wire                              c3_vio_modify_enable;
    wire  [2:0]                      c3_vio_data_mode_value;
    wire  [2:0]                      c3_vio_addr_mode_value;
    wire  [319:0]                                 c3_p0_error_status;
    wire  [319:0]                                 c3_p1_error_status;
    wire  [127:0]                                 c3_p2_error_status;
    wire  [127:0]                                 c3_p3_error_status;
    wire  [127:0]                                 c3_p4_error_status;
    wire  [127:0]                                 c3_p5_error_status;
    
    memc_tb_top #
    (
        .C_SIMULATION                   (SIMULATION),
        .C_NUM_DQ_PINS                  (C3_NUM_DQ_PINS),
        .C_MEM_BURST_LEN                (C3_MEM_BURST_LEN),
        .C_MEM_NUM_COL_BITS             (C3_MEM_NUM_COL_BITS),
        .C_SMALL_DEVICE                 (C3_SMALL_DEVICE),

        // The following parameters from C_PORT_ENABLE to C_P5_PORT_MODE are introduced
    // to handle the static instances of all the six traffic generators inside the
    // memc_tb_top module. 
        .C_PORT_ENABLE                  (C3_PORT_ENABLE),
        .C_P0_MASK_SIZE                 (C3_P0_MASK_SIZE),
        .C_P0_DATA_PORT_SIZE            (C3_P0_DATA_PORT_SIZE),
        .C_P0_PORT_MODE                 (C3_P0_PORT_MODE),  
        .C_P1_PORT_MODE                 (C3_P1_PORT_MODE),  
        .C_P2_PORT_MODE                 (C3_P2_PORT_MODE),  
        .C_P3_PORT_MODE                 (C3_P3_PORT_MODE),
        .C_P4_PORT_MODE                 (C3_P4_PORT_MODE),
        .C_P5_PORT_MODE                 (C3_P5_PORT_MODE),

        .C_p0_BEGIN_ADDRESS             (C3_p0_BEGIN_ADDRESS),
        .C_p0_DATA_MODE                 (C3_p0_DATA_MODE),
        .C_p0_END_ADDRESS               (C3_p0_END_ADDRESS),
        .C_p0_PRBS_EADDR_MASK_POS       (C3_p0_PRBS_EADDR_MASK_POS),
        .C_p0_PRBS_SADDR_MASK_POS       (C3_p0_PRBS_SADDR_MASK_POS),
        .C_p1_BEGIN_ADDRESS             (C3_p1_BEGIN_ADDRESS),
        .C_p1_DATA_MODE                 (C3_p1_DATA_MODE),
        .C_p1_END_ADDRESS               (C3_p1_END_ADDRESS),
        .C_p1_PRBS_EADDR_MASK_POS       (C3_p1_PRBS_EADDR_MASK_POS),
        .C_p1_PRBS_SADDR_MASK_POS       (C3_p1_PRBS_SADDR_MASK_POS),
        .C_p2_BEGIN_ADDRESS             (C3_p2_BEGIN_ADDRESS),
        .C_p2_DATA_MODE                 (C3_p2_DATA_MODE),
        .C_p2_END_ADDRESS               (C3_p2_END_ADDRESS),
        .C_p2_PRBS_EADDR_MASK_POS       (C3_p2_PRBS_EADDR_MASK_POS),
        .C_p2_PRBS_SADDR_MASK_POS       (C3_p2_PRBS_SADDR_MASK_POS),
        .C_p3_BEGIN_ADDRESS             (C3_p3_BEGIN_ADDRESS),
        .C_p3_DATA_MODE                 (C3_p3_DATA_MODE),
        .C_p3_END_ADDRESS               (C3_p3_END_ADDRESS),
        .C_p3_PRBS_EADDR_MASK_POS       (C3_p3_PRBS_EADDR_MASK_POS),
        .C_p3_PRBS_SADDR_MASK_POS       (C3_p3_PRBS_SADDR_MASK_POS),
        .C_p4_BEGIN_ADDRESS             (C3_p4_BEGIN_ADDRESS),
        .C_p4_DATA_MODE                 (C3_p4_DATA_MODE),
        .C_p4_END_ADDRESS               (C3_p4_END_ADDRESS),
        .C_p4_PRBS_EADDR_MASK_POS       (C3_p4_PRBS_EADDR_MASK_POS),
        .C_p4_PRBS_SADDR_MASK_POS       (C3_p4_PRBS_SADDR_MASK_POS),
        .C_p5_BEGIN_ADDRESS             (C3_p5_BEGIN_ADDRESS),
        .C_p5_DATA_MODE                 (C3_p5_DATA_MODE),
        .C_p5_END_ADDRESS               (C3_p5_END_ADDRESS),
        .C_p5_PRBS_EADDR_MASK_POS       (C3_p5_PRBS_EADDR_MASK_POS),
        .C_p5_PRBS_SADDR_MASK_POS       (C3_p5_PRBS_SADDR_MASK_POS)
        )
    memc3_tb_top_inst
    (
        .error			                 (c3_error),
        .calib_done			             (ddr_calib_done), 
        .clk0			                 (clk_mif),
        .rst0			                 (sys_rst),
        .cmp_error			             (c3_cmp_error),
        .cmp_data_valid  	             (c3_cmp_data_valid),
        .cmp_data			             (c3_cmp_data),
        .vio_modify_enable               (c3_vio_modify_enable),
        .vio_data_mode_value             (c3_vio_data_mode_value),
        .vio_addr_mode_value             (c3_vio_addr_mode_value),
        .p0_error_status	             (c3_p0_error_status),
        .p1_error_status	             (c3_p1_error_status),
        .p2_error_status	             (c3_p2_error_status),
        .p3_error_status	             (c3_p3_error_status),
        .p4_error_status	             (c3_p4_error_status),
        .p5_error_status	             (c3_p5_error_status),

    // The following port map shows that all the memory controller ports are connected
    // to the test bench top. However, a traffic generator can be connected to the 
    // corresponding port only if the port is enabled, whose information can be obtained
    // from the parameters C_PORT_ENABLE. 

        // User Port-0 command interface will be active only when the port is enabled in 
        // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
        .p0_mcb_cmd_en                  (mig_p0_cmd_en),
        .p0_mcb_cmd_instr               (mig_p0_cmd_instr),
        .p0_mcb_cmd_bl                  (mig_p0_cmd_bl),
        .p0_mcb_cmd_addr                (mig_p0_cmd_byte_addr),
        .p0_mcb_cmd_full                (mig_p0_cmd_full),
        // User Port-0 data write interface will be active only when the port is enabled in
        // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
        .p0_mcb_wr_en                   (mig_p0_wr_en),
        .p0_mcb_wr_mask                 (mig_p0_wr_mask),
        .p0_mcb_wr_data                 (mig_p0_wr_data),
        .p0_mcb_wr_full                 (mig_p0_wr_full),
        .p0_mcb_wr_fifo_counts          (mig_p0_wr_count),
        // User Port-0 data read interface will be active only when the port is enabled in
        // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
        .p0_mcb_rd_en                   (mig_p0_rd_en),
        .p0_mcb_rd_data                 (mig_p0_rd_data),
        .p0_mcb_rd_empty                (mig_p0_rd_empty),
        .p0_mcb_rd_fifo_counts          (mig_p0_rd_count),

        // User Port-1 command interface will be active only when the port is enabled in 
        // the port configurations Config-1, Config-2, Config-3 and Config-4
        .p1_mcb_cmd_en                  (),
        .p1_mcb_cmd_instr               (),
        .p1_mcb_cmd_bl                  (),
        .p1_mcb_cmd_addr                (),
        .p1_mcb_cmd_full                (),
        // User Port-1 data write interface will be active only when the port is enabled in 
        // the port configurations Config-1, Config-2, Config-3 and Config-4
        .p1_mcb_wr_en                   (),
        .p1_mcb_wr_mask                 (),
        .p1_mcb_wr_data                 (),
        .p1_mcb_wr_full                 (),
        .p1_mcb_wr_fifo_counts          (),
        // User Port-1 data read interface will be active only when the port is enabled in 
        // the port configurations Config-1, Config-2, Config-3 and Config-4
        .p1_mcb_rd_en                   (),
        .p1_mcb_rd_data                 (),
        .p1_mcb_rd_empty                (),
        .p1_mcb_rd_fifo_counts          (),

        // User Port-2 command interface will be active only when the port is enabled in 
        // the port configurations Config-1, Config-2 and Config-3
        .p2_mcb_cmd_en                  (),
        .p2_mcb_cmd_instr               (),
        .p2_mcb_cmd_bl                  (),
        .p2_mcb_cmd_addr                (),
        .p2_mcb_cmd_full                (),
        // User Port-2 data write interface will be active only when the port is enabled in 
        // the port configurations Config-1 write direction, Config-2 and Config-3
        .p2_mcb_wr_en                   (),
        .p2_mcb_wr_mask                 (),
        .p2_mcb_wr_data                 (),
        .p2_mcb_wr_full                 (),
        .p2_mcb_wr_fifo_counts          (),
        // User Port-2 data read interface will be active only when the port is enabled in 
        // the port configurations Config-1 read direction, Config-2 and Config-3
        .p2_mcb_rd_en                   (),
        .p2_mcb_rd_data                 (),
        .p2_mcb_rd_empty                (),
        .p2_mcb_rd_fifo_counts          (),

        // User Port-3 command interface will be active only when the port is enabled in 
        // the port configurations Config-1 and Config-2
        .p3_mcb_cmd_en                  (),
        .p3_mcb_cmd_instr               (),
        .p3_mcb_cmd_bl                  (),
        .p3_mcb_cmd_addr                (),
        .p3_mcb_cmd_full                (),
        // User Port-3 data write interface will be active only when the port is enabled in 
        // the port configurations Config-1 write direction and Config-2
        .p3_mcb_wr_en                   (),
        .p3_mcb_wr_mask                 (),
        .p3_mcb_wr_data                 (),
        .p3_mcb_wr_full                 (),
        .p3_mcb_wr_fifo_counts          (),
        // User Port-3 data read interface will be active only when the port is enabled in 
        // the port configurations Config-1 read direction and Config-2
        .p3_mcb_rd_en                   (),
        .p3_mcb_rd_data                 (),
        .p3_mcb_rd_empty                (),
        .p3_mcb_rd_fifo_counts          (),

        // User Port-4 command interface will be active only when the port is enabled in 
        // the port configuration Config-1
        .p4_mcb_cmd_en                  (),
        .p4_mcb_cmd_instr               (),
        .p4_mcb_cmd_bl                  (),
        .p4_mcb_cmd_addr                (),
        .p4_mcb_cmd_full                (),
        // User Port-4 data write interface will be active only when the port is enabled in 
        // the port configuration Config-1 write direction
        .p4_mcb_wr_en                   (),
        .p4_mcb_wr_mask                 (),
        .p4_mcb_wr_data                 (),
        .p4_mcb_wr_full                 (),
        .p4_mcb_wr_fifo_counts          (),
        // User Port-4 data read interface will be active only when the port is enabled in 
        // the port configuration Config-1 read direction
        .p4_mcb_rd_en                   (),
        .p4_mcb_rd_data                 (),
        .p4_mcb_rd_empty                (),
        .p4_mcb_rd_fifo_counts          (),

        // User Port-5 command interface will be active only when the port is enabled in 
        // the port configuration Config-1
        .p5_mcb_cmd_en                  (),
        .p5_mcb_cmd_instr               (),
        .p5_mcb_cmd_bl                  (),
        .p5_mcb_cmd_addr                (),
        .p5_mcb_cmd_full                (),
        // User Port-5 data write interface will be active only when the port is enabled in 
        // the port configuration Config-1 write direction
        .p5_mcb_wr_en                   (),
        .p5_mcb_wr_mask                 (),
        .p5_mcb_wr_data                 (),
        .p5_mcb_wr_full                 (),
        .p5_mcb_wr_fifo_counts          (),
        // User Port-5 data read interface will be active only when the port is enabled in 
        // the port configuration Config-1 read direction
        .p5_mcb_rd_en                   (),
        .p5_mcb_rd_data                 (),
        .p5_mcb_rd_empty                (),
        .p5_mcb_rd_fifo_counts          ()
    );

    assign error = c3_error;
    assign cmp_data_valid = c3_cmp_data_valid;*/
    
    // WR state machine
    wire wr_issue_req;
    reg wr_issue_done;

    reg [29:0] wr_byte_address;
    reg [6:0] wr_burst_count;
    reg [2:0] wr_state;

    localparam WR_IDLE = 3'd0;
    localparam WR_PUSH = 3'd1;
    localparam WR_ISSUE = 3'd2;

    wire pix_writing = (!mig_p0_wr_full) && (pix_write_valid);

    always @(posedge clk_mif) begin
        // The WR state machine works as following:
        // Try to fill BURST_LENGTH number of words into WR FIFO
        // Then issue a burst write
        if (sys_rst && !ddr_calib_done) begin
            wr_state <= WR_IDLE;
        end
        else begin
            case (wr_state)
            WR_IDLE: begin
                if (vsync) begin
                    wr_byte_address <= 0;
                    wr_burst_count <= 0;
                    wr_state <= WR_PUSH;
                end
            end
            WR_PUSH: begin
                if (wr_burst_count >= BURST_LENGTH) begin
                    wr_state <= WR_ISSUE;
                    wr_burst_count <= wr_burst_count + pix_writing -
                            BURST_LENGTH;
                end
                else begin
                    wr_burst_count <= wr_burst_count + pix_writing;
                end
            end
            WR_ISSUE: begin
                if (wr_issue_done) begin
                    wr_byte_address <= wr_byte_address + BYTE_PER_CMD;
                    if (wr_byte_address == MAX_ADDRESS - BYTE_PER_CMD) begin
                        wr_state <= WR_IDLE;
                    end
                    else begin
                        wr_state <= WR_PUSH;
                    end
                end
                wr_burst_count <= wr_burst_count + pix_writing;
            end
            endcase
        end
    end

    assign pix_write_ready = pix_writing;
    always @(posedge clk_mif) begin
        mig_p0_wr_en <= pix_writing; // FIFO has 1 cycle RD latency
    end
    assign mig_p0_wr_data = pix_write;
    assign mig_p0_wr_mask = 16'h0000;
    assign wr_issue_req = (wr_state == WR_ISSUE);

    // RD state machine
    wire rd_issue_req;
    reg rd_issue_done;

    reg [29:0] rd_byte_address;
    reg [2:0] rd_state;

    localparam RD_IDLE = 3'd0;
    localparam RD_WAIT1 = 3'd1;
    localparam RD_WAIT2 = 3'd2;
    localparam RD_ISSUE = 3'd3;
    
    always @(posedge clk_mif) begin
        // RD state machine is a bit different:
        // It always tries to issue RD as long as output is not full
        if (sys_rst && !ddr_calib_done) begin
            rd_state <= RD_IDLE;
        end
        else begin
            case (rd_state)
            RD_IDLE: begin
                if (vsync) begin
                    rd_byte_address <= 0;
                    rd_state <= RD_WAIT2;
                end
            end
            RD_WAIT1: begin
                if (!mig_p0_rd_empty) begin
                    rd_state <= RD_WAIT2;
                end
            end
            RD_WAIT2: begin
                if (pix_read_ready && mig_p0_rd_empty) begin
                    rd_state <= RD_ISSUE;
                end
            end
            RD_ISSUE: begin
                if (rd_issue_done) begin
                    rd_byte_address <= rd_byte_address + BYTE_PER_CMD;
                    if (rd_byte_address == MAX_ADDRESS - BYTE_PER_CMD) begin
                        rd_state <= RD_IDLE;
                    end
                    else begin
                        rd_state <= RD_WAIT1;
                    end
                end
            end
            endcase
        end
    end

    wire pix_reading = (!mig_p0_rd_empty) && (pix_read_ready);
    assign mig_p0_rd_en = pix_reading;
    assign pix_read_valid = pix_reading;
    assign pix_read = mig_p0_rd_data;
    assign rd_issue_req = (rd_state == RD_ISSUE);
    
    // It tries to issue RD first, then tries WR. Currently there is no RR
    // It currently issues 1 cmd every 2 cycles.
    reg issue_state;
    localparam ISSUE_WAIT = 1'd0;
    localparam ISSUE_ACT = 1'd1;

    always @(posedge clk_mif) begin
        if (sys_rst && !ddr_calib_done) begin
            mig_p0_cmd_en <= 1'b0;
            issue_state <= ISSUE_WAIT;
            rd_issue_done <= 1'b0;
            wr_issue_done <= 1'b0;
        end
        else begin
            case (issue_state)
            ISSUE_WAIT: begin
                if (!mig_p0_cmd_full) begin
                    if (rd_issue_req) begin
                        mig_p0_cmd_instr <= 3'b001;
                        mig_p0_cmd_byte_addr <= rd_byte_address;
                        mig_p0_cmd_en <= 1'b1;
                        rd_issue_done <= 1'b1;
                        issue_state <= ISSUE_ACT;
                    end
                    else if ((wr_issue_req) &&
                            (wr_byte_address < rd_byte_address)) begin
                        mig_p0_cmd_instr <= 3'b000;
                        mig_p0_cmd_byte_addr <= wr_byte_address;
                        mig_p0_cmd_en <= 1'b1;
                        wr_issue_done <= 1'b1;
                        issue_state <= ISSUE_ACT;
                    end
                end
            end
            ISSUE_ACT: begin
                rd_issue_done <= 1'b0;
                wr_issue_done <= 1'b0;
                mig_p0_cmd_en <= 1'b0;
                issue_state <= ISSUE_WAIT;
            end
            endcase
        end
    end

    assign mig_p0_cmd_bl = BURST_LENGTH - 1;
    
    assign error = 1'b0;
    assign cmp_data_valid = 1'b0;

endmodule
`default_nettype wire
