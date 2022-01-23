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
    // Slave I2C bus
    inout wire I2C_SDA,
    input wire I2C_SCL,
    // Master I2C bus
    // Not present on R0.1 hardware
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

    wire         top_pll_locked;
    wire         clk_ddr;
    wire         clk_epd;

    clocking clocking (
        // Clock in ports
        .clk_in(CLK_IN),
        // Clock out ports
        .clk_ddr(clk_ddr),
        .clk_epd(clk_epd),
        // Status and control signals
        .reset(1'b0),
        .locked(top_pll_locked)
     );
    
    wire         vsync;
    wire         pix_read_valid;
    wire         pix_read_ready;
    wire [63:0]  pix_read;
    wire         pix_write_valid;
    wire         pix_write_ready;
    wire [63:0]  pix_write;

    memif memif(
        // Clock and reset
        .clk_ddr(clk_ddr),
        .clk_ddr_locked(top_pll_locked),
        .clk_mif(clk_mif),
        .rst_out(sys_rst),
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
        .vsync(vsync),
        // Pixel output interface
        .pix_read(pix_read),
        .pix_read_valid(pix_read_valid),
        .pix_read_ready(pix_read_ready),
        // Pixel input interface
        .pix_write(pix_write),
        .pix_write_valid(pix_write_valid),
        .pix_write_ready(pix_write_ready)
    );

    vin vin(
        .rst(sys_rst),
        .dsi_cp(DSI_CK_P),
        .dsi_cn(DSI_CK_N),
        .dsi_dp(DSI_D_P),
        .dsi_dn(DSI_D_N),
        .v_vsync(),
        .v_hsync(),
        .v_pclk(),
        .v_pixel()
    );

endmodule
