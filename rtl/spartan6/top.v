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
// top.v
// Glider top-level
`default_nettype none
`timescale 1ns / 1ps

`define INPUT_DVI       // DVI input on Glider DVI input
//`define INPUT_LVDS      // LVDS input on Glider Type-C input
//`define INPUT_INTERNAL	// Internal test feed

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
`ifdef INPUT_LVDS
    // LVDS interface
    input wire LVDS_ODD_CK_P,
    input wire LVDS_ODD_CK_N,
    input wire [2:0] LVDS_ODD_P,
    input wire [2:0] LVDS_ODD_N,
    input wire [2:0] LVDS_EVEN_P,
    input wire [2:0] LVDS_EVEN_N,
`elsif INPUT_DVI
    input wire DVI_CK_P,
    input wire DVI_CK_N,
    input wire [2:0] DVI_DAT_P,
    input wire [2:0] DVI_DAT_N,
`endif
    // CSR interface
    input wire SPI_CS,
    input wire SPI_SCK,
    input wire SPI_MOSI,
    output wire SPI_MISO
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
    
    wire epdc_rst;
    
    /*generate
    if (CLK_SOURCE == "DCM") begin: clocking_dq*/
        wire pll_locked;
        sysclock sysclock (
            .clk_in(CLK_IN),
            .clk_ddr(clk_ddr),
            .clk_sys(clk_sys),
            .reset(1'b0),
            .locked(pll_locked)
        );
//         reg [26:0] rst_counter;
//         always @(posedge clk_sys) begin
//             if (!pll_locked) begin
//                 rst_counter <= 27'd0;
//             end
//             else begin
//                 if (!rst_counter[26])
//                     rst_counter <= rst_counter + 1;
//             end
//         end
//         assign mif_rst = !rst_counter[26];
        assign mif_rst = !pll_locked;
    /*end
    else if (CLK_SOURCE == "DDR") begin: clocking_ddr
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
    end
    else if (CLK_SOURCE == "FPD") begin: clocking_lvds
        reg c3_sys_rst = 1'b1;
        always @(posedge clk_sys) begin
            c3_sys_rst <= 1'b0;
        end
   
        assign clk_sys = v_pclk;
        assign clk_ddr = v_pclk;
        assign mif_rst = c3_sys_rst;
    end
    endgenerate*/

    // Global frame trigger & control
    wire b_trigger;
    wire global_en;
    wire [23:0] frame_bytes;

    // Video input
    (* KEEP = "TRUE" *) wire v_pclk;
    wire v_vs, v_hs, v_de;
    wire [15:0] v_pixel;
    
    `ifdef INPUT_INTERNAL
    // Set resolutions for internal video feed
    // Horizontal
    // All numbers are divided by 2
    parameter VIN_H_FP    = 32;  //Front porch
    parameter VIN_H_SYNC  = 96;  //Sync
    parameter VIN_H_BP    = 152; //Back porch
    parameter VIN_H_ACT   = 800; //Active pixels
    // Vertical
    parameter VIN_V_FP    = 1;    //Front porch
    parameter VIN_V_SYNC  = 3;    //Sync
    parameter VIN_V_BP    = 46;   //Back porch
    parameter VIN_V_ACT   = 1200; //Active lines
    vin_internal #(
        .H_FP(VIN_H_FP),
        .H_SYNC(VIN_H_SYNC),
        .H_BP(VIN_H_BP),
        .H_ACT(VIN_H_ACT),
        .V_FP(VIN_V_FP),
        .V_SYNC(VIN_V_SYNC),
        .V_BP(VIN_V_BP),
        .V_ACT(VIN_V_ACT)
    ) vin(
        .clk(clk_sys),
        .rst(sys_rst),
        .v_vsync(v_vs),
        .v_hsync(v_hs),
        .v_pclk(v_pclk),
        .v_de(v_de),
        .v_pixel(v_pixel)
    );
    `elsif INPUT_LVDS
    vin_fpdlink #(
        .COLORMODE(COLORMODE)
    ) vin_fpdlink(
        .clk(clk_sys),
        .rst(sys_rst),
        .fpdlink_cp(LVDS_ODD_CK_P),
        .fpdlink_cn(LVDS_ODD_CK_N),
        .fpdlink_odd_p(LVDS_ODD_P),
        .fpdlink_odd_n(LVDS_ODD_N),
        .fpdlink_even_p(LVDS_EVEN_P),
        .fpdlink_even_n(LVDS_EVEN_N),
        .v_vsync(v_vs),
        .v_hsync(v_hs),
        .v_pclk(v_pclk),
        .v_de(v_de),
        .v_pixel(v_pixel)
    );
    `elsif INPUT_DVI
    wire dbg_pclk;
    wire dbg_hsync;
    wire dbg_vsync;
    wire dbg_de;
    wire dbg_pll_lck;
    vin_dvi vin_dvi (
        .rst(sys_rst),
        .rst_out(epdc_rst),
        .dvi_cp(DVI_CK_P),
        .dvi_cn(DVI_CK_N),
        .dvi_dp(DVI_DAT_P),
        .dvi_dn(DVI_DAT_N),
        .v_vsync(v_vs),
        .v_hsync(v_hs),
        .v_pclk(v_pclk),
        .v_de(v_de),
        .v_pixel(v_pixel),
        .dbg_pclk(dbg_pclk),
        .dbg_hsync(dbg_hsync),
        .dbg_vsync(dbg_vsync),
        .dbg_de(dbg_de),
        .dbg_pll_lck(dbg_pll_lck)
    );
    `endif
    
    // Generate 1/2 video clock
    (* KEEP = "TRUE" *) wire clk_epdc;
    clk_div #(.WIDTH(1), .DIV(2)) clk_epdc_div (
        .i(v_pclk),
        .o(clk_epdc)
    );
    
    // Video input buffering
    wire fifo_full;
    wire fifo_empty;
    wire [31:0] vin_pixel;
    wire vin_ready;
    
    vi_fifo vi_fifo (
        .rst(vin_vsync), // input rst, reset at each frame
        // Write port
        .wr_clk(v_pclk), // input wr_clk
        .din(v_pixel), // input [7 : 0] din
        .wr_en(v_de), // input wr_en
        .full(fifo_full), // output full, error
        // Read port
        .rd_clk(clk_epdc), // input rd_clk
        .rd_en(vin_ready), // input rd_en
        .dout(vin_pixel), // output [15 : 0] dout
        .empty(fifo_empty) // output empty
    );
    
    wire vin_valid = !fifo_empty;
    wire vin_vsync;
    // Sync vs signal to clk_sys clock domain
    dff_sync vs_sync (
        .i(v_vs),
        .clko(clk_epdc),
        .o(vin_vsync)
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
        .frame_bytes(frame_bytes),
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

    dff_sync memif_vs_sync (
        .i(b_trigger),
        .clko(clk_mif),
        .o(memif_trigger)
    );

    dff_sync memif_en_sync (
        .i(ddr_calib_done && global_en),
        .clko(clk_mif),
        .o(memif_enable)
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
    wire epdc_ddr_calib_done;
    dff_sync epdc_ddr_calib_done_sync (
        .i(ddr_calib_done),
        .clko(clk_epdc),
        .o(epdc_ddr_calib_done)
    );
    wire sys_ready = epdc_ddr_calib_done;

    wire spi_ncs;
    wire spi_sck;
    wire spi_mosi;
    wire spi_miso;
    dff_sync spi_cs_sync (
        .i(!SPI_CS),
        .clko(clk_epdc),
        .o(spi_ncs)
    );
    wire spi_cs = !spi_ncs;

    dff_sync spi_sck_sync (
        .i(SPI_SCK),
        .clko(clk_epdc),
        .o(spi_sck)
    );

    dff_sync spi_mosi_sync (
        .i(SPI_MOSI),
        .clko(clk_epdc),
        .o(spi_mosi)
    );
    
    wire [1:0] dbg_scan_state;
    wire [10:0] dbg_scan_h_cnt;
    wire [10:0] dbg_scan_v_cnt;

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
        .epd_sd(EPD_SD[7:0]),
        .epd_sdce0(EPD_SDCE0),
        // CSR interface
        .spi_cs(spi_cs),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(SPI_MISO),
        // Control / status
        .b_trigger(b_trigger),
        .sys_ready(sys_ready),
        .mig_error(mig_error),
        .mif_error(memif_error),
        .frame_bytes(frame_bytes),
        .global_en(global_en),
        // Debugging
        .dbg_scan_state(dbg_scan_state),
        .dbg_scan_h_cnt(dbg_scan_h_cnt),
        .dbg_scan_v_cnt(dbg_scan_v_cnt)
    );
    
    // Debug
    wire [35:0] chipscope_control0;
    chipscope_icon icon (
        .CONTROL0(chipscope_control0) // INOUT BUS [35:0]
    );
    
    wire [31:0] ila_signals;
    chipscope_ila ila (
        .CONTROL(chipscope_control0), // INOUT BUS [35:0]
        .CLK(clk_mif),
        .TRIG0(ila_signals)
    );

    assign ila_signals[0] = pll_locked;
    assign ila_signals[1] = ddr_calib_done;
    assign ila_signals[2] = sys_rst;
    assign ila_signals[3] = memif_error;
    assign ila_signals[4] = v_vs;
    assign ila_signals[5] = v_hs;
    assign ila_signals[6] = v_de;
//    assign ila_signals[7] = v_pclk;
//    assign ila_signals[8] = dbg_hsync;
//    assign ila_signals[9] = dbg_vsync;
//    assign ila_signals[10] = dbg_de;
//    assign ila_signals[11] = dbg_pll_lck;
    
    assign ila_signals[7] = vin_ready; // vi_fifo_rd_en
    assign ila_signals[8] = vin_valid; // vi_fifo_rd not empty
    assign ila_signals[9] = memif_enable;
    assign ila_signals[10] = memif_trigger;
    assign ila_signals[11] = pix_read_valid; // bi_fifo_wr_en
    assign ila_signals[12] = bi_fifo_full;
    assign ila_signals[13] = bi_ready;
    assign ila_signals[14] = bi_valid; // bi_fifo_rd not empty
    assign ila_signals[15] = bo_valid;
    assign ila_signals[16] = bo_fifo_full;
    assign ila_signals[17] = pix_write_ready; // bo_fifo_rd_en
    assign ila_signals[18] = bo_fifo_empty;
    //assign ila_signals[19] = dbg_scan_state[0];
    assign ila_signals[19] = dbg_scan_state[1];
    //assign ila_signals[15] = vin_vsync;
    assign ila_signals[20] = vin_pixel[15]; // sneak peak of pixel

    assign ila_signals[21] = spi_cs;
    assign ila_signals[22] = spi_sck;
    assign ila_signals[23] = spi_mosi;
    
    assign ila_signals[31:24] = dbg_scan_v_cnt[7:0];
    //assign ila_signals[31:21] = dbg_scan_v_cnt;
    
    assign EPD_SD[15:8] = EPD_SD[7:0];

endmodule
`default_nettype wire
