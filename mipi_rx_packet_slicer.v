`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting Zhang 
// 
// Create Date:    13:45:32 11/11/2021 
// Design Name:    caster
// Module Name:    mipi_rx_packet_slicer 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//   Slice the bitstrem into packets up to 1 packet per clock. Because the MIPI
//   spec doesn't require the packet size to be integer multiple of lane count,
//   the incoming bytes from lane should be from different packets.
//   To avoid overflowing the internal buffer, ECC bytes are stripped out.
//   This would only work with LANES from 2 to 4. 1 lane system doesn't need this
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//   
//
//////////////////////////////////////////////////////////////////////////////////
module mipi_rx_packet_slicer(
        clk, rst, din, validin, dout, validout, pktheader
    );
    
    parameter LANES = 4;
    // NOTE: the byte dropping logic only work with 4 lanes
    
    input  wire                 clk;
    input  wire                 rst;
    input  wire [LANES*8-1:0]   din;
    input  wire                 validin;
    output reg  [LANES*8-1:0]   dout;
    output wire                 validout;
    output reg                  pktheader;

    reg  [1:0]          offset;
    reg  [LANES*8-1:0]  din_last;
    reg                 valid_last;
    wire [LANES*8-1:0]  din_rev;
    wire [LANES*16-1:0] d = {din_last, din_rev};
    
    wire                pkt_end;
    reg  [1:0]          state;
    reg                 valid_mask;
    reg  [15:0]         pkt_remaining;
    wire [LANES*8-1:0]  pkt_current = d[offset*8 +: LANES*8];
    wire [5:0]          pkt_dt = pkt_current[29:24];
    wire [15:0]         pkt_size = {pkt_current[15:8], pkt_current[23:16]};
    wire [15:0]         pkt_remaining_next = pkt_remaining - LANES;
    
    genvar i;
    generate
    for (i = 0; i < LANES; i = i + 1) begin
        assign din_rev[i*8 +: 8] = din[(LANES-1-i)*8 +: 8];
    end
    endgenerate
    
    assign validout = valid_last;

    always @(posedge clk) begin
        if (rst) begin
            offset <= 0;
            state <= 0;
            valid_mask <= 1;
            valid_last <= 0;
        end
        else begin
            din_last <= din_rev;
            valid_last <= validin;
            dout <= pkt_current;
            if (state == 2'd0) begin
                if (validin) begin
                    if ((pkt_dt == 6'h01) ||
                        (pkt_dt == 6'h11) ||
                        (pkt_dt == 6'h21) ||
                        (pkt_dt == 6'h31)) begin
                        // Short packet
                        state <= 0;
                    end
                    else begin
                        // Long packet
                        pkt_remaining <= pkt_size + 2;
                        state <= 1;
                    end
                    pktheader <= 1;
                end
                else begin
                    // lose sync, reset
                    offset <= 0;
                end
            end
            else if (state == 2'd1) begin
                // Previously in long packet mode
                // check for packet end
                if (pkt_remaining_next < LANES) begin
                    if (pkt_remaining_next <= offset) begin
                        // Dropping CRC bytes to avoid overflow
                        state <= 2'd0;
                        pktheader <= 0;
                        offset <= offset - pkt_remaining_next;
                        pkt_remaining <= pkt_remaining_next;
                    end
                    else begin
                        // Shouldn't be dropped
                        state <= 2'd2;
                        pktheader <= 0;
                    end
                end
                else begin
                    pkt_remaining <= pkt_remaining_next;
                    pktheader <= 0;
                end
            end
            else if (state == 2'd2) begin
                state <= 2'd0;
                offset <= offset + (4 - pkt_remaining);
                pktheader <= 0;
            end
        end
    end

endmodule
