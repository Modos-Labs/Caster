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
	reg vin_hsync;
	reg vin_de;
	reg [31:0] vin_pixel;
	reg [31:0] bi_pixel;
	reg bi_valid;

	// Outputs
	wire bi_ready;
	wire [31:0] bo_pixel;
	wire bo_valid;
	wire epd_gdoe;
	wire epd_gdclk;
	wire epd_gdsp;
	wire epd_sdclk;
	wire epd_sdle;
	wire epd_sdoe;
	wire [15:0] epd_sd;
	wire epd_sdce0;

	// Instantiate the Unit Under Test (UUT)
	caster uut (
		.clk(clk), 
		.rst(rst), 
		.pok(pok), 
		.vin_vsync(vin_vsync), 
		.vin_hsync(vin_hsync), 
		.vin_de(vin_de), 
		.vin_pixel(vin_pixel), 
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
		vin_vsync = 0;
		vin_hsync = 0;
		vin_de = 0;
		vin_pixel = 0;
		bi_pixel = 0;
		bi_valid = 0;

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

