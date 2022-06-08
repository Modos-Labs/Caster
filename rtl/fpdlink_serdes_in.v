`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting Zhang
// 
// Create Date:    02:21:00 06/07/2021 
// Design Name:    caster
// Module Name:    serdes_in
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//   FPD-Link I 1:7 LVDS deserializer
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module fpdlink_serdes_in(rst, cp, cn, dp, dn, gclk, dout);
    
    // Possible values:
    // 3: 18bpp single channel
    // 4: 24bpp single channel
    // 6: 18bpp dual channel
    // 8: 24bpp dual channel
    parameter integer LANES = 6;
    
    output wire                 rst;
    input  wire                 cp;
    input  wire                 cn;
    input  wire [LANES-1:0]     dp;
    input  wire [LANES-1:0]     dn;
    output wire                 gclk;   // Fabric clock, at pixel clock rate
    output wire [LANES*7-1:0]   dout;   // Data output
    
    wire             cal_m;     // Master IODELAY calibration enable
    wire             cal_s;     // Slave IODELAY calibration enable
    wire             iod_rst;   // IODELAY reset input
    wire [LANES-1:0] inc;       // IODELAY increment counter
    wire [LANES-1:0] ce;        // IODELAY clock enable input
    wire [LANES-1:0] busy;      // Slave IODELAY sync/ cal finish output
    wire [LANES-1:0] valid;     // Master ISERDES phase detector valid output
    wire [LANES-1:0] incdec;    // Master ISERDES phase detector result output

    // SerDes block clock, 7x CLK lane frequency
    wire ioclk;
    // SerDes block strobe
    wire serdes_strobe;
    // SerDes block bit slip enable
    wire bitslip;

    fpdlink_serdes_clkin fpdlink_serdes_clkin (
        .rst(rst),
        .clk_p(cp),
        .clk_n(cn),
        .ioclk(ioclk),
        .serdes_strobe(serdes_strobe),
        .gclk(gclk),
        .bitslip(bitslip)
    );
    
    genvar i;
    generate
    for (i = 0; i < LANES; i = i + 1)
    begin
        fpdlink_serdes_datain fpdlink_serdes_datain (
            // Clock and reset
            .gclk(gclk),
            .rst(rst),
            // Serdes interface
            .dat_p(dp[i]),
            .dat_n(dn[i]),
            .ioclk(ioclk),
            .serdes_strobe(serdes_strobe),
            .bitslip(bitslip),
            .dout(dout[(LANES - 1 - i)*7+6 -: 7]),
            // Phase detector interface
            .cal_m(cal_m),
            .cal_s(cal_s),
            .iod_rst(iod_rst),
            .inc(inc[i]),
            .ce(ce[i]),
            .busy(busy[i]),
            .valid(valid[i]),
            .incdec(incdec[i])
        );
    end
    endgenerate
    
    // FPD link probably doesn't have enough transitions for PD to work
    phase_detector #(
        .D(LANES)
    )
    phase_detector (
        .use_phase_detector(1'b0),
        .busy(busy),
        .valid(valid),    
        .inc_dec(incdec),    
        .reset(rst),    
        .gclk(gclk),        
        .debug_in(2'b00),        
        .cal_master(cal_m),
        .cal_slave(cal_s),    
        .rst_out(iod_rst),
        .ce(ce),
        .inc(inc),
        .debug()
    );

endmodule
