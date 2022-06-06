`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   02:55:56 06/01/2022
// Design Name:   top
// Module Name:   /home/ise/caster/rtl/tb_top.v
// Project Name:  caster
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_top;

	// Inputs
	reg CLK_IN;
	reg DSI_CK_P;
	reg DSI_CK_N;
	reg [3:0] DSI_D_P;
	reg [3:0] DSI_D_N;

	// Outputs
	wire [12:0] DDR_A;
	wire [2:0] DDR_BA;
	wire DDR_RAS_N;
	wire DDR_CAS_N;
	wire DDR_WE_N;
	wire DDR_ODT;
	wire DDR_RESET_N;
	wire DDR_CKE;
	wire DDR_LDM;
	wire DDR_UDM;
	wire DDR_CK_P;
	wire DDR_CK_N;
	wire I2C_SCL;
	wire EPD_GDOE;
	wire EPD_GDCLK;
	wire EPD_GDSP;
	wire EPD_SDCLK;
	wire EPD_SDLE;
	wire EPD_SDOE;
	wire [15:0] EPD_SD;
	wire EPD_SDCE0;

	// Bidirs
	wire [15:0] DDR_DQ;
	wire DDR_UDQS_P;
	wire DDR_UDQS_N;
	wire DDR_LDQS_P;
	wire DDR_LDQS_N;
	wire DDR_RZQ;
	wire DDR_ZIO;
	wire I2C_SDA;

    /*
    parameter VIN_H_FP    = 4;
    parameter VIN_H_SYNC  = 6;
    parameter VIN_H_BP    = 8;
    parameter VIN_H_ACT   = 64;
    parameter EPDC_H_FP   = 2;
    parameter EPDC_H_SYNC = 1;
    parameter EPDC_H_BP   = 6;
    parameter EPDC_H_ACT  = 32;
    parameter VIN_V_FP    = 1;
    parameter VIN_V_SYNC  = 3;
    parameter VIN_V_BP    = 6;
    parameter VIN_V_ACT   = 96;
    parameter EPDC_V_FP   = 4;
    parameter EPDC_V_SYNC = 1;
    parameter EPDC_V_BP   = 3;
    parameter EPDC_V_ACT  = 96;*/
    
    parameter VIN_H_FP    = 4;
    parameter VIN_H_SYNC  = 6;
    parameter VIN_H_BP    = 8;
    parameter VIN_H_ACT   = 16;
    parameter EPDC_H_FP   = 2;
    parameter EPDC_H_SYNC = 1;
    parameter EPDC_H_BP   = 6;
    parameter EPDC_H_ACT  = 8;
    parameter VIN_V_FP    = 1;
    parameter VIN_V_SYNC  = 3;
    parameter VIN_V_BP    = 6;
    parameter VIN_V_ACT   = 4;
    parameter EPDC_V_FP   = 4;
    parameter EPDC_V_SYNC = 1;
    parameter EPDC_V_BP   = 3;
    parameter EPDC_V_ACT  = 4;

	// Instantiate the Unit Under Test (UUT)
	top #(
        .SIMULATION    ("TRUE"),
        .CALIB_SOFT_IP ("TRUE"),
        .VIN_H_FP      (VIN_H_FP),
        .VIN_H_SYNC    (VIN_H_SYNC),
        .VIN_H_BP      (VIN_H_BP),
        .VIN_H_ACT     (VIN_H_ACT),
        .EPDC_H_FP     (EPDC_H_FP),
        .EPDC_H_SYNC   (EPDC_H_SYNC),
        .EPDC_H_BP     (EPDC_H_BP),
        .EPDC_H_ACT    (EPDC_H_ACT),
        .VIN_V_FP      (VIN_V_FP),
        .VIN_V_SYNC    (VIN_V_SYNC),
        .VIN_V_BP      (VIN_V_BP),
        .VIN_V_ACT     (VIN_V_ACT),
        .EPDC_V_FP     (EPDC_V_FP),
        .EPDC_V_SYNC   (EPDC_V_SYNC),
        .EPDC_V_BP     (EPDC_V_BP),
        .EPDC_V_ACT    (EPDC_V_ACT)
    )
    uut (
		.CLK_IN(CLK_IN),
		.DDR_DQ(DDR_DQ), 
		.DDR_A(DDR_A), 
		.DDR_BA(DDR_BA), 
		.DDR_RAS_N(DDR_RAS_N), 
		.DDR_CAS_N(DDR_CAS_N), 
		.DDR_WE_N(DDR_WE_N), 
		.DDR_ODT(DDR_ODT), 
		.DDR_RESET_N(DDR_RESET_N), 
		.DDR_CKE(DDR_CKE), 
		.DDR_LDM(DDR_LDM), 
		.DDR_UDM(DDR_UDM), 
		.DDR_UDQS_P(DDR_UDQS_P), 
		.DDR_UDQS_N(DDR_UDQS_N), 
		.DDR_LDQS_P(DDR_LDQS_P), 
		.DDR_LDQS_N(DDR_LDQS_N), 
		.DDR_CK_P(DDR_CK_P), 
		.DDR_CK_N(DDR_CK_N), 
		.DDR_RZQ(DDR_RZQ), 
		.DDR_ZIO(DDR_ZIO), 
		.I2C_SDA(I2C_SDA), 
		.I2C_SCL(I2C_SCL), 
		.EPD_GDOE(EPD_GDOE), 
		.EPD_GDCLK(EPD_GDCLK), 
		.EPD_GDSP(EPD_GDSP), 
		.EPD_SDCLK(EPD_SDCLK), 
		.EPD_SDLE(EPD_SDLE), 
		.EPD_SDOE(EPD_SDOE), 
		.EPD_SD(EPD_SD), 
		.EPD_SDCE0(EPD_SDCE0), 
		.DSI_CK_P(DSI_CK_P), 
		.DSI_CK_N(DSI_CK_N), 
		.DSI_D_P(DSI_D_P), 
		.DSI_D_N(DSI_D_N)
	);
    
    ddr3 # (
        .DEBUG(1),
        .check_strict_timing(0),
        .check_strict_mrbits(0)
    )
    ddr3
    (
        .rst_n   (DDR_RESET_N),
        .ck      (DDR_CK_P),
        .ck_n    (DDR_CK_N),
        .cke     (DDR_CKE),
        .cs_n    (1'b0),
        .ras_n   (DDR_RAS_N),
        .cas_n   (DDR_CAS_N),
        .we_n    (DDR_WE_N),
        .dm_tdqs ({DDR_UDM, DDR_LDM}),
        .ba      (DDR_BA),
        .addr    ({1'b0, DDR_A}),
        .dq      (DDR_DQ),
        .dqs     ({DDR_UDQS_P, DDR_LDQS_P}),
        .dqs_n   ({DDR_UDQS_N, DDR_LDQS_N}),
        .tdqs_n  (),
        .odt     (DDR_ODT)
    );

	initial begin
		// Initialize Inputs
		CLK_IN = 0;
		DSI_CK_P = 0;
		DSI_CK_N = 0;
		DSI_D_P = 0;
		DSI_D_N = 0;

		#15;
    
		// Add stimulus here
        while (1) begin
            CLK_IN = 1;
            #15;
            CLK_IN = 0;
            #15;
        end
	end
      
endmodule
