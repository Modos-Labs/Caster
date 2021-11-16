//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2009 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor: Xilinx
// \   \   \/    Version: 1.1
//  \   \        Filename: phase_detector.v
//  /   /        Date Last Modified:  February 5 2010
// /___/   /\    Date Created: August 1 2008
// \   \  /  \
//  \___\/\___\
// 
//Device: 	Spartan 6
//Purpose:  	Generic phase detector control module
//
//Reference:
//    
//Revision History:
//    Rev 1.0 - First created (nicks)
//    Rev 1.1 - Modifications (nicks)
//		- State machine changed slightly to enable individual control of INC pins on IODELAY2s
//		- inc connection changed from 1 wide to D wide to accomodate this
//		- debug in and out ports added
//
//////////////////////////////////////////////////////////////////////////////
//
//  Disclaimer: 
//
//		This disclaimer is not a license and does not grant any rights to the materials 
//              distributed herewith. Except as otherwise provided in a valid license issued to you 
//              by Xilinx, and to the maximum extent permitted by applicable law: 
//              (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, 
//              AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, 
//              INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT, OR 
//              FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx shall not be liable (whether in contract 
//              or tort, including negligence, or under any other theory of liability) for any loss or damage 
//              of any kind or nature related to, arising under or in connection with these materials, 
//              including for any direct, or any indirect, special, incidental, or consequential loss 
//              or damage (including loss of data, profits, goodwill, or any type of loss or damage suffered 
//              as a result of any action brought by a third party) even if such damage or loss was 
//              reasonably foreseeable or Xilinx had been advised of the possibility of the same.
//
//  Critical Applications:
//
//		Xilinx products are not designed or intended to be fail-safe, or for use in any application 
//		requiring fail-safe performance, such as life-support or safety devices or systems, 
//		Class III medical devices, nuclear facilities, applications related to the deployment of airbags,
//		or any other applications that could lead to death, personal injury, or severe property or 
//		environmental damage (individually and collectively, "Critical Applications"). Customer assumes 
//		the sole risk and liability of any use of Xilinx products in Critical Applications, subject only 
//		to applicable laws and regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
//
//////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module phase_detector (use_phase_detector, busy, valid, inc_dec, reset, gclk, debug_in, cal_master, cal_slave, rst_out, ce, inc, debug) ;


parameter integer D = 16 ;			// Set the number of inputs

input			use_phase_detector ;	// Set generation of phase detector logic
input	[D-1:0]		busy ;			// BUSY inputs from IODELAY2s
input	[D-1:0]		valid ;			// VALID inputs from ISERDES2s
input	[D-1:0]		inc_dec ;		// INC_DEC inputs from ISERDES2s
input			reset ;			// Reset line
input			gclk ;			// Global clock
input 	[1:0]		debug_in ;		// Debug Inputs, set to 2'b00 if not required
output			cal_master ;		// Output to cal pins on master IODELAY2s
output			cal_slave ;		// Output to cal pins on slave IODELAY2s
output			rst_out ;		// Output to rst pins on master & slave IODELAY2s
output	[D-1:0]		ce ;  			// Outputs to ce pins on IODELAY2s
output	[D-1:0]		inc ;  			// Outputs to inc pins on IODELAY2s
output 	[3*D+5:0] 	debug ;			// Debug bus, 3D+5 = 3 lines per input pin (from inc, mux and ce) + 6, leave nc if debug not required

reg	[3:0]		state ;
reg	[11:0]		counter ;
reg			cal_data_sint ;
reg 			busy_data_d ;
reg			enable ;
reg			cal_data_master ;
reg			rst_data ;
reg 			inc_data_int ;
reg 	[D-1:0]		ce_data ;
reg 			valid_data_d ;
reg 			incdec_data_d ;
reg	[4:0] 		pdcounter ;
reg 	[D-1:0]		mux ;
reg			ce_data_inta ;
wire	[D:0]		incdec_data_or ;
wire	[D-1:0]		incdec_data_im ;
wire	[D:0]		valid_data_or ;
wire	[D-1:0]		valid_data_im ;
wire	[D:0]		busy_data_or ;
wire	[D-1:0]		all_ce ;
wire	[D-1:0]		all_inc ;
reg 	[D-1:0]		inc_data_int_d ;

genvar i ;

assign debug = {mux, cal_data_master, rst_data, cal_data_sint, busy_data_d, inc_data_int_d, ce_data, valid_data_d, incdec_data_d};
assign cal_slave = cal_data_sint ;
assign cal_master = cal_data_master ;
assign rst_out = rst_data ;
assign ce = ce_data ;
assign inc = inc_data_int_d ;

always @ (posedge gclk or posedge reset)
begin
if (reset == 1'b1) begin
	state <= 0 ;
	cal_data_master <= 1'b0 ;
	cal_data_sint <= 1'b0 ;
	counter <= 12'h000 ;
//synthesis translate_off
	counter[10:3] <= 8'hFF ;					// speed up simulation
//synthesis translate_on
	enable <= 1'b0 ;
	mux <= 16'h0001 ;
end
else begin
   	if (counter[11] == 1'b1) begin
		counter <= 12'h000 ;
   	end
   	else begin
   		counter <= counter + 12'h001 ;
//synthesis translate_off
		counter[10:7] <= 12'hFFF ;				// speed up simulation
//synthesis translate_on
   	end
   	if (counter[11] == 1'b1) begin					// Delay before startup
		enable <= 1'b1 ;
   	end
  	case (state)
  	4'h0 : 	begin 
  		if (enable == 1'b1) begin				// Wait for IODELAY to be available
			cal_data_master <= 1'b0 ;
			cal_data_sint <= 1'b0 ;
			rst_data <= 1'b0 ;
   			if (busy_data_d == 1'b0) begin
				state <= 1 ;
			end
   		end
   		end
   	4'h1: 	begin							// Issue calibrate command to both master and slave, needed for simulation, not for the silicon
   		cal_data_master <= 1'b1 ;				// When in phase_detector mode the slave controls the master completely in silicon, but due to the 
   		cal_data_sint <= 1'b1 ;					// way the simulation models work, the master does require these signals for correct simulation
   		if (busy_data_d == 1'b1) begin				// and wait for command to be accepted
   			state <= 2 ;
   		end
   		end
   	4'h2 : 	begin							// Now RST master and slave IODELAYs needed for simulation, not for the silicon
   		cal_data_master <= 1'b0 ;				// When in phase_detector mode the slave controls the master completely in silicon, but due to 
   		cal_data_sint <= 1'b0 ;  				// way the simulation models work, the master does require these signals for correct simulation
   		if (busy_data_d == 1'b0) begin
   			rst_data <= 1'b1 ;
   			state <= 3 ;
   		end
   		end
   	4'h3 : 	begin							// Dummy state. delay may or may not go BUSY depending on timing
   		rst_data <= 1'b0 ;
   		state <= 4 ;
   		end
   	4'h4 : 	begin							// Wait for IODELAY to be available
   		if (busy_data_d == 1'b0) begin
   			state <= 6 ;
   		end
   		end
   	4'h5 : 	begin							// Wait for occasional enable
   		if (counter[11] == 1'b1) begin
  		 	state <= 6 ;
   		end
    		end
    	4'h6 : 	begin							// Calibrate slave only
   		if (busy_data_d == 1'b0) begin 				
   			cal_data_sint <= 1'b1 ;				
   			state <= 7 ;
   			if (D != 1) begin
   				mux <= {mux[D-2:0], mux[D-1]} ;
   			end
   		end
   		end
    	4'h7 : 	begin							// Wait for command to be accepted
   		if (busy_data_d == 1'b1) begin
   			cal_data_sint <= 1'b0 ;
   			state <= 8 ;
   		end
   		end
   	4'h8 : begin							// Wait for all IODELAYs to be available, ie CAL command finished
  		if (busy_data_d == 1'b0) begin
   			state <= 5 ;
   		end
   		end
   	default : begin state <= 0 ; end
   	endcase
end
end

always @ (posedge gclk or posedge reset)				// Per-bit phase detection state machine
begin
if (reset == 1'b1) begin
	pdcounter <= 5'b10000 ;
	ce_data_inta <= 1'b0 ;
	inc_data_int <= 1'b0 ;
end
else begin
	busy_data_d <= busy_data_or[D] ;
	incdec_data_d <= incdec_data_or[D] ;
	valid_data_d <= valid_data_or[D] ;
   	if (use_phase_detector == 1'b1) begin				// decide whther pd is used
		if (ce_data_inta == 1'b1) begin
			ce_data <= mux ;
			if (inc_data_int == 1'b1) begin
				inc_data_int_d <= mux ;
			end
		end
		else begin
			ce_data <= 64'h0000000000000000 ;
			inc_data_int_d <= 64'h0000000000000000 ;
		end
   		if (state != 5 || busy_data_d == 1'b1) begin		// Reset filter if state machine issues a cal command or unit is busy
			pdcounter <= 5'b10000 ;
   			ce_data_inta <= 1'b0 ;
   			inc_data_int <= 1'b0 ;
   		end
   		else if (pdcounter == 5'b11111) begin			// Filter has reached positive max - increment the tap count
   			ce_data_inta <= 1'b1 ;
   			inc_data_int <= 1'b1 ;
 			pdcounter <= 5'b10000 ;
 		end
    		else if (pdcounter == 5'b00000) begin			// Filter has reached negative max - decrement the tap count
   			ce_data_inta <= 1'b1 ;
   			inc_data_int <= 1'b0 ;
 			pdcounter <= 5'b10000 ;
   		end
		else if (valid_data_d == 1'b1) begin			// increment filter
   			ce_data_inta <= 1'b0 ;
   			inc_data_int <= 1'b0 ;
			if (incdec_data_d == 1'b1) begin
				pdcounter <= pdcounter + 5'b00001 ;
			end
			else if (incdec_data_d == 1'b0) begin		// decrement filter
				pdcounter <= pdcounter + 5'b11111 ;
			end
   		end
   		else begin
   			ce_data_inta <= 1'b0 ;
   			inc_data_int <= 1'b0 ;
   		end
   	end
   	else begin
		ce_data <= all_ce ;
		inc_data_int_d <= all_inc ;
   	end
end
end

assign incdec_data_or[0] = 1'b0 ;					// Input Mux - Initialise generate loop OR gates
assign valid_data_or[0] = 1'b0 ;
assign busy_data_or[0] = 1'b0 ;

generate
for (i = 0 ; i <= (D-1) ; i = i+1)
begin : loop0

assign incdec_data_im[i] = inc_dec[i] & mux[i] ;			// Input muxes
assign incdec_data_or[i+1] = incdec_data_im[i] | incdec_data_or[i] ;	// AND gates to allow just one signal through at a tome
assign valid_data_im[i] = valid[i] & mux[i] ;				// followed by an OR
assign valid_data_or[i+1] = valid_data_im[i] | valid_data_or[i] ;	// for the three inputs from each PD
assign busy_data_or[i+1] = busy[i] | busy_data_or[i] ;			// The busy signals just need an OR gate

assign all_ce[i] = debug_in[0] ;
assign all_inc[i] = debug_in[1] & debug_in[0] ;

end
endgenerate

endmodule
