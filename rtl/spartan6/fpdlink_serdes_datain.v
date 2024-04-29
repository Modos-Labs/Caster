// fpdlink_serdes_datain.v
// FPD-Link I 1:7 LVDS data receiver based on XAPP1064.
// This file is not covered under CERN-OHL-P.
`timescale 1ns / 1ps
`default_nettype none
module fpdlink_serdes_datain(
    // Clock and reset
    input  wire         gclk,           // fabric clock
    input  wire         rst,            // reset
    // Serdes interface
    input  wire         dat_p,          // DP pin
    input  wire         dat_n,          // DN pin
    input  wire         ioclk,          // serdes clock
    input  wire         serdes_strobe,  // serdes strobe
    input  wire         bitslip,        // bit slip enable
    output wire [6:0]   dout,           // data out
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

    parameter INVERT = 1'b0;

    wire ddly_m;    // Master IODELAY output
    wire ddly_s;    // Slave IODELAY output
    wire iob_din;   // Signal after IBUFDS
    wire cascade;   // Master ISERDES cascade output
    wire pd_edge;   // Slave ISERDES cascade output
    
    generate if (INVERT == 1'b0) begin
        IBUFDS #(
            .DIFF_TERM("TRUE")
        )
        ibufds (
            .I(dat_p),
            .IB(dat_n),
            .O(iob_din)
        );
    else begin
        IBUFDS_DIFF_OUT #(
            .DIFF_TERM("TRUE")
        )
        ibufds (
            .I(dat_p),
            .IB(dat_n),
            .O(),
            .OB(iob_din)
        );
    end endgenerate
    
    IODELAY2 #(
        .DATA_RATE("SDR"),
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
        .IOCLK0(ioclk),     // high speed clock for calibration
        .IOCLK1(1'b0),      // high speed clock for calibration
        .CLK(gclk),         // fabric clock for control signals
        .CAL(cal_m),        // calibrate enable signal
        .INC(inc),          // increment counter
        .CE(ce),            // clock enable
        .RST(iod_rst),      // reset delay line to 1/2 max
        .BUSY()             // output when sync/ calibration has finished
    );
    
    IODELAY2 #(
        .DATA_RATE("SDR"),
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
        .IOCLK0(ioclk),     // high speed clock for calibration
        .IOCLK1(1'b0),      // high speed clock for calibration
        .CLK(gclk),         // fabric clock for control signals
        .CAL(cal_s),        // calibrate enable signal
        .INC(inc),          // increment counter
        .CE(ce),            // clock enable
        .RST(iod_rst),      // reset delay line to 1/2 max
        .BUSY(busy)         // output when sync/ calibration has finished
    );
    
    ISERDES2 #(
        .DATA_WIDTH(7),
        .DATA_RATE("SDR"),
        .BITSLIP_ENABLE("TRUE"),
        .SERDES_MODE("MASTER"),
        .INTERFACE_TYPE("RETIMED")
    )
    iserdes_m (
        .D(ddly_m), 
        .CE0(1'b1),
        .CLK0(ioclk),
        .CLK1(1'b0),
        .IOCE(serdes_strobe),
        .RST(rst),
        .CLKDIV(gclk),
        .SHIFTIN(pd_edge), // Cascade input for phase detector
        .BITSLIP(bitslip),
        .FABRICOUT(),
        .Q4(dout[0]),
        .Q3(dout[1]),
        .Q2(dout[2]),
        .Q1(dout[3]),
        .DFB(),
        .CFB0(),
        .CFB1(),
        .VALID(valid),
        .INCDEC(incdec),
        .SHIFTOUT(cascade)
    );
        
    ISERDES2 #(
        .DATA_WIDTH(7),
        .DATA_RATE("SDR"),
        .BITSLIP_ENABLE("TRUE"),
        .SERDES_MODE("SLAVE"),
        .INTERFACE_TYPE("RETIMED")
    )
    iserdes_s (
        .D(ddly_s), 
        .CE0(1'b1),
        .CLK0(ioclk),
        .CLK1(1'b0),
        .IOCE(serdes_strobe),
        .RST(rst),
        .CLKDIV(gclk),
        .SHIFTIN(cascade), // Cascade input for complete data
        .BITSLIP(bitslip),
        .FABRICOUT(),
        .Q4(dout[4]),
        .Q3(dout[5]),
        .Q2(dout[6]),
        .Q1(),
        .DFB(),
        .CFB0(),
        .CFB1(),
        .VALID(),
        .INCDEC(),
        .SHIFTOUT(pd_edge)
    );
    
endmodule
`default_nettype wire
