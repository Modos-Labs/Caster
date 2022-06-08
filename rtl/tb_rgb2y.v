`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   08:06:06 06/07/2022
// Design Name:   rgb2y
// Module Name:   /home/ise/caster/rtl/tb_rgb2y.v
// Project Name:  caster
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: rgb2y
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_rgb2y;

	// Inputs
	reg [5:0] r;
	reg [5:0] g;
	reg [5:0] b;

	// Outputs
	wire [3:0] y;

	// Instantiate the Unit Under Test (UUT)
	rgb2y uut (
		.r(r), 
		.g(g), 
		.b(b), 
		.y(y)
	);
    
    integer i;

	initial begin
		// Initialize Inputs
		r = 0;
		g = 0;
		b = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
        for (i = 0; i < 64; i = i + 1) begin
            r = i;
            g = i;
            b = i;
            #10;
        end
        
        $finish;
	end
      
endmodule

