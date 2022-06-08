`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting Zhang
// 
// Create Date:    01:05:27 11/10/2021 
// Design Name:    caster
// Module Name:    serdes_clkin 
// Project Name: 
// Target Devices: spartan6
// Tool versions: 
// Description: 
//   Generic diff 1:8 DDR clock receiver based on XAPP1064.
//   Output x2 clock and strobe for serdes, and /4 clock for fabric
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mipi_serdes_clkin(
    input  wire         clk_p,          // CKP pin
    input  wire         clk_n,          // CKN pin
    output wire         ioclk_p,        // IO clock for SerDes blocks
    output wire         ioclk_n,        // IO clock for SerDes blocks
    output wire         serdes_strobe,  // Strobe for SerDes blocks
    output wire         gclk            // Buffered fabric clock
    );

    wire ddly_m; // IODELAY master output
    wire ddly_s; // IODELAY slave output
    wire rxclk_in;
    wire iob_din_p;
    wire iob_din_n;
    
    IBUFDS_DIFF_OUT #(
        .DIFF_TERM("TRUE")
    )
    iob_clk_in (
        .I(clk_p),
        .IB(clk_n),
        .O(iob_din_p),
        .OB(iob_din_n)
    );
    
    IODELAY2 #(
        .DATA_RATE("SDR"),
        .SIM_TAPDELAY_VALUE(49),
        .IDELAY_VALUE(0),
        .IDELAY2_VALUE(0),
        .ODELAY_VALUE(0),
        .IDELAY_MODE("NORMAL"),
        .SERDES_MODE("MASTER"),
        .IDELAY_TYPE("FIXED"),
        .COUNTER_WRAPAROUND("STAY_AT_LIMIT"),
        .DELAY_SRC("IDATAIN")
    )
    iodelay_m (
        .IDATAIN(iob_din_p),// data from master IOB
        .TOUT(),            // tri-state signal to IOB
        .DOUT(),            // output data to IOB
        .T(1'b1),           // tri-state control from OLOGIC/OSERDES2
        .ODATAIN(1'b0),     // data from OLOGIC/OSERDES2
        .DATAOUT(ddly_m),   // output data 1 to ILOGIC/ISERDES2
        .DATAOUT2(),        // output data 2 to ILOGIC/ISERDES2
        .IOCLK0(1'b0),      // high speed clock for calibration
        .IOCLK1(1'b0),      // high speed clock for calibration
        .CLK(1'b0),         // fabric clock for control signals
        .CAL(1'b0),         // calibrate enable signal
        .INC(1'b0),         // increment counter
        .CE(1'b0),          // clock enable
        .RST(1'b0),         // reset delay line to 1/2 max
        .BUSY()             // output when sync/ calibration has finished
    );
    
    IODELAY2 #(
        .DATA_RATE("SDR"),
        .SIM_TAPDELAY_VALUE(49),
        .IDELAY_VALUE(0),
        .IDELAY2_VALUE(0),
        .ODELAY_VALUE(0),
        .IDELAY_MODE("NORMAL"),
        .SERDES_MODE("SLAVE"),
        .IDELAY_TYPE("FIXED"),
        .COUNTER_WRAPAROUND("STAY_AT_LIMIT"),
        .DELAY_SRC("IDATAIN")
    )
    iodelay_m (
        .IDATAIN(iob_din_n),// data from master IOB
        .TOUT(),            // tri-state signal to IOB
        .DOUT(),            // output data to IOB
        .T(1'b1),           // tri-state control from OLOGIC/OSERDES2
        .ODATAIN(1'b0),     // data from OLOGIC/OSERDES2
        .DATAOUT(ddly_s),   // output data 1 to ILOGIC/ISERDES2
        .DATAOUT2(),        // output data 2 to ILOGIC/ISERDES2
        .IOCLK0(1'b0),      // high speed clock for calibration
        .IOCLK1(1'b0),      // high speed clock for calibration
        .CLK(1'b0),         // fabric clock for control signals
        .CAL(1'b0),         // calibrate enable signal
        .INC(1'b0),         // increment counter
        .CE(1'b0),          // clock enable
        .RST(1'b0),         // reset delay line to 1/2 max
        .BUSY()             // output when sync/ calibration has finished
    );
    
    wire gclk_unbuf;
    
    BUFIO2_2CLK #(
        .DIVIDE(8)
    )
    bufio2_2clk (
        .I(ddly_m),
        .IB(ddly_s),
        .IOCLK(ioclk_p),
        .DIVCLK(gclk_unbuf),
        .SERDESSTROBE(serdes_strobe)
    );

    BUFIO2 #(
        .I_INVERT("FALSE"),
        .DIVIDE_BYPASS("FALSE"),
        .USE_DOUBLER("FALSE")
    )
    bufio2 (
        .I(ddly_s),
        .IOCLK(ioclk_n),
        .DIVCLK(),
        .SERDESSTROBE()
    );
    
    BUFG bufg_gclk (
        .I(gclk_unbuf),
        .O(gclk)
    );

endmodule
