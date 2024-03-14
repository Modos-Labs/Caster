// Copyright Modos / Wenting Zhang 2024
//
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2
//
// You may redistribute and modify this documentation and make products using
// it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl). This
// documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
// INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A
// PARTICULAR PURPOSE. Please see the CERN-OHL-P v2 for applicable conditions
//
// pixel_processing.v
// Combinational single pixel processing
`timescale 1ns / 1ps
`default_nettype none
`include "defines.vh"
module pixel_processing(
    input  wire [5:0]  csr_lutframe,// Total frames in LUT
    input  wire [1:0]  csr_mindrv,    // Dynamic frame rate cap setting
    input  wire [3:0]  proc_p_or,   // Original pixel
    input  wire        proc_p_bd,   // Bayer dithered pixel to 1-bit
    input  wire        proc_p_n1,   // Blue noise dithered pixel to 1-bit
    input  wire [3:0]  proc_p_n4,   // Blue noise dithered pixel to 4-bit
    input  wire [3:0]  proc_p_e4,   // Error diffusion dithered pixel to 4-bit
    input  wire [15:0] proc_bi,     // Pixel state input from VRAM
    output reg  [15:0] proc_bo,     // Pixel state output to VRAM
    input  wire [1:0]  proc_lut_rd, // Read out from LUT
    output reg  [1:0]  proc_output, // Output to screen
    input  wire [1:0]  op_state,    // Current overall operating state
    input  wire        op_valid,    // External operation enable
    input  wire [7:0]  op_cmd,      // External operation command
    input  wire [7:0]  op_param,    // External operation parameter
    input  wire [7:0]  op_framecnt, // Current overall frame counter for state
    input  wire [5:0]  al_framecnt, // Auto LUT mode frame counter
    output reg         al_diff      // Auto LUT mode input change detected
);

    // Pixel state: 16bits
    // Bit 15-12: Mode
    // Bit 13-12 is shared
    localparam MODE_MANUAL_LUT_NO_DITHER = 2'd0; // 00xx
    localparam MODE_MANUAL_LUT_ERROR_DIFFUSION = 2'd1; // 01xx
    localparam MODE_FAST_MONO_NO_DITHER = 4'd8; // 1000
    localparam MODE_FAST_MONO_BAYER = 4'd9; // 1001
    localparam MODE_FAST_MONO_BLUE_NOISE = 4'd10; // 1010
    localparam MODE_FAST_GREY = 4'd11; // 1011
    localparam MODE_AUTO_LUT_NO_DITHER = 4'd12; // 1100
    localparam MODE_AUTO_LUT_BLUE_NOISE = 4'd13; // 1101

    localparam FASTM_B2W_FRAMES = 6'd9;
    localparam FASTM_W2B_FRAMES = 6'd9;
    //localparam FASTM_B2W_FRAMES = 6'd10;
    //localparam FASTM_W2B_FRAMES = 6'd10;

    //
    localparam FASTG_HOLDOFF_FRAMES = 6'd10;
    localparam FASTG_B2G_FRAMES = 6'd1;
    localparam FASTG_W2G_FRAMES = 6'd1;
    localparam FASTG_SETTLE_FRAMES = 6'd5;

    // In auto LUT mode:
    // Bit 11-8: Reserved
    // Bit 7-4: Source pixel value
    // Bit 3-0: Target pixel value
    // Auto LUT mode uses a global framecounter to keep global synchronization,
    // and insufficient space to keep counter in per pixel state.
    // Just an idea, it's also possible to create a bounding box for all changed
    // pixels and only update inside the bounding box. However ghosting may
    // prove this to be a bad idea.
    // When frame counter is not 0, waveform lookup is in progress.
    // When lookup is in progress, the state is kept in still, until the last
    // frame where the dest value is copied to source value.
    // When lookup is not in progress, the input pixel and source pixel
    // value is compared. If doesn't match, a flag is output to the external
    // logic for determining the region of update. The destination pixel value
    // is always updated.
    // In auto LUT modes, same color update is ignored (does not trigger the
    // clearing process). As a result ghosting could be bad and user will need
    // to use clear button to manually clear the screen. It does avoid the
    // flashing caused by tiny changes on the screen.

    // In manual LUT mode:
    // Bit 13-10: Source pixel value
    // Bit 9-4: Frame counter
    // Bit 3-0: Target pixel value
    // When frame counter is not 0, waveform lookup is in progress.
    // When lookup is in progress, both target and source pixel value are hold
    // still, and the frame counter is decremented.
    // When lookup is not in progress and an external update is request on the
    // region, the input pixel is copied to target pixel value, the old target
    // pixel value (current screen status) is copied to target pixel value, and
    // the frame counter is set to LUT frame length.

    // In fast mono mode:
    // Bit 11-10: Reserved
    // Bit 9-4: Frame counter
    // Bit 3-2: Dynamic frame rate cap
    // Bit 1: Reserved, keep at 0
    // Bit 0: Previous frame pixel value (0 black 1 white)

    // In fast grey 4-level mode:
    // Bit 11-10: Stage
    // Bit 9-4: Frame counter
    // Bit 3-2: Reserved, keep at 0
    // Bit 1-0: Previous frame pixel value
    // It matches, continue the current operation:
    localparam STAGE_DONE = 2'd0; // Screen already settled. No operation
    localparam STAGE_MONO = 2'd1; // Driving to mono (same as fast mono mode)
    localparam STAGE_HOLD = 2'd2; // Hold off (wait before start driving greyscale)
    localparam STAGE_GREY = 2'd3; // Driving to greyscale (non-cancellable)

    // Pixel processing
    wire [1:0] pixel_mode_hi = proc_bi[15:14];
    wire [3:0] pixel_mode = proc_bi[15:12];
    wire [1:0] pixel_stage = proc_bi[11:10];
    wire [5:0] pixel_framecnt = proc_bi[9:4];
    wire [3:0] pixel_autolut_src = proc_bi[7:4];
    wire [3:0] pixel_prev = proc_bi[3:0];
    wire [1:0] pixel_mindrv = proc_bi[3:2];
    wire [5:0] pixel_framecnt_dec = pixel_framecnt - 1;
    wire [1:0] pixel_mindrv_dec = (pixel_mindrv != 2'd0) ? (pixel_mindrv - 2'd1) : 2'd0;
    // Specific to fast mono mode
    wire [5:0] pixel_framecnt_2w = FASTM_B2W_FRAMES - pixel_framecnt + 1;
    wire [5:0] pixel_framecnt_2b = FASTM_W2B_FRAMES - pixel_framecnt + 1;

    // Decode base mode and dither mode
    localparam BASEMODE_MANUAL_LUT = 2'b00;
    localparam BASEMODE_FAST_MONO = 2'b01;
    localparam BASEMODE_FAST_GREY = 2'b10;
    localparam BASEMODE_AUTO_LUT = 2'b11;

    localparam DITHER_NONE = 3'b000;
    localparam DITHER_BAYER = 3'b001;
    localparam DITHER_BN_1BIT = 3'b010;
    localparam DITHER_BN_4BIT = 3'b011;
    localparam DITHER_ED_4BIT = 3'b100;

    // EX op decoding sorta
    wire manual_lut_update_en = op_valid && (op_cmd == `OP_EXT_REDRAW);
    wire set_mode_en = op_valid && (op_cmd == `OP_EXT_SETMODE);
    wire clear_en = op_valid && (op_cmd == `OP_EXT_REDRAW);
    wire force_clear = (set_mode_en && (op_framecnt != 0)) || clear_en;
    wire set_mode_apply = set_mode_en && (op_framecnt == 0);

    reg [1:0] pixel_basemode;
    reg [2:0] pixel_dither;
    always @(*) begin
        case (pixel_mode_hi)
        MODE_MANUAL_LUT_NO_DITHER: begin
            pixel_basemode = BASEMODE_MANUAL_LUT;
            pixel_dither = DITHER_NONE;
        end
        MODE_MANUAL_LUT_ERROR_DIFFUSION: begin
            pixel_basemode = BASEMODE_MANUAL_LUT;
            pixel_dither = DITHER_ED_4BIT;
        end
        default: begin
            case (pixel_mode) 
            MODE_FAST_MONO_NO_DITHER: begin
                pixel_basemode = BASEMODE_FAST_MONO;
                pixel_dither = DITHER_NONE;
            end
            MODE_FAST_MONO_BAYER: begin
                pixel_basemode = BASEMODE_FAST_MONO;
                pixel_dither = DITHER_BAYER;
            end
            MODE_FAST_MONO_BLUE_NOISE: begin
                pixel_basemode = BASEMODE_FAST_MONO;
                pixel_dither = DITHER_BN_1BIT;
            end
            MODE_FAST_GREY: begin
                pixel_basemode = BASEMODE_FAST_GREY;
                pixel_dither = DITHER_NONE;
            end
            MODE_AUTO_LUT_NO_DITHER: begin
                pixel_basemode = BASEMODE_AUTO_LUT;
                pixel_dither = DITHER_NONE;
            end
            MODE_AUTO_LUT_BLUE_NOISE: begin
                pixel_basemode = BASEMODE_AUTO_LUT;
                pixel_dither = DITHER_BN_4BIT;
            end
            default: begin
                // Fallback, todo: report this as an error
                pixel_basemode = BASEMODE_FAST_MONO;
                pixel_dither = DITHER_NONE;
            end
            endcase
        end
        endcase
    end

    wire [3:0] clear_color =
        ((pixel_basemode == BASEMODE_AUTO_LUT) ||
        (pixel_basemode == BASEMODE_MANUAL_LUT)) ? 4'hF :
        ((op_framecnt[4:3] == 2'b11) ? 4'h0 :
        (op_framecnt[5] ? 4'h0 : 4'hF));

    /* verilator lint_off UNUSEDSIGNAL */
    // Only 4 MSBs used
    wire [7:0] proc_p_li; // linear
    /* verilator lint_on UNUSEDSIGNAL */
    // Let it optimize, only 4b in and 4b out used
    degamma degamma (
        .in({proc_p_or, proc_p_or[1:0]}),
        .out(proc_p_li)
    );

    wire [3:0] proc_vin = force_clear ? clear_color :
        (pixel_basemode == BASEMODE_FAST_GREY) ? (proc_p_li[7:4]) :
        (pixel_dither == DITHER_NONE) ? (proc_p_or) :
        (pixel_dither == DITHER_BAYER) ? ({4{proc_p_bd}}) :
        (pixel_dither == DITHER_BN_1BIT) ? ({4{proc_p_n1}}) :
        (pixel_dither == DITHER_BN_4BIT) ? (proc_p_n4) : {proc_p_e4};

    `define NO_DRIVE    2'b00
    `define DRIVE_BLACK 2'b01
    `define DRIVE_WHITE 2'b10

    wire [1:0] drive_towards_input = proc_vin[3] ? `DRIVE_WHITE: `DRIVE_BLACK;

    always @(*) begin
        // Normal mode, init mode override later
        al_diff = 1'b0;
        case (pixel_basemode)
        BASEMODE_MANUAL_LUT: begin
            if (pixel_framecnt != 0) begin
                // Update in progress, ignore update/ external request
                proc_output = proc_lut_rd;
                proc_bo = {proc_bi[15:10], pixel_framecnt_dec, proc_bi[3:0]};
            end
            else begin
                proc_output = `NO_DRIVE; // TODO: Reduce this latency
                if (manual_lut_update_en || force_clear) begin
                    // Update requested, initiate update
                    proc_bo = {proc_bi[15:14], pixel_prev, csr_lutframe, proc_vin};
                end
                else begin
                    proc_bo = proc_bi;
                end
            end
        end
        BASEMODE_AUTO_LUT: begin
            if (al_framecnt != 0) begin
                // Update in progress
                proc_output = proc_lut_rd;
                if (al_framecnt == 1) begin
                    // Last frame, copy destination value to source value
                    proc_bo = {proc_bi[15:8], pixel_prev, proc_vin};
                end
                else begin
                    proc_bo = proc_bi;
                end
            end
            else begin
                // Not updating, keep old source, update destination
                proc_output = `NO_DRIVE;
                proc_bo = {proc_bi[15:4], proc_vin};
                if (proc_vin != pixel_autolut_src)
                    al_diff = 1'b1;
            end
        end
        BASEMODE_FAST_MONO: begin
            if (pixel_framecnt != 0) begin
                // Dynamic frame rate cap:
                // Once the pixel state is changed, the DYFRC field is reset to
                // the CSR val.
                // The field value is then decremented every frame until 0
                // Change to a new color is only allowed if the field is 0
                // Currently updating
                if ((proc_vin[3] != pixel_prev[0]) && (pixel_mindrv == 2'd0)) begin
                    // Pixel state changed
                    proc_output = drive_towards_input;
                    proc_bo = proc_vin[3] ? (
                        {proc_bi[15:10], pixel_framecnt_2w, csr_mindrv, 2'd1}
                    ) : {proc_bi[15:10], pixel_framecnt_2b, csr_mindrv, 2'd0};
                end
                else begin
                    // Pixel state not changed
                    proc_output = pixel_prev[0] ? `DRIVE_WHITE : `DRIVE_BLACK;
                    proc_bo = {proc_bi[15:10], pixel_framecnt_dec, pixel_mindrv_dec, proc_bi[1:0]};
                end
            end
            else begin
                // Not currently updating
                if (proc_vin[3] != pixel_prev[0]) begin
                    // Pixel state changed
                    proc_output = drive_towards_input;
                    proc_bo = proc_vin[3] ? (
                        {proc_bi[15:10], FASTM_B2W_FRAMES, csr_mindrv, 2'd1}
                    ) : {proc_bi[15:10], FASTM_W2B_FRAMES, csr_mindrv, 2'd0};
                end
                else begin
                    // Pixel state not changed
                    proc_output = `NO_DRIVE;
                    proc_bo = proc_bi;
                end
            end
        end
        BASEMODE_FAST_GREY: begin
            // Update strategy is similar in mono and hold stage (only binary)
            if (pixel_stage == STAGE_MONO) begin
                // Currently updating
                proc_output = drive_towards_input;
                if (proc_vin[3] != pixel_prev[1]) begin
                    // Pixel state changed
                    proc_bo = proc_vin[3] ? (
                        {proc_bi[15:12], STAGE_MONO, FASTM_B2W_FRAMES, 2'b00, proc_vin[3:2]}
                    ) : {proc_bi[15:12], STAGE_MONO, FASTM_W2B_FRAMES, 2'b00, proc_vin[3:2]};
                end
                else begin
                    proc_output = pixel_prev[1] ? `DRIVE_WHITE : `DRIVE_BLACK;
                    // Pixel didn't change, continue
                    if (pixel_framecnt == 1) begin
                        proc_bo = {proc_bi[15:12], STAGE_HOLD, FASTG_HOLDOFF_FRAMES, proc_bi[3:0]};
                    end
                    else begin
                        proc_bo = {proc_bi[15:10], pixel_framecnt_dec, proc_bi[3:0]};
                    end
                end
            end
            else if (pixel_stage == STAGE_HOLD) begin
                // Not currently updating, holding
                if (proc_vin[3] != pixel_prev[1]) begin
                    // Pixel state changed
                    proc_output = drive_towards_input;
                    proc_bo = proc_vin[3] ? (
                        {proc_bi[15:12], STAGE_MONO, FASTM_B2W_FRAMES, 2'b00, proc_vin[3:2]}
                    ) : {proc_bi[15:12], STAGE_MONO, FASTM_W2B_FRAMES, 2'b00, proc_vin[3:2]};
                end
                else begin
                    // Pixel state not changed
                    proc_output = `NO_DRIVE;
                    // Hold mode, update status counter
                    if (pixel_framecnt == 0) begin
                        proc_bo = (proc_vin[3:2] == 2'b10) ? (
                                {proc_bi[15:12], STAGE_GREY, FASTG_W2G_FRAMES + FASTG_SETTLE_FRAMES, 2'b00, proc_vin[3:2]}
                            ) : (proc_vin[3:2] == 2'b01) ? (
                                {proc_bi[15:12], STAGE_GREY, FASTG_B2G_FRAMES + FASTG_SETTLE_FRAMES, 2'b00, proc_vin[3:2]}
                            ) : (
                                {proc_bi[15:12], STAGE_DONE, 6'd0, 2'b00, proc_vin[3:2]}
                            );
                    end
                    else begin
                        proc_bo = {proc_bi[15:10], pixel_framecnt_dec, proc_bi[3:0]};
                    end
                end
            end
            else if (pixel_stage == STAGE_GREY) begin
                // Keep driving grey
                if (pixel_framecnt > FASTG_SETTLE_FRAMES) begin
                    proc_output = pixel_prev[1] ? `DRIVE_BLACK : `DRIVE_WHITE;
                end
                else begin
                    proc_output = `NO_DRIVE;
                end
                if (pixel_framecnt == 0) begin
                    proc_bo = {proc_bi[15:12], STAGE_DONE, 6'd0, proc_bi[3:0]};
                end
                else begin
                    proc_bo = {proc_bi[15:10], pixel_framecnt_dec, proc_bi[3:0]};
                end
            end
            else if (pixel_stage == STAGE_DONE) begin
                if (proc_vin[3:2] != pixel_prev[1:0]) begin
                    // Pixel state changed
                    proc_output = drive_towards_input;
                    proc_bo = proc_vin[3] ? (
                        {proc_bi[15:12], STAGE_MONO, FASTM_B2W_FRAMES, 2'b00, proc_vin[3:2]}
                    ) : {proc_bi[15:12], STAGE_MONO, FASTM_W2B_FRAMES, 2'b00, proc_vin[3:2]};
                end
                else begin
                    // Pixel state not changed
                    proc_output = `NO_DRIVE;
                    proc_bo = proc_bi;
                end
            end
        end
        endcase

        // If set mode is active, override previous
        if (set_mode_apply) begin
            // Use the initial state preset
            proc_bo = `DEFAULT_MODE; // Default
            case (op_param)
            `SETMODE_MANUAL_LUT_NO_DITHER:
                proc_bo = {MODE_MANUAL_LUT_NO_DITHER, 4'd0, 6'd0, 4'd15};
            `SETMODE_MANUAL_LUT_ERROR_DIFFUSION:
                proc_bo = {MODE_MANUAL_LUT_ERROR_DIFFUSION, 4'd0, 6'd0, 4'd15};
            `SETMODE_FAST_MONO_NO_DITHER:
                proc_bo = {MODE_FAST_MONO_NO_DITHER, 2'b0, 6'd0, 3'b0, 1'b1};
            `SETMODE_FAST_MONO_BAYER:
                proc_bo = {MODE_FAST_MONO_BAYER, 2'b0, 6'd0, 3'b0, 1'b1};
            `SETMODE_FAST_MONO_BLUE_NOISE:
                proc_bo = {MODE_FAST_MONO_BLUE_NOISE, 2'b0, 6'd0, 3'b0, 1'b1};
            `SETMODE_FAST_GREY:
                proc_bo = {MODE_FAST_GREY, STAGE_DONE, 6'd0, 2'b0, 2'b11};
            `SETMODE_AUTO_LUT_NO_DITHER:
                proc_bo = {MODE_AUTO_LUT_NO_DITHER, 4'd0, 4'd15, 4'd0};
            `SETMODE_AUTO_LUT_BLUE_NOISE:
                proc_bo = {MODE_AUTO_LUT_BLUE_NOISE, 4'd0, 4'd15, 4'd0};
            default: begin
                // Invalid input detected, default back to manual lut
                proc_bo = {MODE_MANUAL_LUT_NO_DITHER, 4'd0, 6'd0, 4'd15};
                $display("Invalid set mode");
            end
            endcase
        end

        // If in init mode, override previous
        if (op_state == `OP_INIT) begin
            // one round is 128 clock cycle [6:0], but down counting
            // 6543210
            // x111xxx - 0-7 / 64-71 noop
            // 1xxxxxx - 8-63 black
            // 0xxxxxx - 72-127 white
            if (op_framecnt[5:3] == 3'b111)
                proc_output = `NO_DRIVE;
            else if (op_framecnt[6] == 1'b1)
                proc_output = `DRIVE_BLACK;
            else
                proc_output = `DRIVE_WHITE;
            // Set initial mode
            proc_bo = `DEFAULT_MODE;
        end
    end

endmodule
`default_nettype wire
