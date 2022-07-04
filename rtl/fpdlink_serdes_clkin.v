`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting Zhang
// 
// Create Date:    01:44:18 06/07/2022 
// Design Name:    caster
// Module Name:    serdes_clkin 
// Project Name: 
// Target Devices: spartan6
// Tool versions: 
// Description: 
//   FPD-Link I clock receiver based on XAPP1064.
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module fpdlink_serdes_clkin(
    input  wire rstin,
    output wire rst,            // Async RST
    input  wire clk_p,          // CKP pin
    input  wire clk_n,          // CKN pin
    output wire ioclk,          // IO clock for SerDes blocks
    output wire serdes_strobe,  // Strobe for SerDes blocks
    output wire gclk,           // Buffered fabric clock
    output reg  bitslip         // Bitslip output
    );
    
    parameter DIFF_TERM = "TRUE"; // Intenal differential termination
    parameter CLK_PERIOD = 12.345; // Input clock period, 12.345ns = 81MHz

    wire rxclk_in;
    
    IBUFGDS #(
        .DIFF_TERM(DIFF_TERM)
    )
    ibufgds_clkin (
        .I(clk_p),
        .IB(clk_n),
        .O(rxclk_in)
    );
    
    wire rxpll_locked;
    wire gclk_pll;
    wire ioclk_pll;
    wire fbclk;
    wire pclk;
    wire fbclk_bufio;
    wire pclk_bufio;
    
    PLL_ADV #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT(7),
        .CLKFBOUT_PHASE(0.0),
        .CLKIN1_PERIOD(CLK_PERIOD),
        .CLKIN2_PERIOD(CLK_PERIOD),
        .CLKOUT0_DIVIDE(1),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0.0),
        .CLKOUT1_DIVIDE(1),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT1_PHASE(0.0),
        .CLKOUT2_DIVIDE(7),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT2_PHASE(0.0),
        .CLKOUT3_DIVIDE(7),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT3_PHASE(0.0),
        .CLKOUT4_DIVIDE(7),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT4_PHASE(0.0),
        .CLKOUT5_DIVIDE(7),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT5_PHASE(0.0),
        .COMPENSATION("SOURCE_SYNCHRONOUS"),
        .DIVCLK_DIVIDE(1),
        .CLK_FEEDBACK("CLKOUT0"),
        .REF_JITTER(0.100)
    )
    rxpll (
        .CLKFBDCM(),
        .CLKFBOUT(),
        .CLKOUT0(ioclk_pll),
        .CLKOUT1(),
        .CLKOUT2(gclk_pll),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUTDCM0(),
        .CLKOUTDCM1(),
        .CLKOUTDCM2(),
        .CLKOUTDCM3(),
        .CLKOUTDCM4(),
        .CLKOUTDCM5(),
        .DO(),
        .DRDY(),
        .LOCKED(rxpll_locked),
        .CLKFBIN(fbclk_bufio),
        .CLKIN1(pclk_bufio),
        .CLKIN2(1'b0),
        .CLKINSEL(1'b1),
        .DADDR(5'b00000),
        .DCLK(1'b0),
        .DEN(1'b0),
        .DI(16'h0000),
        .DWE(1'b0),
        .RST(rstin),
        .REL(1'b0)
    );
    
    BUFG bufg_gclk (
        .I(gclk_pll),
        .O(gclk)
    );
    
    wire bufpll_locked;
    
    BUFPLL #(
        .DIVIDE(7)
    )
    bufpll (
        .PLLIN(ioclk_pll),
        .GCLK(gclk),
        .LOCKED(rxpll_locked),
        .IOCLK(ioclk),
        .LOCK(bufpll_locked),
        .SERDESSTROBE(serdes_strobe)
    );
    
    wire pll_locked = rxpll_locked && bufpll_locked;
    assign rst = !pll_locked;
    
    BUFIO2 #(
        .DIVIDE(1),
        .DIVIDE_BYPASS("TRUE")
    )
    bufio2 (
        .I(pclk),
        .IOCLK(),
        .DIVCLK(pclk_bufio),
        .SERDESSTROBE()
    );

    BUFIO2FB #(
        .DIVIDE_BYPASS("TRUE")
    )
    bufio2fb (
        .I(fbclk),
        .O(fbclk_bufio)
    );
    
    wire delayed_data_master; // IODELAY master output
    wire delayed_data_slave;
    
    reg iod_cal; // Calibration enable
    reg iod_rst; // Reset delay line
    wire iod_busy; // Calibration in progress
    
    IODELAY2 #(
        .DATA_RATE("SDR"),
        .SIM_TAPDELAY_VALUE(49),
        .IDELAY_VALUE(0),
        .IDELAY2_VALUE(0),
        .ODELAY_VALUE(0),
        .IDELAY_MODE("NORMAL"),
        .SERDES_MODE("MASTER"),
        .IDELAY_TYPE("VARIABLE_FROM_HALF_MAX"),
        .COUNTER_WRAPAROUND("STAY_AT_LIMIT"),
        .DELAY_SRC("IDATAIN")
    )
    iodelay_master (
        .IDATAIN(rxclk_in),
        .TOUT(),
        .DOUT(),
        .T(1'b1),
        .ODATAIN(1'b0),
        .DATAOUT(delayed_data_master),
        .DATAOUT2(),
        .IOCLK0(ioclk),
        .IOCLK1(1'b0),
        .CLK(gclk),
        .CAL(iod_cal),
        .INC(1'b0),
        .CE(1'b0),
        .RST(iod_rst),
        .BUSY(iod_busy)
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
    iodelay_slave (
        .IDATAIN(rxclk_in),
        .TOUT(),
        .DOUT(),
        .T(1'b1),
        .ODATAIN(1'b0),
        .DATAOUT(delayed_data_slave),
        .DATAOUT2(),
        .IOCLK0(1'b0),
        .IOCLK1(1'b0),
        .CLK(1'b0),
        .CAL(1'b0),
        .INC(1'b0),
        .CE(1'b0),
        .RST(1'b0),
        .BUSY()
    );
    
    wire serdes_pd_edge; // Slave -> Master
    wire serdes_cascade; // Master -> Slave
    wire [6:0] dout;
    
    ISERDES2 #(
        .DATA_WIDTH(7),
        .DATA_RATE("SDR"),
        .BITSLIP_ENABLE("TRUE"),
        .SERDES_MODE("MASTER"),
        .INTERFACE_TYPE("RETIMED")
    )
    iserdes_master (
        .D(delayed_data_master),
        .CE0(1'b1),
        .CLK0(ioclk),
        .CLK1(1'b0),
        .IOCE(serdes_strobe),
        .RST(!bufpll_locked),
        .CLKDIV(gclk),
        .SHIFTIN(serdes_pd_edge),
        .BITSLIP(bitslip),
        .FABRICOUT(),
        .DFB(),
        .CFB0(),
        .CFB1(),
        .Q4(dout[0]),
        .Q3(dout[1]),
        .Q2(dout[2]),
        .Q1(dout[3]),
        .VALID(),
        .INCDEC(),
        .SHIFTOUT(serdes_cascade)
    );
    
    ISERDES2 #(
        .DATA_WIDTH(7),
        .DATA_RATE("SDR"),
        .BITSLIP_ENABLE("TRUE"),
        .SERDES_MODE("SLAVE"),
        .INTERFACE_TYPE("RETIMED")
    )
    iserdes_slave (
        .D(delayed_data_slave),
        .CE0(1'b1),
        .CLK0(ioclk),
        .CLK1(1'b0),
        .IOCE(serdes_strobe),
        .RST(!bufpll_locked),
        .CLKDIV(gclk),
        .SHIFTIN(serdes_cascade),
        .BITSLIP(bitslip),
        .FABRICOUT(),
        .DFB(pclk),
        .CFB0(fbclk),
        .CFB1(),
        .Q4(dout[4]),
        .Q3(dout[5]),
        .Q2(dout[6]),
        .Q1(),
        .VALID(),
        .INCDEC(),
        .SHIFTOUT(serdes_pd_edge)
    );
    
    // State machine for bitslip
    localparam CLK_PATTERN_1 = 7'b1100011;
    localparam CLK_PATTERN_2 = 7'b1100001; // Used in DC balanced mode
    
    localparam STATE_RESET = 0;
    localparam STATE_WAIT_BUSY = 1;
    localparam STATE_WAIT_NOT_BUSY = 2;
    localparam STATE_IOD_RESET = 3;
    localparam STATE_WAIT_RESET = 4;
    localparam STATE_WAIT_WORD = 5;
    localparam STATE_RUNNING = 6;
    
    reg [3:0] state;
    
    reg bitslip_reg;
    reg busy_reg;
    reg [11:0] counter;
    
    always @(posedge gclk) begin
        bitslip <= bitslip_reg;
        busy_reg <= iod_busy;
    end
    
    always @(posedge gclk or posedge rst) begin
        if (rst) begin
            state <= STATE_RESET;
            iod_cal <= 1'b0;
            iod_rst <= 1'b0;
            bitslip_reg <= 1'b0;
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
            case (state)
            STATE_RESET: begin
                // Delay the startup, wait for phase_det
                if ((counter[5]) && (!busy_reg)) begin
                    iod_cal <= 1'b1;
                    state <= STATE_WAIT_BUSY;
                end
            end
            STATE_WAIT_BUSY: begin
                if (busy_reg) begin
                    iod_cal <= 1'b0;
                    state <= STATE_WAIT_NOT_BUSY;
                end
            end
            STATE_WAIT_NOT_BUSY: begin
                if (!busy_reg) begin
                    iod_rst <= 1'b1;
                    state <= STATE_IOD_RESET;
                end
            end
            STATE_IOD_RESET: begin
                iod_rst <= 1'b0;
                state <= STATE_WAIT_RESET;
            end
            STATE_WAIT_RESET: begin
                if (!busy_reg) begin
                    state <= STATE_WAIT_WORD;
                    counter <= 0;
                end
            end
            STATE_WAIT_WORD: begin
                bitslip_reg <= 1'b0;
                if (counter == 7) begin
                    state <= STATE_RUNNING;
                end
            end
            STATE_RUNNING: begin
                if (counter[11]) begin
                    // Recalibrate
                    state <= STATE_RESET;
                    counter <= 0;
                end
                else if ((dout != CLK_PATTERN_1) && (dout != CLK_PATTERN_2)) begin
                    bitslip_reg <= 1'b1;
                    state <= STATE_WAIT_WORD;
                end
            end
            endcase
        end
    end
    
endmodule