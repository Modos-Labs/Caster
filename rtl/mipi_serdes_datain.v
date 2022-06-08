`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:55:12 11/10/2021 
// Design Name: 
// Module Name:    serdes_datain 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//   Generic diff 1:8 DDR data receiver based on XAPP1064.
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//   MIPI doesn't really provide any additional time for linek training, thus
//   bitslip is not used. Instead byte aligning is done outside of this module.
//   Given how phase detector works, it might miss the very first data being sent
//   on the bus after entering HS mode. The logic may be designed to always drop
//   the first frame received.
//////////////////////////////////////////////////////////////////////////////////
module mipi_serdes_datain(
    // Clock and reset
    input  wire         gclk,           // fabric clock
    input  wire         rst,            // reset
    // Serdes interface
    input  wire         dat_p,          // DP pin
    input  wire         dat_n,          // DN pin
    input  wire         ioclk_p,        // serdes clock
    input  wire         ioclk_n,        // serdes clock
    input  wire         serdes_strobe,  // serdes strobe
    output wire [7:0]   dout,           // data out
    // Phase detector interface
    input  wire cal_m,     // Master IODELAY calibration enable
    input  wire cal_s,     // Slave IODELAY calibration enable
    input  wire iod_rst,   // IODELAY reset input
    input  wire inc,       // IODELAY increment counter
    input  wire ce,        // IODELAY clock enable input
    output wire busy,      // Slave IODELAY sync/ cal finish output
    output wire valid,     // Master ISERDES phase detector valid output
    output wire incdec     // Master ISERDES phase detector result output
    );

    wire ddly_m;    // Master IODELAY output
    wire ddly_s;    // Slave IODELAY output
    wire iob_din;   // Signal after IBUFDS
    wire cascade;   // Master ISERDES cascade output
    wire pd_edge;   // Slave ISERDES cascade output
    
    IBUFDS #(
        .DIFF_TERM("TRUE")
    )
    ibufds (
        .I(dat_p),
        .IB(dat_n),
        .O(iob_din)
    );
    
    IODELAY2 #(
        .DATA_RATE("DDR"),
        .IDELAY_VALUE(0),
        .IDELAY2_VALUE(0),
        .ODELAY_VALUE(0),
        .IDELAY_MODE("NORMAL"),
        .SERDES_MODE("MASTER"),
        .IDELAY_TYPE("DIFF_PHASE_DETECTOR"),
        .COUNTER_WRAPAROUND("WRAPAROUND"),
        .DELAY_SRC("IDATAIN")
    )
    iodelay_m (
        .IDATAIN(iob_din),  // data from master IOB
        .TOUT(),            // tri-state signal to IOB
        .DOUT(),            // output data to IOB
        .T(1'b1),           // tri-state control from OLOGIC/OSERDES2
        .ODATAIN(1'b0),     // data from OLOGIC/OSERDES2
        .DATAOUT(ddly_m),   // output data 1 to ILOGIC/ISERDES2
        .DATAOUT2(),        // output data 2 to ILOGIC/ISERDES2
        .IOCLK0(ioclk_p),   // high speed clock for calibration
        .IOCLK1(ioclk_n),   // high speed clock for calibration
        .CLK(gclk),         // fabric clock for control signals
        .CAL(cal_m),        // calibrate enable signal
        .INC(inc),          // increment counter
        .CE(ce),            // clock enable
        .RST(iod_rst),      // reset delay line to 1/2 max
        .BUSY()             // output when sync/ calibration has finished
    );
    
    IODELAY2 #(
        .DATA_RATE("DDR"),
        .IDELAY_VALUE(0),
        .IDELAY2_VALUE(0),
        .ODELAY_VALUE(0),
        .IDELAY_MODE("NORMAL"),
        .SERDES_MODE("SLAVE"),
        .IDELAY_TYPE("DIFF_PHASE_DETECTOR"),
        .COUNTER_WRAPAROUND("WRAPAROUND"),
        .DELAY_SRC("IDATAIN")
    )
    iodelay_s (
        .IDATAIN(iob_din),  // data from master IOB
        .TOUT(),            // tri-state signal to IOB
        .DOUT(),            // output data to IOB
        .T(1'b1),           // tri-state control from OLOGIC/OSERDES2
        .ODATAIN(1'b0),     // data from OLOGIC/OSERDES2
        .DATAOUT(ddly_s),   // output data 1 to ILOGIC/ISERDES2
        .DATAOUT2(),        // output data 2 to ILOGIC/ISERDES2
        .IOCLK0(ioclk_p),   // high speed clock for calibration
        .IOCLK1(ioclk_n),   // high speed clock for calibration
        .CLK(gclk),         // fabric clock for control signals
        .CAL(cal_s),        // calibrate enable signal
        .INC(inc),          // increment counter
        .CE(ce),            // clock enable
        .RST(iod_rst),      // reset delay line to 1/2 max
        .BUSY(busy)         // output when sync/ calibration has finished
    );
    
    ISERDES2 #(
        .DATA_WIDTH(8),
        .DATA_RATE("DDR"),
        .BITSLIP_ENABLE("FALSE"),
        .SERDES_MODE("MASTER"),
        .INTERFACE_TYPE("RETIMED")
    )
    iserdes_m (
        .D(ddly_m), 
        .CE0(1'b1),
        .CLK0(ioclk_p),
        .CLK1(ioclk_n),
        .IOCE(serdes_strobe),
        .RST(reset),
        .CLKDIV(gclk),
        .SHIFTIN(pd_edge), // Cascade input for phase detector
        .BITSLIP(1'b0),
        .FABRICOUT(),
        .Q4(dout[7]),
        .Q3(dout[6]),
        .Q2(dout[5]),
        .Q1(dout[4]),
        .VALID(valid),
        .INCDEC(incdec),
        .SHIFTOUT(cascade)
    );
        
    ISERDES2 #(
        .DATA_WIDTH(8),
        .DATA_RATE("DDR"),
        .BITSLIP_ENABLE("FALSE"),
        .SERDES_MODE("SLAVE"),
        .INTERFACE_TYPE("RETIMED")
    )
    iserdes_s (
        .D(ddly_s), 
        .CE0(1'b1),
        .CLK0(ioclk_p),
        .CLK1(ioclk_n),
        .IOCE(serdes_strobe),
        .RST(reset),
        .CLKDIV(gclk),
        .SHIFTIN(cascade), // Cascade input for  complete data
        .BITSLIP(1'b0),
        .FABRICOUT(),
        .Q4(dout[3]),
        .Q3(dout[2]),
        .Q2(dout[1]),
        .Q1(dout[0]),
        .VALID(),
        .INCDEC(),
        .SHIFTOUT(pd_edge)
    );
    
endmodule
