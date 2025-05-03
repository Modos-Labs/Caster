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
// top.v
// Glider top-level
`default_nettype none
`timescale 1ns / 1ps

module top(
    // Global clock input
    input wire CLK_IN,
    // DDR3/MCB interface
    inout wire [15:0] DDR_DQ,
    output wire [12:0] DDR_A,
    output wire [2:0] DDR_BA,
    output wire DDR_RAS_N,
    output wire DDR_CAS_N,
    output wire DDR_WE_N,
    output wire DDR_ODT,
    output wire DDR_RESET_N,
    output wire DDR_CKE,
    output wire DDR_LDM,
    output wire DDR_UDM,
    inout wire DDR_UDQS_P,
    inout wire DDR_UDQS_N,
    inout wire DDR_LDQS_P,
    inout wire DDR_LDQS_N,
    output wire DDR_CK_P,
    output wire DDR_CK_N,
    inout wire DDR_RZQ,
    inout wire DDR_ZIO,
    // EPD interface
    output wire EPD_GDOE,
    output wire EPD_GDCLK,
    output wire EPD_GDSP,
    output wire EPD_SDCLK,
    output wire EPD_SDLE,
    output wire EPD_SDOE,
    output wire [15:0] EPD_SD,
    output wire EPD_SDCE0,
    // LVDS interface
    input wire LVDS_ODD_CK_P,
    input wire LVDS_ODD_CK_N,
    input wire [2:0] LVDS_ODD_P,
    input wire [2:0] LVDS_ODD_N,
    input wire [2:0] LVDS_EVEN_P,
    input wire [2:0] LVDS_EVEN_N,   
    input wire DPI_PCLK,
    input wire DPI_DE,
    input wire DPI_VSYNC,
    input wire DPI_HSYNC,
    input wire [17:0] DPI_PIXEL,
    // CSR interface
    input wire SPI_CS,
    input wire SPI_SCK,
    input wire SPI_MOSI,
    output wire SPI_MISO,
    // DEBUG
    output wire LED
    );
    
    parameter COLORMODE = "MONO";
    
    parameter SIMULATION = "FALSE";
    parameter CALIB_SOFT_IP = "TRUE";
    parameter CLK_SOURCE = "DCM"; // Possible values: DDR, FPD, DCM
    // Remember to change clock multiplier in DDR3 unit
    // 2 for DCM, 8 for FPD, 20 for DDR

    // System clocking
    wire clk_sys;
    wire sys_rst;
    
    wire clk_ddr;
    wire mif_rst;
    
    wire clk_epdc;
    // For compatibility with r0.12 boards
    wire dcm_locked;
    sysclock sysclock(
        // Clock in ports
        .clk_in(CLK_IN),
        // Clock out ports
        .clk_ddr(clk_ddr),
        .clk_sys(clk_sys),
        // Status and control signals
        .reset(1'b0),
        .locked(dcm_locked)
    );
    
    wire c3_sys_rst = !dcm_locked;
    assign mif_rst = c3_sys_rst;

/*
    reg c3_sys_rst = 1'b1;
    always @(posedge clk_sys) begin
        c3_sys_rst <= 1'b0;
    end
    
    IBUFG clkin1_buf (
        .O (clk_sys),
        .I (CLK_IN)
    );
    assign clk_ddr = clk_sys;
    assign mif_rst = c3_sys_rst;
*/

    // Global frame trigger & control
    wire b_trigger;
    wire global_en;
    wire [23:0] frame_bytes_memif;

    // Video input
    wire vin_vsync;
    wire [31:0] vin_pixel;
    wire vin_valid;
    wire vin_ready;
    wire [7:0] debug;
    vin #(
        .COLORMODE(COLORMODE)
    ) vin(
        .rst(sys_rst),
        // DPI signals
        .dpi_vsync(DPI_VSYNC),
        .dpi_hsync(DPI_HSYNC),
        .dpi_pclk(DPI_PCLK),
        .dpi_de(DPI_DE),
        .dpi_pixel(DPI_PIXEL),
        // FPD-Link signals
        .fpdlink_cp(LVDS_ODD_CK_P),
        .fpdlink_cn(LVDS_ODD_CK_N),
        .fpdlink_odd_p(LVDS_ODD_P),
        .fpdlink_odd_n(LVDS_ODD_N),
        .fpdlink_even_p(LVDS_EVEN_P),
        .fpdlink_even_n(LVDS_EVEN_N),
        // Output
        .v_vsync(vin_vsync),
        .v_pclk(clk_epdc),
        .v_pixel(vin_pixel),
        .v_valid(vin_valid),
        .v_ready(vin_ready),
        .debug(debug)
    );

    // Hardware DDR controller
    wire clk_mif;
    wire ddr_calib_done;
    wire mig_cmd_en;
    wire [2:0] mig_cmd_instr;
    wire [5:0] mig_cmd_bl;
    wire [29:0] mig_cmd_byte_addr;
    wire mig_cmd_empty;
    wire mig_cmd_full;
    wire mig_wr_en;
    wire [15:0] mig_wr_mask;
    wire [127:0] mig_wr_data;
    wire mig_wr_empty;
    wire mig_wr_full;
    wire [6:0] mig_wr_count;
    wire mig_wr_underrun;
    wire mig_rd_en;
    wire [127:0] mig_rd_data;
    wire mig_rd_full;
    wire mig_rd_empty;
    wire mig_rd_overflow;
    wire [6:0] mig_rd_count;
    wire mig_error;

    mig_wrapper #(
        .SIMULATION(SIMULATION),
        .CALIB_SOFT_IP(CALIB_SOFT_IP)
    ) mig_wrapper(
        // Clock and reset
        .clk_sys(clk_ddr),
        .clk_mif(clk_mif),
        .rst_in(mif_rst),
        .sys_rst(sys_rst),
        // DDR ram interface
        .ddr_dq(DDR_DQ),
        .ddr_a(DDR_A),
        .ddr_ba(DDR_BA),
        .ddr_ras_n(DDR_RAS_N),
        .ddr_cas_n(DDR_CAS_N),
        .ddr_we_n(DDR_WE_N),
        .ddr_odt(DDR_ODT),
        .ddr_reset_n(DDR_RESET_N),
        .ddr_cke(DDR_CKE),
        .ddr_ldm(DDR_LDM),
        .ddr_udm(DDR_UDM),
        .ddr_udqs_p(DDR_UDQS_P),
        .ddr_udqs_n(DDR_UDQS_N),
        .ddr_ldqs_p(DDR_LDQS_P),
        .ddr_ldqs_n(DDR_LDQS_N),
        .ddr_ck_p(DDR_CK_P),
        .ddr_ck_n(DDR_CK_N),
        .ddr_rzq(DDR_RZQ),
        .ddr_zio(DDR_ZIO),
        // Control interface
        .ddr_calib_done(ddr_calib_done),
        // User interface
        .mig_cmd_en(mig_cmd_en),
        .mig_cmd_instr(mig_cmd_instr),
        .mig_cmd_bl(mig_cmd_bl),
        .mig_cmd_byte_addr(mig_cmd_byte_addr),
        .mig_cmd_empty(mig_cmd_empty),
        .mig_cmd_full(mig_cmd_full),
        .mig_wr_en(mig_wr_en),
        .mig_wr_mask(mig_wr_mask),
        .mig_wr_data(mig_wr_data),
        .mig_wr_empty(mig_wr_empty),
        .mig_wr_full(mig_wr_full),
        .mig_wr_count(mig_wr_count),
        .mig_wr_underrun(mig_wr_underrun),
        .mig_rd_en(mig_rd_en),
        .mig_rd_data(mig_rd_data),
        .mig_rd_full(mig_rd_full),
        .mig_rd_empty(mig_rd_empty),
        .mig_rd_overflow(mig_rd_overflow),
        .mig_rd_count(mig_rd_count),
        // Error
        .error(mig_error)
    );

    wire mig_error_epdc;
    mu_dsync mig_error_sync (
        .iclk(clk_mif),
        .in(mig_error),
        .oclk(clk_epdc),
        .out(mig_error_epdc)
    );

    // VRAM interface
    wire memif_enable;
    wire memif_trigger;
    wire pix_read_valid;
    wire pix_read_ready;
    wire [127:0] pix_read;
    wire pix_write_valid;
    wire pix_write_ready;
    wire [127:0] pix_write;
    
    wire memif_error;

    memif memif(
        // Clock and reset
        .clk(clk_mif),
        .rst(sys_rst),
        // Control
        .enable(memif_enable),
        .vsync(memif_trigger),
        .frame_bytes(frame_bytes_memif),
        // Pixel output interface
        .pix_read(pix_read),
        .pix_read_valid(pix_read_valid),
        .pix_read_ready(pix_read_ready),
        // Pixel input interface
        .pix_write(pix_write),
        .pix_write_valid(pix_write_valid),
        .pix_write_ready(pix_write_ready),
        // To MIG
        .mig_cmd_en(mig_cmd_en),
        .mig_cmd_instr(mig_cmd_instr),
        .mig_cmd_bl(mig_cmd_bl),
        .mig_cmd_byte_addr(mig_cmd_byte_addr),
        .mig_cmd_empty(mig_cmd_empty),
        .mig_cmd_full(mig_cmd_full),
        .mig_wr_en(mig_wr_en),
        .mig_wr_mask(mig_wr_mask),
        .mig_wr_data(mig_wr_data),
        .mig_wr_empty(mig_wr_empty),
        .mig_wr_full(mig_wr_full),
        .mig_wr_count(mig_wr_count),
        .mig_wr_underrun(mig_wr_underrun),
        .mig_rd_en(mig_rd_en),
        .mig_rd_data(mig_rd_data),
        .mig_rd_full(mig_rd_full),
        .mig_rd_empty(mig_rd_empty),
        .mig_rd_overflow(mig_rd_overflow),
        .mig_rd_count(mig_rd_count),
        // Error
        .error(memif_error)
    );

    mu_dsync memif_vs_sync (
        .iclk(clk_epdc),
        .in(b_trigger),
        .oclk(clk_mif),
        .out(memif_trigger)
    );

    wire [23:0] frame_bytes;
    mu_dbsync #(.W(24)) memif_fbytes_sync (
        .iclk(clk_epdc),
        .in(frame_bytes),
        .oclk(clk_mif),
        .out(frame_bytes_memif)
    );

    wire memif_error_epdc;
    mu_dsync memif_error_sync (
        .iclk(clk_mif),
        .in(memif_error),
        .oclk(clk_epdc),
        .out(memif_error_epdc)
    );

    wire ddr_calib_done_epdc;
    mu_dsync ddr_calib_done_sync (
        .iclk(clk_mif),
        .in(ddr_calib_done),
        .oclk(clk_epdc),
        .out(ddr_calib_done_epdc)
    );

    mu_dsync memif_en_sync (
        .iclk(clk_epdc),
        .in(ddr_calib_done_epdc && global_en),
        .oclk(clk_mif),
        .out(memif_enable)
    );

    // VRAM FIFOs
    // BI is from VRAM to EPDC
    wire bi_fifo_full;
    wire bi_fifo_empty;
    wire bi_fifo_overflow;
    wire [63:0] bi_pixel;
    wire bi_valid;
    wire bi_ready;
    bi_fifo bi_fifo(
        .rst(sys_rst), // input rst, reset at each frame
        // Write port
        .wr_clk(clk_mif),
        .din(pix_read),
        .wr_en(pix_read_valid),
        .full(bi_fifo_full),
        // Read port
        .rd_clk(clk_epdc),
        .rd_en(bi_ready),
        .dout(bi_pixel),
        .empty(bi_fifo_empty)
    );
    assign pix_read_ready = !bi_fifo_full;
    assign bi_valid = !bi_fifo_empty;

    // BO is from EPDC to VRAM
    wire bo_fifo_full;
    wire bo_fifo_empty;
    wire [63:0] bo_pixel;
    wire bo_valid;
    bo_fifo bo_fifo(
        .rst(sys_rst), // input rst, reset at each frame
        // Write port
        .wr_clk(clk_epdc),
        .din(bo_pixel),
        .wr_en(bo_valid),
        .full(bo_fifo_full),
        // Read port
        .rd_clk(clk_mif),
        .rd_en(pix_write_ready),
        .dout(pix_write),
        .empty(bo_fifo_empty)
    );
    assign pix_write_valid = !bo_fifo_empty;
    
    // EPD controller
    wire sys_ready = ddr_calib_done_epdc;

    wire spi_ncs;
    wire spi_sck;
    wire spi_mosi;
    wire spi_miso;
    mu_dsync spi_cs_sync (
        .iclk(1'b0), // external
        .in(!SPI_CS),
        .oclk(clk_epdc),
        .out(spi_ncs)
    );
    wire spi_cs = !spi_ncs;

    mu_dsync spi_sck_sync (
        .iclk(1'b0), // external
        .in(SPI_SCK),
        .oclk(clk_epdc),
        .out(spi_sck)
    );

    mu_dsync spi_mosi_sync (
        .iclk(1'b0), // external
        .in(SPI_MOSI),
        .oclk(clk_epdc),
        .out(spi_mosi)
    );
    
    wire [1:0] dbg_scan_state;
    wire [10:0] dbg_scan_h_cnt;
    wire [10:0] dbg_scan_v_cnt;
    wire dbg_spi_req_wen;
    wire [7:0] dbg_spi_req_addr;
    wire [7:0] dbg_spi_req_wdata;

    reg epdc_rst_sync = 1'b1;
    reg epdc_rst = 1'b1;
    always @(posedge clk_epdc) begin
        epdc_rst <= epdc_rst_sync;
        epdc_rst_sync <= sys_rst;
    end


    wire [15:0] epd_sd_caster;
    caster #(
        .SIMULATION(SIMULATION),
        .COLORMODE(COLORMODE)
    )
    caster(
        .clk(clk_epdc),
        .rst(epdc_rst),
        // Video input
        .vin_vsync(vin_vsync),
        .vin_pixel(vin_pixel),
        .vin_valid(vin_valid),
        .vin_ready(vin_ready),
        // Framebuffer input
        .bi_pixel(bi_pixel),
        .bi_valid(bi_valid),
        .bi_ready(bi_ready),
        // Framebuffer output
        .bo_pixel(bo_pixel),
        .bo_valid(bo_valid),
        // EPD signals
        .epd_gdoe(EPD_GDOE),
        .epd_gdclk(EPD_GDCLK),
        .epd_gdsp(EPD_GDSP),
        .epd_sdclk(EPD_SDCLK),
        .epd_sdle(EPD_SDLE),
        .epd_sdoe(EPD_SDOE),
        .epd_sd(epd_sd_caster),
        .epd_sdce0(EPD_SDCE0),
        // CSR interface
        .spi_cs(spi_cs),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(SPI_MISO),
        // Control / status
        .b_trigger(b_trigger),
        .sys_ready(sys_ready),
        .mig_error(mig_error_epdc),
        .mif_error(memif_error_epdc),
        .frame_bytes(frame_bytes),
        .global_en(global_en),
        // Debugging
        .dbg_scan_state(dbg_scan_state),
        .dbg_scan_h_cnt(dbg_scan_h_cnt),
        .dbg_scan_v_cnt(dbg_scan_v_cnt),
        .dbg_spi_req_wen(dbg_spi_req_wen),
        .dbg_spi_req_addr(dbg_spi_req_addr),
        .dbg_spi_req_wdata(dbg_spi_req_wdata)
    );
    
//    assign EPD_SD[7:0] = epd_sd_caster[7:0];
//    assign EPD_SD[15:8] = debug;
    assign EPD_SD = epd_sd_caster;
    // Debug
    wire [35:0] chipscope_control0;
    chipscope_icon icon (
        .CONTROL0(chipscope_control0) // INOUT BUS [35:0]
    );
    
    wire [31:0] ila_signals;
    chipscope_ila ila (
        .CONTROL(chipscope_control0), // INOUT BUS [35:0]
        .CLK(clk_epdc),
        .TRIG0(ila_signals)
    );

//    assign ila_signals[0] = c3_sys_rst;
//    assign ila_signals[1] = ddr_calib_done;
//    assign ila_signals[2] = sys_rst;
//    assign ila_signals[3] = memif_error;
//    // assign ila_signals[4] = v_vs;
//    // assign ila_signals[5] = v_hs;
//    // assign ila_signals[6] = v_de;
////    assign ila_signals[7] = v_pclk;
////    assign ila_signals[8] = dbg_hsync;
////    assign ila_signals[9] = dbg_vsync;
////    assign ila_signals[10] = dbg_de;
////    assign ila_signals[11] = dbg_pll_lck;
//
//    //assign ila_signals[6:4] = debug[2:0];
//
//   assign ila_signals[7] = vin_ready; // vi_fifo_rd_en
//   assign ila_signals[8] = vin_valid; // vi_fifo_rd not empty
//   assign ila_signals[9] = memif_enable;
//   assign ila_signals[10] = memif_trigger;
//   assign ila_signals[11] = pix_read_valid; // bi_fifo_wr_en
//   assign ila_signals[12] = bi_fifo_full;
//   assign ila_signals[13] = bi_ready;
//   assign ila_signals[14] = bi_valid; // bi_fifo_rd not empty
//   assign ila_signals[15] = bo_valid;
//   assign ila_signals[16] = bo_fifo_full;
//   assign ila_signals[17] = pix_write_ready; // bo_fifo_rd_en
//   assign ila_signals[18] = bo_fifo_empty;
////   //assign ila_signals[19] = dbg_scan_state[0];
//   assign ila_signals[19] = dbg_scan_state[1];
////   //assign ila_signals[15] = vin_vsync;
//   assign ila_signals[20] = vin_pixel[15]; // sneak peak of pixel
//
//    assign ila_signals[4] = spi_cs;
//    assign ila_signals[5] = spi_sck;
//    assign ila_signals[6] = spi_mosi;
//    
//    assign ila_signals[23:21] = 3'd0; 
////
////    assign ila_signals[7] = dbg_spi_req_wen;
////    assign ila_signals[15:8] = dbg_spi_req_addr;
////    assign ila_signals[23:16] = dbg_spi_req_wdata;
////    
////    assign ila_signals[31:24] = dbg_scan_v_cnt[7:0];
////    assign ila_signals[31:21] = dbg_scan_v_cnt;
//    assign ila_signals[31:24] = debug;


    assign ila_signals[0] = vin_vsync;
    assign ila_signals[1] = vin_valid;
    assign ila_signals[2] = vin_ready;
    assign ila_signals[31:3] = vin_pixel[31:3];

    assign LED = |(epd_sd_caster[7:0]);

endmodule
`default_nettype wire
