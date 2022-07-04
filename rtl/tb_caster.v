`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   03:33:40 05/30/2022
// Design Name:   caster
// Module Name:   /home/ise/caster/rtl/tb_caster.v
// Project Name:  caster
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: caster
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_caster;

	// Inputs
	reg clk;
	reg rst;
	reg pok;
	reg vin_vsync;
	reg vin_valid;
	reg [15:0] vin_pixel;
	reg [63:0] bi_pixel;
	reg bi_valid;

	// Outputs
    wire vin_ready;
	wire bi_ready;
	wire [63:0] bo_pixel;
	wire bo_valid;
	wire epd_gdoe;
	wire epd_gdclk;
	wire epd_gdsp;
	wire epd_sdclk;
	wire epd_sdle;
	wire epd_sdoe;
	wire [7:0] epd_sd;
	wire epd_sdce0;
    
    parameter EPDC_H_FP   = 120;
    parameter EPDC_H_SYNC = 10;
    parameter EPDC_H_BP   = 10;
    parameter EPDC_H_ACT  = 400;
    // Vertical
    parameter EPDC_V_FP   = 45;
    parameter EPDC_V_SYNC = 1;
    parameter EPDC_V_BP   = 2;
    parameter EPDC_V_ACT  = 1200;

	// Instantiate the Unit Under Test (UUT)
	caster #(
        .H_FP(EPDC_H_FP),
        .H_SYNC(EPDC_H_SYNC),
        .H_BP(EPDC_H_BP),
        .H_ACT(EPDC_H_ACT),
        .V_FP(EPDC_V_FP),
        .V_SYNC(EPDC_V_SYNC),
        .V_BP(EPDC_V_BP),
        .V_ACT(EPDC_V_ACT),
        .SIMULATION("TRUE"),
        .COLORMODE("MONO")
    ) uut (
		.clk(clk), 
		.rst(rst), 
		.sys_ready(pok), 
		.vin_vsync(vin_vsync), 
		.vin_pixel(vin_pixel), 
        .vin_valid(vin_valid),
        .vin_ready(vin_ready),
		.bi_pixel(bi_pixel), 
		.bi_valid(bi_valid), 
		.bi_ready(bi_ready), 
		.bo_pixel(bo_pixel), 
		.bo_valid(bo_valid), 
		.epd_gdoe(epd_gdoe), 
		.epd_gdclk(epd_gdclk), 
		.epd_gdsp(epd_gdsp), 
		.epd_sdclk(epd_sdclk), 
		.epd_sdle(epd_sdle), 
		.epd_sdoe(epd_sdoe), 
		.epd_sd(epd_sd), 
		.epd_sdce0(epd_sdce0)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		pok = 0;
		vin_vsync = 1;
		vin_valid = 1;
		vin_pixel = 0;
		bi_pixel = 0;
		bi_valid = 1;

        #10;
		rst = 1;
        clk = 1;
        #10;
        clk = 0;
        #10;
        rst = 0;
        pok = 1;
        
		// Add stimulus here
        while (1) begin
            clk = 1;
            #10;
            clk = 0;
            #10;
        end
	end
      
endmodule

