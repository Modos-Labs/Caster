`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   00:02:42 03/02/2022
// Design Name:   power
// Module Name:   /home/ise/caster/rtl/tb_power.v
// Project Name:  caster
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: power
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_power;

	// Inputs
	reg clk;
	reg rst;
	reg en;
	reg cen;

	// Outputs
	wire pok;
	wire error;
	wire i2c_scl;
	wire [2:0] dbg_state;

	// Bidirs
	wire i2c_sda;

	// Instantiate the Unit Under Test (UUT)
	power uut (
		.clk(clk), 
		.rst(rst), 
		.en(en), 
		.cen(cen), 
		.pok(pok), 
		.error(error), 
		.i2c_sda(i2c_sda), 
		.i2c_scl(i2c_scl), 
		.dbg_state(dbg_state)
	);
    
    assign i2c_sda = 1'b0;

	initial begin
		// Initialize Inputs
		rst = 0;
		en = 1;
		cen = 1;
        
		// Add stimulus here
        rst = 1;
        clk = 1;
        #10;
        clk = 0;
        #10;
        rst = 0;
        
        while (1) begin
            clk = 1;
            #10;
            clk = 0;
            #10;
        end
	end
      
endmodule

