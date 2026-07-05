// Copyright Wenting Zhang 2026
//
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2
//
// vin_source_ctrl.v
// Controls the one-way internal-to-live video source transition.
`timescale 1ns / 1ps
`default_nettype none

module vin_source_ctrl(
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] request_source,
    input  wire       live_valid,
    input  wire       live_vsync,
    input  wire       internal_frame_done,
    input  wire       memif_quiescent,
    output reg  [2:0] selected_source,
    output wire       stop_new_frame,
    output wire       source_reset,
    output wire       live_selected,
    output wire       internal_selected,
    output wire       live_lost,
    output wire [2:0] state_dbg
);

    localparam REQ_INTERNAL = 2'd0;
    localparam REQ_DPI = 2'd1;
    localparam REQ_FPDLINK = 2'd2;

    localparam OUT_INTERNAL = 3'd0;
    localparam OUT_DPI = 3'd1;
    localparam OUT_FPDLINK = 3'd2;

    localparam SRC_INTERNAL = 3'd0;
    localparam SRC_ARM_LIVE = 3'd1;
    localparam SRC_QUIESCE_INTERNAL = 3'd2;
    localparam SRC_RESET_LIVE = 3'd3;
    localparam SRC_WAIT_LIVE_FRAME = 3'd4;
    localparam SRC_LIVE = 3'd5;
    localparam SRC_LOST = 3'd6;

    reg [2:0] state = SRC_INTERNAL;
    reg [1:0] armed_source = REQ_INTERNAL;
    reg [3:0] reset_count = 4'd0;
    initial selected_source = OUT_INTERNAL;

    assign stop_new_frame = (state == SRC_QUIESCE_INTERNAL) ||
            (state == SRC_RESET_LIVE) || (state == SRC_WAIT_LIVE_FRAME);
    assign source_reset = (state == SRC_RESET_LIVE);
    assign live_selected = (state == SRC_LIVE);
    assign internal_selected = (selected_source == OUT_INTERNAL);
    assign live_lost = (state == SRC_LOST);
    assign state_dbg = state;

    wire request_is_live = (request_source == REQ_DPI) ||
            (request_source == REQ_FPDLINK);
    wire request_changed = request_source != armed_source;

    always @(posedge clk) begin
        case (state)
        SRC_INTERNAL: begin
            selected_source <= OUT_INTERNAL;
            reset_count <= 4'd0;
            armed_source <= request_source;
            if (request_is_live && live_valid)
                state <= SRC_ARM_LIVE;
        end
        SRC_ARM_LIVE: begin
            if (!request_is_live || !live_valid || request_changed) begin
                state <= SRC_INTERNAL;
            end
            else if (internal_frame_done) begin
                state <= SRC_QUIESCE_INTERNAL;
            end
        end
        SRC_QUIESCE_INTERNAL: begin
            if (!request_is_live || !live_valid || request_changed) begin
                state <= SRC_INTERNAL;
            end
            else if (memif_quiescent) begin
                reset_count <= 4'd0;
                state <= SRC_RESET_LIVE;
            end
        end
        SRC_RESET_LIVE: begin
            if (!request_is_live || !live_valid || request_changed) begin
                state <= SRC_INTERNAL;
            end
            else if (reset_count == 4'd7) begin
                selected_source <= (armed_source == REQ_DPI) ?
                        OUT_DPI : OUT_FPDLINK;
                state <= SRC_WAIT_LIVE_FRAME;
            end
            else begin
                reset_count <= reset_count + 4'd1;
            end
        end
        SRC_WAIT_LIVE_FRAME: begin
            if (!request_is_live || !live_valid || request_changed) begin
                selected_source <= OUT_INTERNAL;
                state <= SRC_INTERNAL;
            end
            else if (live_vsync) begin
                state <= SRC_LIVE;
            end
        end
        SRC_LIVE: begin
            if (!request_is_live || !live_valid || request_changed)
                state <= SRC_LOST;
        end
        SRC_LOST: begin
        end
        default: begin
            state <= SRC_INTERNAL;
            selected_source <= OUT_INTERNAL;
        end
        endcase

        if (rst) begin
            state <= SRC_INTERNAL;
            armed_source <= REQ_INTERNAL;
            selected_source <= OUT_INTERNAL;
            reset_count <= 4'd0;
        end
    end

endmodule

`default_nettype wire
