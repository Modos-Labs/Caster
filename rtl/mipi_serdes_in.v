`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting Zhang
// 
// Create Date:    03:01:00 11/10/2021 
// Design Name:    caster
// Module Name:    serdes_in
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//   Generic diff 1:8 DDR deserializer
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mipi_serdes_in(rst, cp, cn, dp, dn, gclk, dout);
    
    parameter integer LANES = 4;
    
    input  wire                 rst;
    input  wire                 cp;
    input  wire                 cn;
    input  wire [LANES-1:0]     dp;
    input  wire [LANES-1:0]     dn;
    output wire                 gclk;   // Fabric clock, /4 DDR clock
    output wire [LANES*8-1:0]   dout;   // Unaligned data output
    
    wire             cal_m;     // Master IODELAY calibration enable
    wire             cal_s;     // Slave IODELAY calibration enable
    wire             iod_rst;   // IODELAY reset input
    wire [LANES-1:0] inc;       // IODELAY increment counter
    wire [LANES-1:0] ce;        // IODELAY clock enable input
    wire [LANES-1:0] busy;      // Slave IODELAY sync/ cal finish output
    wire [LANES-1:0] valid;     // Master ISERDES phase detector valid output
    wire [LANES-1:0] incdec;    // Master ISERDES phase detector result output

    // SerDes block clock, 2x DDR clock
    wire ioclk_p, ioclk_n;
    // SerDes block strobe
    wire serdes_strobe;

    mipi_serdes_clkin mipi_serdes_clkin (
        .clk_p(dsi_cp),
        .clk_n(dsi_cn),
        .ioclk_p(ioclk_p),
        .ioclk_n(ioclk_n),
        .serdes_strobe(serdes_strobe),
        .gclk(gclk)
    );
    
    genvar i;
    generate
    for (i = 0; i < D; i = i + 1)
    begin
        mipi_serdes_datain mipi_serdes_datain (
            // Clock and reset
            .gclk(gclk),
            .rst(rst),
            // Serdes interface
            .dat_p(dp[i]),
            .dat_n(dn[i]),
            .ioclk_p(ioclk_p),
            .ioclk_n(ioclk_n),
            .serdes_strobe(serdes_strobe),
            .dout(dout[i*8+7 -: 8]),
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
    
    phase_detector #(
        .D(LANES * 2)
    )
    phase_detector (
        .use_phase_detector(1'b1),
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
