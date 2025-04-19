// Copyright Wenting Zhang 2024
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
    input  wire [1:0]  csr_mindrv,  // Dynamic frame rate cap setting
    input  wire [3:0]  proc_p_or,   // Original pixel
    input  wire        proc_p_bd,   // Bayer dithered pixel to 1-bit
    input  wire        proc_p_n1,   // Blue noise dithered pixel to 1-bit
    input  wire [3:0]  proc_p_n4,   // Blue noise dithered pixel to 4-bit
    input  wire [15:0] proc_bi,     // Pixel state input from VRAM
    output reg  [15:0] proc_bo,     // Pixel state output to VRAM
    input  wire [1:0]  proc_lut_rd, // Read out from LUT
    output reg  [1:0]  proc_output, // Output to screen
    input  wire [1:0]  op_state,    // Current overall operating state
    input  wire        op_valid,    // External operation enable
    input  wire [7:0]  op_cmd,      // External operation command
    input  wire [7:0]  op_param,    // External operation parameter
    input  wire [7:0]  op_framecnt, // Current overall frame counter for state
    input  wire [5:0]  al_framecnt  // Auto LUT mode frame counter
);

    // Pixel state: 16bits
    // Bit 15-12: Mode
    // Bit 13-12 is shared
    localparam MODE_MANUAL_LUT_NO_DITHER = 2'd0; // 00xx
    localparam MODE_MANUAL_LUT_BLUE_NOISE = 2'd1; // 01xx
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
    localparam FASTG_HOLDOFF_FRAMES = 6'd1;
    localparam FASTG_B2G_FRAMES = 6'd2;
    localparam FASTG_W2G_FRAMES = 6'd2;
    localparam FASTG_SETTLE_FRAMES = 6'd5;

    localparam AUTOLUT_HOLDOFF_FRAMES = 6'd60;

    wire [5:0] fastg_g2w_frames =
        (pixel_prev == 4'd0) ? 6'd9 : // Black to white
        (pixel_prev == 4'd1) ? 6'd9 :
        (pixel_prev == 4'd2) ? 6'd9 :
        (pixel_prev == 4'd3) ? 6'd9 :
        (pixel_prev == 4'd4) ? 6'd8 :
        (pixel_prev == 4'd5) ? 6'd8 :
        (pixel_prev == 4'd6) ? 6'd8 :
        (pixel_prev == 4'd7) ? 6'd7 :
        (pixel_prev == 4'd8) ? 6'd7 :
        (pixel_prev == 4'd9) ? 6'd6 :
        (pixel_prev == 4'd10) ? 6'd6 :
        (pixel_prev == 4'd11) ? 6'd5 :
        (pixel_prev == 4'd12) ? 6'd4 :
        (pixel_prev == 4'd13) ? 6'd3 :
        (pixel_prev == 4'd14) ? 6'd2 :
                             6'd1;
    wire [5:0] fastg_g2b_frames =
        (pixel_prev == 4'd0) ? 6'b1 : // Black to black
        (pixel_prev == 4'd1) ? 6'd2 :
        (pixel_prev == 4'd2) ? 6'd2 :
        (pixel_prev == 4'd3) ? 6'd3 :
        (pixel_prev == 4'd4) ? 6'd3 :
        (pixel_prev == 4'd5) ? 6'd4 :
        (pixel_prev == 4'd6) ? 6'd4 :
        (pixel_prev == 4'd7) ? 6'd5 :
        (pixel_prev == 4'd8) ? 6'd6 :
        (pixel_prev == 4'd9) ? 6'd7 :
        (pixel_prev == 4'd10) ? 6'd8 :
        (pixel_prev == 4'd11) ? 6'd9 :
        (pixel_prev == 4'd12) ? 6'd9 :
        (pixel_prev == 4'd13) ? 6'd9 :
        (pixel_prev == 4'd14) ? 6'd9 : 6'd9;

    // In auto LUT mode:
    // Bit 11-10: Stage
    // In MONO stage:
    // Bit 9-4: Frame counter
    // Bit 3-2: Dynamic frame rate cap
    // Bit 1: Reserved, keep at 0
    // Bit 0: Previous frame pixel value (0 black 1 white)
    // In DONE/HOLD stage:
    // Bit 9-4: Frame counter
    // Bit 3-0: Last pixel value
    // In GREY stage:
    // Bit 9-8: Reserved
    // Bit 7-4: Source pixel value
    // Bit 3-0: Target pixel value
    // Auto LUT mode is a hybrid between fast mono mode and dithered LUT mode.
    // The update process of each pixel is divided into 4 stages:
    localparam STAGE_DONE = 2'd0; // Screen already settled. No operation
    localparam STAGE_MONO = 2'd1; // Driving to mono (same as fast mono mode)
    localparam STAGE_HOLD = 2'd2; // Hold off (wait before start driving greyscale)
    localparam STAGE_GREY = 2'd3; // Driving to greyscale (non-cancellable)
    // When change is detected on the DONE pixel, it kicks off the update process
    // immediately similar to the fast mono mode, entering the MONO stage.
    // Once the mono update is done, it enters the HOLD stage.
    // If changes are detected during HOLD stage, it goes back to the MONO stage.
    // If the HOLD stage times out (means no changes are ever detected) and global
    // greyscale counter is at 1 (next round starts the next frame), it updates
    // The source and destination colors and enters GREY stage.
    // In the GREY stage it follows the waveform LUT to drive the screen. Once
    // that's done it goes back to the DONE stage.

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

    // Pixel processing
    wire [1:0] pixel_mode_hi = proc_bi[15:14];
    wire [3:0] pixel_mode = proc_bi[15:12];
    wire [1:0] pixel_stage = proc_bi[11:10];
    wire [5:0] pixel_framecnt = proc_bi[9:4];
    wire [3:0] pixel_prev = proc_bi[3:0];
    wire [1:0] pixel_mindrv = proc_bi[3:2];
    wire [5:0] pixel_framecnt_dec = pixel_framecnt - 1;
    wire [1:0] pixel_mindrv_dec = (pixel_mindrv != 2'd0) ? (pixel_mindrv - 2'd1) : 2'd0;
    // Specific to fast mono mode
    wire [5:0] pixel_framecnt_2w = FASTM_B2W_FRAMES - pixel_framecnt + 1;
    wire [5:0] pixel_framecnt_2b = FASTM_W2B_FRAMES - pixel_framecnt + 1;
    wire [3:0] pixel_prev_bext = {4{pixel_prev[0]}};
    wire [3:0] pixel_vin_bext = {4{proc_vin[3]}};

    // Decode base mode and dither mode
    localparam BASEMODE_MANUAL_LUT = 2'b00;
    localparam BASEMODE_FAST_MONO = 2'b01;
    localparam BASEMODE_FAST_GREY = 2'b10;
    localparam BASEMODE_AUTO_LUT = 2'b11;

    localparam DITHER_NONE = 3'b000;
    localparam DITHER_BAYER = 3'b001;
    localparam DITHER_BN_1BIT = 3'b010;
    localparam DITHER_BN_4BIT = 3'b011;

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
        MODE_MANUAL_LUT_BLUE_NOISE: begin
            pixel_basemode = BASEMODE_MANUAL_LUT;
            pixel_dither = DITHER_BN_4BIT;
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
        (pixel_basemode == BASEMODE_MANUAL_LUT) ? 4'hF :
        ((op_framecnt[4:3] == 2'b11) ? 4'h0 :
        (op_framecnt[5] ? 4'h0 : 4'hF));

    /* verilator lint_off UNUSEDSIGNAL */
    // Only 4 MSBs used
    wire [7:0] proc_p_li; // linear
    /* verilator lint_on UNUSEDSIGNAL */
    // Let it optimize, only 4b in and 4b out used
    /*degamma degamma (
        .in({proc_p_or, proc_p_or[1:0]}),
        .out(proc_p_li)
    );*/
    assign proc_p_li = {proc_p_or, 4'b0};

    wire [3:0] proc_vin = force_clear ? clear_color :
        (pixel_basemode == BASEMODE_FAST_GREY) ? (proc_p_li[7:4]) :
        (pixel_dither == DITHER_NONE) ? (proc_p_or) :
        (pixel_dither == DITHER_BAYER) ? ({4{proc_p_bd}}) :
        (pixel_dither == DITHER_BN_1BIT) ? ({4{proc_p_n1}}) :
        (pixel_dither == DITHER_BN_4BIT) ? (proc_p_n4) : {4'd0};

    wire [3:0] proc_vinnd = force_clear ? clear_color : proc_p_li[7:4];

    `define NO_DRIVE    2'b00
    `define DRIVE_BLACK 2'b01
    `define DRIVE_WHITE 2'b10

    wire [1:0] drive_towards_input = proc_vin[3] ? `DRIVE_WHITE: `DRIVE_BLACK;
    wire [1:0] drive_against_input = proc_vin[3] ? `DRIVE_BLACK: `DRIVE_WHITE;

    always @(*) begin
        // Normal mode, init mode override later
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
            if (pixel_stage == STAGE_MONO) begin
                // Framecnt != 0 means in MONO stage
                // Currently updating
                if ((proc_vinnd[3] != pixel_prev[0]) && (pixel_mindrv == 2'd0)) begin
                    // Pixel state changed
                    proc_output = drive_towards_input;
                    proc_bo = proc_vinnd[3] ? (
                        {proc_bi[15:10], pixel_framecnt_2w, csr_mindrv, 2'd1}
                    ) : {proc_bi[15:10], pixel_framecnt_2b, csr_mindrv, 2'd0};
                end
                else begin
                    // Pixel state not changed
                    proc_output = pixel_prev[0] ? `DRIVE_WHITE : `DRIVE_BLACK;
                    // Finishing mono update next frame
                    if (pixel_framecnt == 0) begin
                        // Hold off for some time before start grayscale render
                        proc_bo = {proc_bi[15:12], STAGE_HOLD, AUTOLUT_HOLDOFF_FRAMES - FASTM_B2W_FRAMES, {4{pixel_prev[0]}}};
                    end
                    else begin
                        proc_bo = {proc_bi[15:10], pixel_framecnt_dec, pixel_mindrv_dec, proc_bi[1:0]};
                    end
                end
            end
            else if (pixel_stage == STAGE_HOLD) begin
                // Not currently updating, display in BINARY/ GREYSCALE mode
                if (proc_vinnd[3] != pixel_prev[3]) begin
                    // Binary pixel state changed
                    proc_output = drive_towards_input;
                    proc_bo = proc_vinnd[3] ? (
                        {proc_bi[15:12], STAGE_MONO, FASTM_B2W_FRAMES, csr_mindrv, 2'd1}
                    ) : {proc_bi[15:12], STAGE_MONO, FASTM_W2B_FRAMES, csr_mindrv, 2'd0};
                end
                else begin
                    // Pixel state not meaningfully changed
                    proc_output = `NO_DRIVE;
                    if (pixel_framecnt == 0) begin
                        // Greyscale mode can be entered only if global counter is at last frame
                        if (al_framecnt == 0) begin
                            // Check pixel target color again, if it equals the current color,
                            // don't bother, enter DONE
                            // This could be due to a greyscale only change in the HOLD stage
                            if (pixel_prev != proc_vin)
                                proc_bo = {proc_bi[15:12], STAGE_GREY, 2'b0, pixel_prev, proc_vin};
                            else
                                proc_bo = {proc_bi[15:12], STAGE_DONE, 6'd0, pixel_prev};
                        end
                        else begin
                            proc_bo = proc_bi; // Wait
                        end
                    end
                    else begin
                        // Count down
                        proc_bo = {proc_bi[15:10], pixel_framecnt_dec, proc_bi[3:0]};
                    end
                end
            end
            else if (pixel_stage == STAGE_GREY) begin
                // In grey stage
                proc_output = proc_lut_rd;
                if (al_framecnt == 0) begin
                    // Finished refresh cycle, enter done stage
                    proc_bo = {proc_bi[15:12], STAGE_DONE, 6'd0, pixel_prev};
                end
                else begin
                    proc_bo = proc_bi;
                end
            end
            else if (pixel_stage == STAGE_DONE) begin
                // Not currently updating, display in BINARY/ GREYSCALE mode
                if (proc_vin[3:0] != pixel_prev[3:0]) begin
                    // In GREYSCALE mode, any change triggers an update, frame count depends on the delta
                    proc_output = drive_towards_input;
                    proc_bo = proc_vin[3] ? (
                        // To white, see if it's current dark grey or light grey
                        {proc_bi[15:12], STAGE_MONO, fastg_g2w_frames, csr_mindrv, 2'd1}
                    ) : {proc_bi[15:12], STAGE_MONO, fastg_g2b_frames, csr_mindrv, 2'd0};
                end
                else begin
                    // Nothing has changed, do nothing
                    proc_output = `NO_DRIVE;
                    proc_bo = proc_bi;
                end
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
                if ((proc_vin[3] != pixel_prev[1]) && (pixel_mindrv == 2'd0)) begin
                    // Pixel state changed
                    proc_bo = proc_vin[3] ? (
                        {proc_bi[15:12], STAGE_MONO, pixel_framecnt_2w, csr_mindrv, proc_vin[3:2]}
                    ) : {proc_bi[15:12], STAGE_MONO, pixel_framecnt_2b, csr_mindrv, proc_vin[3:2]};
                end
                else begin
                    proc_output = pixel_prev[1] ? `DRIVE_WHITE : `DRIVE_BLACK;
                    // Pixel didn't change, continue
                    if (pixel_framecnt == 0) begin
                        proc_bo = {proc_bi[15:12], STAGE_HOLD, FASTG_HOLDOFF_FRAMES, proc_bi[3:0]};
                    end
                    else begin
                        proc_bo = {proc_bi[15:10], pixel_framecnt_dec, pixel_mindrv_dec, proc_bi[1:0]};
                    end
                end
            end
            else if (pixel_stage == STAGE_HOLD) begin
                // Not currently updating, holding
                if (proc_vin[3] != pixel_prev[1]) begin
                    // Pixel state changed
                    proc_output = drive_towards_input;
                    proc_bo = proc_vin[3] ? (
                        {proc_bi[15:12], STAGE_MONO, FASTM_B2W_FRAMES, csr_mindrv, proc_vin[3:2]}
                    ) : {proc_bi[15:12], STAGE_MONO, FASTM_W2B_FRAMES, csr_mindrv, proc_vin[3:2]};
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
                    proc_bo = ((proc_vin[3] != pixel_prev[1]) || (pixel_prev[1] != pixel_prev[0])) ? 
                        (proc_vin[3] ? (
                                {proc_bi[15:12], STAGE_MONO, FASTM_B2W_FRAMES, csr_mindrv, proc_vin[3:2]}
                            ) : {proc_bi[15:12], STAGE_MONO, FASTM_W2B_FRAMES, csr_mindrv, proc_vin[3:2]}) :
						((proc_vin[3:2] == 2'b10) ? (
                                {proc_bi[15:12], STAGE_GREY, FASTG_W2G_FRAMES + FASTG_SETTLE_FRAMES, 2'b00, proc_vin[3:2]}
                            ) : (proc_vin[3:2] == 2'b01) ? (
                                {proc_bi[15:12], STAGE_GREY, FASTG_B2G_FRAMES + FASTG_SETTLE_FRAMES, 2'b00, proc_vin[3:2]}
                            ) : (
                                {proc_bi[15:12], STAGE_DONE, 6'd0, 2'b00, proc_vin[3:2]}
                            ));
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
            `SETMODE_MANUAL_LUT_BLUE_NOISE:
                proc_bo = {MODE_MANUAL_LUT_BLUE_NOISE, 4'd0, 6'd0, 4'd15};
            `SETMODE_FAST_MONO_NO_DITHER:
                proc_bo = `INIT_FAST_MONO_ND;
            `SETMODE_FAST_MONO_BAYER:
                proc_bo = `INIT_FAST_MONO_BD;
            `SETMODE_FAST_MONO_BLUE_NOISE:
                proc_bo = `INIT_FAST_MONO_BN;
            `SETMODE_FAST_GREY:
                proc_bo = `INIT_FAST_GREY;
            `SETMODE_AUTO_LUT_NO_DITHER:
                proc_bo = `INIT_AUTO_LUT_ND;
            `SETMODE_AUTO_LUT_BLUE_NOISE:
                proc_bo = `INIT_AUTO_LUT_OD;
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
            if (op_framecnt[4:2] == 3'b111)
                proc_output = `NO_DRIVE;
            else if (op_framecnt[5] == 1'b1)
                proc_output = `DRIVE_BLACK;
            else
                proc_output = `DRIVE_WHITE;
            // Set initial mode
            proc_bo = `DEFAULT_MODE;
        end
    end

endmodule
`default_nettype wire
