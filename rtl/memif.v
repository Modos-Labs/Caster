// Copyright Modos / Wenting Zhang 2023
//
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2
//
// You may redistribute and modify this documentation and make products using
// it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl). This
// documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
// INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A
// PARTICULAR PURPOSE. Please see the CERN-OHL-P v2 for applicable conditions
//
// memif.v
// The memif module reads the VRAM via the read port linearly through the whole
// framebuffer, and writes the VRAM via the write port at the same time.
`default_nettype none
`timescale 1ns / 1ps
module memif(
    // Clock and reset
    input  wire         clk,
    input  wire         rst,
    // Sync
    input  wire         enable,
    input  wire         vsync,
    // Pixel output interface
    output wire [127:0] pix_read,
    output wire         pix_read_valid,
    input  wire         pix_read_ready,
    // Pixel input interface
    input  wire [127:0] pix_write,
    input  wire         pix_write_valid,
    output wire         pix_write_ready,
    // To MIG
    output reg          mig_cmd_en,
    output reg  [2:0]   mig_cmd_instr,
    output wire [5:0]   mig_cmd_bl,
    output reg  [29:0]  mig_cmd_byte_addr,
    input  wire         mig_cmd_empty, // unused
    input  wire         mig_cmd_full,
    output reg          mig_wr_en,
    output wire [15:0]  mig_wr_mask,
    output wire [127:0] mig_wr_data,
    input  wire         mig_wr_empty, // unused
    input  wire         mig_wr_full,
    input  wire [6:0]   mig_wr_count, // unused
    input  wire         mig_wr_underrun, // unused
    output wire         mig_rd_en,
    input  wire [127:0] mig_rd_data,
    input  wire         mig_rd_full, // unused
    input  wire         mig_rd_empty,
    input  wire         mig_rd_overflow, // unused
    input  wire [6:0]   mig_rd_count, // unused
    // Error
    output wire         error
    );

    parameter MAX_ADDRESS = 1600*1200*2; // UXGA, 16 bit per pixel

    localparam BYTE_PER_WORD = 16; // 128 bit bus
    localparam BURST_LENGTH = 16; // Should be at least 2
    localparam BYTE_PER_CMD = BYTE_PER_WORD * BURST_LENGTH;

    // WR state machine
    wire wr_issue_req;
    reg wr_issue_done;

    reg [29:0] wr_byte_address;
    reg [6:0] wr_burst_count;
    reg [2:0] wr_state;

    localparam WR_IDLE = 3'd0;
    localparam WR_PUSH = 3'd1;
    localparam WR_ISSUE = 3'd2;

    wire pix_writing = (!mig_wr_full) && (pix_write_valid);

    always @(posedge clk) begin
        // The WR state machine works as following:
        // Try to fill BURST_LENGTH number of words into WR FIFO
        // Then issue a burst write
        if (rst && !enable) begin
            wr_state <= WR_IDLE;
        end
        else begin
            case (wr_state)
            WR_IDLE: begin
                if (vsync) begin
                    wr_byte_address <= 0;
                    wr_burst_count <= 0;
                    wr_state <= WR_PUSH;
                end
            end
            WR_PUSH: begin
                if (wr_burst_count >= BURST_LENGTH) begin
                    wr_state <= WR_ISSUE;
                    wr_burst_count <= wr_burst_count + pix_writing -
                            BURST_LENGTH;
                end
                else begin
                    wr_burst_count <= wr_burst_count + pix_writing;
                end
            end
            WR_ISSUE: begin
                if (wr_issue_done) begin
                    wr_byte_address <= wr_byte_address + BYTE_PER_CMD;
                    if (wr_byte_address == MAX_ADDRESS - BYTE_PER_CMD) begin
                        wr_state <= WR_IDLE;
                    end
                    else begin
                        wr_state <= WR_PUSH;
                    end
                end
                wr_burst_count <= wr_burst_count + pix_writing;
            end
            default: begin
                // Invalid
                $display("Invalid state in MEMIF FSM");
                wr_state <= WR_IDLE;
            end
            endcase
        end
    end

    assign pix_write_ready = pix_writing;
    always @(posedge clk) begin
        mig_wr_en <= pix_writing; // FIFO has 1 cycle RD latency
    end
    assign mig_wr_data = pix_write;
    assign mig_wr_mask = 16'h0000;
    assign wr_issue_req = (wr_state == WR_ISSUE);

    // RD state machine
    wire rd_issue_req;
    reg rd_issue_done;

    reg [29:0] rd_byte_address;
    reg [1:0] rd_state;

    localparam RD_IDLE = 2'd0;
    localparam RD_WAIT1 = 2'd1;
    localparam RD_WAIT2 = 2'd2;
    localparam RD_ISSUE = 2'd3;
    
    always @(posedge clk) begin
        // RD state machine is a bit different:
        // It always tries to issue RD as long as output is not full
        if (rst && !enable) begin
            rd_state <= RD_IDLE;
        end
        else begin
            case (rd_state)
            RD_IDLE: begin
                if (vsync) begin
                    rd_byte_address <= 0;
                    rd_state <= RD_WAIT2;
                end
            end
            RD_WAIT1: begin
                if (!mig_rd_empty) begin
                    rd_state <= RD_WAIT2;
                end
            end
            RD_WAIT2: begin
                if (pix_read_ready && mig_rd_empty) begin
                    rd_state <= RD_ISSUE;
                end
            end
            RD_ISSUE: begin
                if (rd_issue_done) begin
                    rd_byte_address <= rd_byte_address + BYTE_PER_CMD;
                    if (rd_byte_address == MAX_ADDRESS - BYTE_PER_CMD) begin
                        rd_state <= RD_IDLE;
                    end
                    else begin
                        rd_state <= RD_WAIT1;
                    end
                end
            end
            endcase
        end
    end

    wire pix_reading = (!mig_rd_empty) && (pix_read_ready);
    assign mig_rd_en = pix_reading;
    assign pix_read_valid = pix_reading;
    assign pix_read = mig_rd_data;
    assign rd_issue_req = (rd_state == RD_ISSUE);
    
    // It tries to issue RD first, then tries WR.
    // It currently issues 1 cmd every 2 cycles.
    reg issue_state;
    localparam ISSUE_WAIT = 1'd0;
    localparam ISSUE_ACT = 1'd1;
    // Round robin. RR = 0: prioritize RD; RR = 1: prioritize WR
    reg issue_rr;
    wire issue_rd = rd_issue_req && ((issue_rr == 1'b0) || !wr_issue_req);
    wire issue_wr = !issue_rd && wr_issue_req;

    always @(posedge clk) begin
        if (rst && !enable) begin
            mig_cmd_en <= 1'b0;
            issue_state <= ISSUE_WAIT;
            rd_issue_done <= 1'b0;
            wr_issue_done <= 1'b0;
            issue_rr <= 1'b0;
        end
        else begin
            case (issue_state)
            ISSUE_WAIT: begin
                if (!mig_cmd_full) begin
                    if (issue_rd) begin
                        mig_cmd_instr <= 3'b001;
                        mig_cmd_byte_addr <= rd_byte_address;
                        mig_cmd_en <= 1'b1;
                        rd_issue_done <= 1'b1;
                        issue_state <= ISSUE_ACT;
                        issue_rr <= 1'b1;
                    end
                    else if (issue_wr) begin
                        mig_cmd_instr <= 3'b000;
                        mig_cmd_byte_addr <= wr_byte_address;
                        mig_cmd_en <= 1'b1;
                        wr_issue_done <= 1'b1;
                        issue_state <= ISSUE_ACT;
                        issue_rr <= 1'b0;
                    end
                end
            end
            ISSUE_ACT: begin
                rd_issue_done <= 1'b0;
                wr_issue_done <= 1'b0;
                mig_cmd_en <= 1'b0;
                issue_state <= ISSUE_WAIT;
            end
            endcase
        end
    end

    assign mig_cmd_bl = BURST_LENGTH - 1;
    
    assign error = 1'b0;

endmodule
`default_nettype wire
