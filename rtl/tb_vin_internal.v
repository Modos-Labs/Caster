`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   01:49:34 05/31/2022
// Design Name:   vin_internal
// Module Name:   /home/ise/caster/rtl/tb_vin_internal.v
// Project Name:  caster
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: vin_internal
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_vin_internal;

	// Inputs
	reg clk;
	reg rst;

	// Outputs
	wire v_vsync;
	wire v_hsync;
	wire v_pclk;
	wire v_de;
	wire [7:0] v_pixel;

	// Instantiate the Unit Under Test (UUT)
	vin_internal uut (
		.clk(clk), 
		.rst(rst), 
		.v_vsync(v_vsync), 
		.v_hsync(v_hsync), 
		.v_pclk(v_pclk), 
		.v_de(v_de), 
		.v_pixel(v_pixel)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;

        #10;
		rst = 1;
        clk = 1;
        #10;
        clk = 0;
        #10;
        rst = 0;
        
		// Add stimulus here
        while (1) begin
            clk = 1;
            #10;
            clk = 0;
            #10;
        end
	end
      
endmodule

