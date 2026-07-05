// Copyright Wenting Zhang 2026
//
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2
//
// video_timing_monitor.v
// Measures decoded video timing in the input pixel-group clock domain.
`timescale 1ns / 1ps
`default_nettype none

module video_timing_monitor(
    input  wire        clk,
    input  wire        rst,
    input  wire        lock,
    input  wire        vsync,
    input  wire        hsync,
    input  wire        de,
    input  wire [11:0] exp_hact,
    input  wire [11:0] exp_vact,
    output reg         stable,
    output reg         supported,
    output reg [11:0]  meas_hact,
    output reg [11:0]  meas_vact,
    output reg [11:0]  meas_htotal,
    output reg [11:0]  meas_vtotal,
    output reg [3:0]   stable_frames
);

    reg last_vsync;
    reg last_hsync;
    reg seen_line;
    reg seen_frame;
    reg [11:0] line_hact;
    reg [11:0] line_total;
    reg [11:0] frame_hact;
    reg [11:0] frame_vact;
    reg [11:0] frame_vtotal;
    reg [11:0] prev_hact;
    reg [11:0] prev_vact;
    reg [11:0] prev_htotal;
    reg [11:0] prev_vtotal;

    wire vsync_rise = vsync && !last_vsync;
    wire hsync_rise = hsync && !last_hsync;

    wire [11:0] final_line_hact = line_hact + (de ? 12'd1 : 12'd0);
    wire [11:0] final_frame_hact = (final_line_hact != 12'd0) ?
            final_line_hact : frame_hact;
    wire [11:0] final_frame_vact = frame_vact +
            ((seen_line && (final_line_hact != 12'd0)) ? 12'd1 : 12'd0);
    wire [11:0] final_frame_vtotal = frame_vtotal +
            (seen_line ? 12'd1 : 12'd0);
    wire frame_matches_previous =
            (final_frame_hact == prev_hact) &&
            (final_frame_vact == prev_vact) &&
            (meas_htotal == prev_htotal) &&
            (final_frame_vtotal == prev_vtotal);
    wire [3:0] stable_frames_next = frame_matches_previous ?
            ((stable_frames == 4'hf) ? 4'hf : (stable_frames + 4'd1)) : 4'd1;

    always @(posedge clk) begin
        last_vsync <= vsync;
        last_hsync <= hsync;

        if (rst || !lock) begin
            stable <= 1'b0;
            supported <= 1'b0;
            meas_hact <= 12'd0;
            meas_vact <= 12'd0;
            meas_htotal <= 12'd0;
            meas_vtotal <= 12'd0;
            stable_frames <= 4'd0;
            seen_line <= 1'b0;
            seen_frame <= 1'b0;
            line_hact <= 12'd0;
            line_total <= 12'd0;
            frame_hact <= 12'd0;
            frame_vact <= 12'd0;
            frame_vtotal <= 12'd0;
            prev_hact <= 12'd0;
            prev_vact <= 12'd0;
            prev_htotal <= 12'd0;
            prev_vtotal <= 12'd0;
            last_vsync <= 1'b0;
            last_hsync <= 1'b0;
        end
        else if (vsync_rise) begin
            if (seen_frame) begin
                meas_hact <= final_frame_hact;
                meas_vact <= final_frame_vact;
                meas_vtotal <= final_frame_vtotal;
                stable_frames <= stable_frames_next;
                stable <= stable_frames_next >= 4'd3;
                supported <= (stable_frames_next >= 4'd3) &&
                        (final_frame_hact == exp_hact) &&
                        (final_frame_vact == exp_vact);
                prev_hact <= final_frame_hact;
                prev_vact <= final_frame_vact;
                prev_htotal <= meas_htotal;
                prev_vtotal <= final_frame_vtotal;
            end
            seen_frame <= 1'b1;
            seen_line <= 1'b0;
            line_hact <= 12'd0;
            line_total <= 12'd0;
            frame_hact <= 12'd0;
            frame_vact <= 12'd0;
            frame_vtotal <= 12'd0;
        end
        else if (hsync_rise) begin
            seen_frame <= 1'b1;
            if (seen_line) begin
                if (line_hact != 12'd0) begin
                    frame_hact <= line_hact;
                    frame_vact <= frame_vact + 12'd1;
                end
                frame_vtotal <= frame_vtotal + 12'd1;
                meas_htotal <= line_total;
            end
            seen_line <= 1'b1;
            line_hact <= de ? 12'd1 : 12'd0;
            line_total <= 12'd1;
        end
        else if (seen_line) begin
            line_total <= line_total + 12'd1;
            if (de)
                line_hact <= line_hact + 12'd1;
        end
    end

endmodule

`default_nettype wire
