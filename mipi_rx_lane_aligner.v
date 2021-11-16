`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting Zhang
// 
// Create Date:    00:29:31 11/11/2021 
// Design Name:    caster
// Module Name:    mipi_rx_lane_aligner 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//   Align multiple lanes to form a synced output
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mipi_lane_aligner(
        clk, rst, din, validin, dout, validout, error
    );
    
    // Note: when changing the DEPTH, beware of the state reg width
    parameter DEPTH = 3;
    parameter LANES = 4;
    parameter LANE_MASK = 4'b1111;

    input  wire                 clk;
    input  wire                 rst;
    input  wire [LANES*8-1:0]   din;
    input  wire [LANES-1:0]     validin;
    output reg  [LANES*8-1:0]   dout;
    output reg                  validout;
    output reg                  error;
    
    // State 0 is not aligned
    // State 1 to DEPTH-1 is aligning in progress
    // State DEPTH is aligned
    reg [2:0]           state;
    reg [LANES*8-1:0]   dbuffer [DEPTH-1:0];
    reg [LANES-1:0]     valid [DEPTH-1:0];
    reg [DEPTH-1:0]     offset [LANES-1:0];
    reg [LANES-1:0]     aligned;
    
    // Comb result, check for all lane valid before output to reg
    reg [LANES-1:0]     out_valid;
    reg [LANES*8-1:0]   out_data;
    
    reg [3:0] i;
    
    // Aligner
    always @(posedge clk) begin
        if (rst) begin
            state <= 0;
            aligned <= 0;
            error <= 1'b0;
            validout <= 1'b0;
        end
        else begin
            if (state == 0) begin
                if (validin) begin
                    for (i = 0; i < LANES; i = i + 1) begin
                        if (validin[i]) begin
                            offset[i] <= state;
                        end
                    end
                    aligned <= validin;
                    state <= 1;
                end
            end
            else if (state == DEPTH) begin
                if (aligned != LANE_MASK) begin
                    error <= 1'b1;
                    state <= 0;
                end
                else begin
                    out_valid = 0;
                    out_data = 0;
                    for (i = 0; i < LANES; i = i + 1) begin
                        out_data[i*8+7 -: 8] = dbuffer[offset[i]][i*8+7 -: 8];
                        out_valid[i] = valid[offset[i]][i];
                    end
                    
                    if (out_valid == LANE_MASK) begin
                        validout <= 1'b1;
                        dout <= out_data;
                    end
                    else begin
                        validout <= 1'b0;
                        dout <= 0;
                        state <= 0;
                    end
                end
            end
            else begin
                for (i = 0; i < LANES; i = i + 1) begin
                    if (validin[i] && !aligned[i]) begin
                        offset[i] <= state;
                    end
                end
                aligned <= aligned | validin;
                state <= state + 1;
            end
        end
    end
    
    // Data buffer
    always @(posedge clk) begin
        if (rst) begin
            dbuffer[DEPTH - 1] <= 0;
            valid[DEPTH - 1] <= 0;
        end
        else begin
            dbuffer[DEPTH - 1] <= din;
            valid[DEPTH - 1] <= validin;
        end
        for (i = 0; i < DEPTH - 1; i = i + 1) begin
            dbuffer[i] <= dbuffer[i + 1];
            valid[i] <= valid[i + 1];
        end
    end

endmodule
