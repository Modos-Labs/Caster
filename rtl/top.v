`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting
// 
// Create Date:    23:50:32 11/08/2021 
// Design Name:    caster
// Module Name:    top 
// Project Name: 
// Target Devices: spartan6
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
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
    // Master I2C bus
    inout wire I2C_SDA,
    output wire I2C_SCL,
    // EPD interface
    output wire EPD_GDOE,
    output wire EPD_GDCLK,
    output wire EPD_GDSP,
    output wire EPD_SDCLK,
    output wire EPD_SDLE,
    output wire EPD_SDOE,
    output wire [15:0] EPD_SD,
    output wire EPD_SDCE0,
    // MIPI interface 
    input wire DSI_CK_P,
    input wire DSI_CK_N,
    input wire [3:0] DSI_D_P,
    input wire [3:0] DSI_D_N
    );
    
    parameter SIMULATION = "FALSE";
    parameter CALIB_SOFT_IP = "TRUE";
    
    // Horizontal
    // All numbers are divided by 2
    parameter VIN_H_FP    = 32;  //Front porch
    parameter VIN_H_SYNC  = 96;  //Sync
    parameter VIN_H_BP    = 152; //Back porch
    parameter VIN_H_ACT   = 800; //Active pixels
    parameter EPDC_H_FP   = 10;
    parameter EPDC_H_SYNC = 10;
    parameter EPDC_H_BP   = 120;
    parameter EPDC_H_ACT  = 400;
    // Vertical
    parameter VIN_V_FP    = 1;    //Front porch
    parameter VIN_V_SYNC  = 3;    //Sync
    parameter VIN_V_BP    = 46;   //Back porch
    parameter VIN_V_ACT   = 1200; //Active lines
    parameter EPDC_V_FP   = 44;
    parameter EPDC_V_SYNC = 1;
    parameter EPDC_V_BP   = 3;
    parameter EPDC_V_ACT  = 1200;

    // System clocking
    wire clk_sys;
    wire sys_rst;
    IBUFG clkin1_buf (
        .O (clk_sys),
        .I (CLK_IN)
    );

    // Global frame trigger
    wire b_trigger;

    // Video input
    wire v_vs, v_hs, v_de, v_pclk;
    wire [7:0] v_pixel;
    
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
    
    // Generate 1/2 video clock
    wire clk_epdc;
    clk_div #(.WIDTH(1), .DIV(2)) clk_epdc_div (
        .i(v_pclk),
        .o(clk_epdc)
    );
    
    // Video input buffering
    wire fifo_full;
    wire fifo_empty;
    wire [15:0] vin_pixel;
    wire vin_ready;
    
    vi_fifo vi_fifo (
        .rst(b_trigger), // input rst, reset at each frame
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
    
    // VRAM interface
    wire         clk_mif;
    wire         memif_trigger;
    wire         pix_read_valid;
    wire         pix_read_ready;
    wire [127:0] pix_read;
    wire         pix_write_valid;
    wire         pix_write_ready;
    wire [127:0] pix_write;
    wire         ddr_calib_done;
    
    wire memif_error;
    wire memif_data_valid;

    memif #(
        .SIMULATION(SIMULATION),
        .CALIB_SOFT_IP(CALIB_SOFT_IP),
        .MAX_ADDRESS(EPDC_H_ACT * 4 * EPDC_V_ACT * 2)
    )
    memif(
        // Clock and reset
        .clk_sys(clk_sys),
        .clk_mif(clk_mif),
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
        .vsync(memif_trigger),
        // Pixel output interface
        .pix_read(pix_read),
        .pix_read_valid(pix_read_valid),
        .pix_read_ready(pix_read_ready),
        // Pixel input interface
        .pix_write(pix_write),
        .pix_write_valid(pix_write_valid),
        .pix_write_ready(pix_write_ready),
        .error(memif_error),
        .cmp_data_valid(memif_data_valid)
    );

    dff_sync memif_vs_sync (
        .i(b_trigger),
        .clko(clk_mif),
        .o(memif_trigger)
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
        .rst(b_trigger), // input rst, reset at each frame
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
        .rst(b_trigger), // input rst, reset at each frame
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

    // Power controller
    wire pok;
    wire error;
    wire [2:0] dbg_state;
    wire pwr_scl;
    wire pwr_sda;
    
    wire sys_rst_sync;
    dff_sync pok_sync (
        .i(sys_rst),
        .clko(clk_sys),
        .o(sys_rst_sync)
    );

    generate
    if (SIMULATION == "FALSE") begin: power_controller
        wire pok_clk_sys;
        power power(
            .clk(clk_sys),
            .rst(sys_rst_sync),
            .en(1'b1),
            .cen(1'b1),
            .pok(pok_clk_sys),
            .error(error),
            .i2c_sda(pwr_sda),
            .i2c_scl(pwr_scl),
            .dbg_state(dbg_state)
        );
        dff_sync pok_sync (
            .i(pok_clk_sys),
            .clko(clk_epdc),
            .o(pok)
        );
    end
    else begin: bypass_power
        // DEBUGGING: BYPASS POWER INIT
        assign pok = !sys_rst_sync;
        assign error = 1'b0;
    end
    endgenerate
    
    assign I2C_SDA = pwr_sda;
    assign I2C_SCL = pwr_scl;
    
    // EPD controller
    wire epdc_ddr_calib_done;
    dff_sync epdc_ddr_calib_done_sync (
        .i(ddr_calib_done),
        .clko(clk_epdc),
        .o(epdc_ddr_calib_done)
    );
    wire sys_ready = pok && epdc_ddr_calib_done;

    caster #(
        .H_FP(EPDC_H_FP),
        .H_SYNC(EPDC_H_SYNC),
        .H_BP(EPDC_H_BP),
        .H_ACT(EPDC_H_ACT),
        .V_FP(EPDC_V_FP),
        .V_SYNC(EPDC_V_SYNC),
        .V_BP(EPDC_V_BP),
        .V_ACT(EPDC_V_ACT),
        .SIMULATION(SIMULATION)
    )
    caster(
        .clk(clk_epdc),
        .rst(sys_rst),
        .sys_ready(sys_ready),
        .vin_vsync(vin_vsync),
        .vin_pixel(vin_pixel),
        .vin_valid(vin_valid),
        .vin_ready(vin_ready),
        .b_trigger(b_trigger),
        .bi_pixel(bi_pixel),
        .bi_valid(bi_valid),
        .bi_ready(bi_ready),
        .bo_pixel(bo_pixel),
        .bo_valid(bo_valid),
        .epd_gdoe(EPD_GDOE),
        .epd_gdclk(EPD_GDCLK),
        .epd_gdsp(EPD_GDSP),
        .epd_sdclk(EPD_SDCLK),
        .epd_sdle(EPD_SDLE),
        .epd_sdoe(EPD_SDOE),
        .epd_sd(EPD_SD),
        .epd_sdce0(EPD_SDCE0)
    );
    
    // Debug
    wire [35:0] chipscope_control0;
    
    chipscope_icon icon (
        .CONTROL0(chipscope_control0) // INOUT BUS [35:0]
    );
    
    chipscope_ila ila (
        .CONTROL(chipscope_control0), // INOUT BUS [35:0]
        .CLK(clk_mif),
        .TRIG0({
            memif_error,
            memif_data_valid,
            ddr_calib_done,
            5'b0
        })
    );

endmodule
