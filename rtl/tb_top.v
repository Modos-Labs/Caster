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
    wire LVDS_ODD_CK_P;
    wire LVDS_ODD_CK_N;
    wire [2:0] LVDS_ODD_P;
    wire [2:0] LVDS_ODD_N;
    wire [2:0] LVDS_EVEN_P;
    wire [2:0] LVDS_EVEN_N;

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
        .CLK_SOURCE    ("FPD"),
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
        .LVDS_ODD_CK_P(LVDS_ODD_CK_P),
        .LVDS_ODD_CK_N(LVDS_ODD_CK_N),
        .LVDS_ODD_P(LVDS_ODD_P),
        .LVDS_ODD_N(LVDS_ODD_N),
        .LVDS_EVEN_P(LVDS_EVEN_P),
        .LVDS_EVEN_N(LVDS_EVEN_N)
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
    
    assign LVDS_ODD_CK_N = ~LVDS_ODD_CK_P;
    assign LVDS_ODD_N = ~LVDS_ODD_P;
    assign LVDS_EVEN_N = ~LVDS_EVEN_P;
    
    reg lvds_ck;
    reg lvds_a;
    reg lvds_b;
    reg lvds_c;
    assign LVDS_ODD_CK_P = lvds_ck;
    assign LVDS_ODD_P[0] = lvds_a;
    assign LVDS_ODD_P[1] = lvds_b;
    assign LVDS_ODD_P[2] = lvds_c;
    assign LVDS_EVEN_P[0] = lvds_a;
    assign LVDS_EVEN_P[1] = lvds_b;
    assign LVDS_EVEN_P[2] = lvds_c;
    
    task sendlvds;
        input hsync;
        input vsync;
        input de;
        input [5:0] r;
        input [5:0] g;
        input [5:0] b;

        begin
            lvds_a = g[0];
            lvds_b = b[1];
            lvds_c = de;
            lvds_ck = 1;
            #1.76;
            lvds_a = r[5];
            lvds_b = b[0];
            lvds_c = vsync;
            lvds_ck = 1;
            #1.76; 
            lvds_a = r[4];
            lvds_b = g[5];
            lvds_c = hsync;
            lvds_ck = 0;
            #1.76;
            lvds_a = r[3];
            lvds_b = g[4];
            lvds_c = b[5];
            lvds_ck = 0;
            #1.76;
            lvds_a = r[2];
            lvds_b = g[3];
            lvds_c = b[4];
            lvds_ck = 0;
            #1.76;
            lvds_a = r[1];
            lvds_b = g[2];
            lvds_c = b[3];
            lvds_ck = 1;
            #1.76;
            lvds_a = r[0];
            lvds_b = g[1];
            lvds_c = b[2];
            lvds_ck = 1;
            #1.76;
        end
    endtask
    
    task sendline;
        input vsync;
        input valid;
        begin: sendline_task
            integer i;
            for (i = 0; i < VIN_H_FP; i = i + 1)
                sendlvds(0, vsync, 0, 0, 0, 0);
            for (i = 0; i < VIN_H_SYNC; i = i + 1)
                sendlvds(1, vsync, 0, 0, 0, 0);
            for (i = 0; i < VIN_H_BP; i = i + 1)
                sendlvds(0, vsync, 0, 0, 0, 0);
            for (i = 0; i < VIN_H_ACT; i = i + 1)
                sendlvds(0, vsync, valid, i, i, i);
        end
    endtask

    task sendframe;
        begin: sendframe_task
            integer i;
            for (i = 0; i < VIN_V_FP; i = i + 1)
                sendline(0, 0);
            for (i = 0; i < VIN_V_SYNC; i = i + 1)
                sendline(1, 0);
            for (i = 0; i < VIN_V_BP; i = i + 1)
                sendline(0, 0);
            for (i = 0; i < VIN_V_ACT; i = i + 1)
                sendline(0, 1);
        end
    endtask

	initial begin
		// Initialize Inputs
		CLK_IN = 0;
		//#15;
        #6;
    
		// Add stimulus here
        while (1) begin
            /*CLK_IN = 1;
            #15;
            CLK_IN = 0;
            #15;*/
            sendframe();
        end
	end
      
endmodule
