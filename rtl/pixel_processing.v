`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting
// 
// Create Date:    21:22:15 06/13/2022 
// Design Name:    caster
// Module Name:    pixel_processing 
// Project Name: 
// Target Devices: generic
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module pixel_processing(
    input  wire [5:0]  csr_lutframe,// Frame count for currently loaded LUT
    input  wire [3:0]  proc_p_or,   // Original pixel
    input  wire [3:0]  proc_p_od,   // Ordered dithered pixel to 1-bit
    input  wire [3:0]  proc_p_e1,   // Error diffusion dithered pixel to 1-bit
    input  wire [3:0]  proc_p_e4,   // Error diffusion dithered pixel to 4-bit
    input  wire [15:0] proc_bi,     // Pixel state input from VRAM
    output wire [15:0] proc_bo,     // Pixel state output to VRAM
    input  wire [1:0]  proc_lut_rd, // Read out from LUT
    output wire [1:0]  proc_output, // Output to screen
    input  wire [1:0]  op_state,    // Current overall operating state
    input  wire [10:0] op_framecount// Current overall frame counter for state
);
    localparam OP_INIT = 2'd0; // Initial power up
    localparam OP_NORMAL = 2'd1; // Normal operation
    localparam OP_CLEAR_NORMAL = 2'd2; // In place screen clear

    // Pixel state: 16bits
    // Bit 15-12: Mode
    // Bit 13-12 is shared
    localparam MODE_NORMAL_LUT_NO_DITHER = 2'd0; // 00xx
    localparam MODE_NORMAL_LUT_ERROR_DIFFUSION = 2'd1; // 01xx
    localparam MODE_FAST_MONO_NO_DITHER = 4'd8; // 1000
    localparam MODE_FAST_MONO_ORDERED = 4'd9; // 1001
    localparam MODE_FAST_MONO_ERROR_DIFFUSION = 4'd10; // 1010
    localparam MODE_FAST_GREY = 4'd11; // 1011
    localparam MODE_RESERVED1 = 4'd12; // 1100
    localparam MODE_RESERVED2 = 4'd13; // 1101
    localparam MODE_RESERVED3 = 4'd14; // 1100
    localparam MODE_RESERVED4 = 4'd15; // 1101

    //localparam FASTM_B2W_FRAMES = 6'd9;
    //localparam FASTM_W2B_FRAMES = 6'd9;
    localparam FASTM_B2W_FRAMES = 6'd10;
    localparam FASTM_W2B_FRAMES = 6'd10;

    //
    localparam FASTG_HOLDOFF_FRAMES = 6'd10;
    localparam FASTG_B2G_FRAMES = 6'd1;
    localparam FASTG_W2G_FRAMES = 6'd1;
    localparam FASTG_LG2B_FRAMES = 6'd8;
    localparam FASTG_DG2B_FRAMES = 6'd5;
    localparam FASTG_LG2W_FRAMES = 6'd5;
    localparam FASTG_DG2W_FRAMES = 6'd8;

    // In normal LUT mode:
    // Bit 13-10: Source pixel value
    // Bit 9-4: Frame counter
    // Bit 3-0: Target pixel value
    // When frame counter is not 0, waveform lookup is in progress.
    // When lookup is in progress, both target and source pixel value are hold
    // still, and the frame counter is decremented.
    // When lookup is not in progress, the input pixel and old target pixel
    // value is compared. If doesn't match, the input pixel is copied to target
    // pixel value, the old target pixel value is copied to source pixel
    // value, and the frame counter is set to LUT frame length.

    // In fast mono mode:
    // Bit 11-10: Reserved
    // Bit 9-4: Frame counter
    // Bit 3-1: Must be 0
    // Bit 0: Previous frame pixel value (0 black 1 white)

    // In fast grey 4-level mode:
    // Bit 11-10: Stage
    // Bit 9-4: Frame counter
    // Bit 3-2: Must be 0
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
    wire [3:0] pixel_prev = proc_bi[3:0];
    wire [5:0] pixel_framecnt_dec = pixel_framecnt - 1;
    // Specific to fast mono mode
    wire [5:0] pixel_framecnt_2w = FASTM_B2W_FRAMES - pixel_framecnt + 2;
    wire [5:0] pixel_framecnt_2b = FASTM_W2B_FRAMES - pixel_framecnt + 2;
    wire [5:0] pixel_framecnt_back = FASTG_B2G_FRAMES - pixel_framecnt + 1;
    wire [5:0] pixel_framecnt_oppo = FASTM_B2W_FRAMES - FASTG_B2G_FRAMES + pixel_framecnt;

    // Decode base mode and dither mode
    localparam BASEMODE_NORMAL_LUT = 2'b00;
    localparam BASEMODE_FAST_MONO = 2'b01;
    localparam BASEMODE_FAST_GREY = 2'b10;
    localparam BASEMODE_RESERVED = 2'b11;

    localparam DITHER_NONE = 2'b00;
    localparam DITHER_ORDERED = 2'b01;
    localparam DITHER_ED_1BIT = 2'b10;
    localparam DITHER_ED_4BIT = 2'b11;

    reg [1:0] pixel_basemode;
    reg [1:0] pixel_dither;
    always @(*) begin
        case (pixel_mode_hi)
        MODE_NORMAL_LUT_NO_DITHER: begin
            pixel_basemode = BASEMODE_NORMAL_LUT;
            pixel_dither = DITHER_NONE;
        end
        MODE_NORMAL_LUT_ERROR_DIFFUSION: begin
            pixel_basemode = BASEMODE_NORMAL_LUT;
            pixel_dither = DITHER_ED_4BIT;
        end
        default: begin
            case (pixel_mode) 
            MODE_FAST_MONO_NO_DITHER: begin
                pixel_basemode = BASEMODE_FAST_MONO;
                pixel_dither = DITHER_NONE;
            end
            MODE_FAST_MONO_ORDERED: begin
                pixel_basemode = BASEMODE_FAST_MONO;
                pixel_dither = DITHER_ORDERED;
            end
            MODE_FAST_MONO_ERROR_DIFFUSION: begin
                pixel_basemode = BASEMODE_FAST_MONO;
                pixel_dither = DITHER_ED_1BIT;
            end
            MODE_FAST_GREY: begin
                pixel_basemode = BASEMODE_FAST_GREY;
                pixel_dither = DITHER_NONE;
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

    wire [3:0] proc_vin = proc_p_or;
        // (pixel_dither == DITHER_NONE) ? (proc_p_or) :
        // (pixel_dither == DITHER_ORDERED) ? (proc_p_od) :
        // (pixel_dither == DITHER_ED_1BIT) ? (proc_p_e1) : (proc_p_e4);

    assign proc_output =
        (op_state == OP_INIT) ? (
            // Init state
            (op_framecount < 11'd10) ? 2'b00 :
            (op_framecount < 11'd58) ? 2'b01 :
            (op_framecount < 11'd60) ? 2'b00 :
            (op_framecount < 11'd108) ? 2'b10 :
            (op_framecount < 11'd110) ? 2'b00 :
            (op_framecount < 11'd178) ? 2'b01 :
            (op_framecount < 11'd180) ? 2'b00 :
            (op_framecount < 11'd258) ? 2'b10 :
            (op_framecount < 11'd260) ? 2'b00 :
            (op_framecount < 11'd278) ? 2'b01 :
            (op_framecount < 11'd280) ? 2'b00 :
            (op_framecount < 11'd298) ? 2'b10 :
            (op_framecount < 11'd300) ? 2'b00 :
            (op_framecount < 11'd318) ? 2'b01 :
            (op_framecount < 11'd320) ? 2'b00 :
            (op_framecount < 11'd338) ? 2'b10 :
                                        2'b00
        ) : ((op_state == OP_NORMAL) ? (
            // Normal state
            (pixel_basemode == BASEMODE_NORMAL_LUT) ? (
                // Normal LUT mode
                (pixel_framecnt != 0) ? (proc_lut_rd) : 2'b00
            ) : (pixel_basemode == BASEMODE_FAST_MONO) ? (
                // Fast mono mode
                (pixel_framecnt != 0) ? (
                    // Currently updating
                    // For now, just continue
                    //pixel_prev[0] ? 2'b10 : 2'b01
                    // Or, respond to input!
                    proc_vin[3] ? 2'b10 : 2'b01
                ) : (
                    // Currently not updating
                    (proc_vin[3] == pixel_prev[0]) ? (
                        // Pixel state did not change, no op
                        2'b00
                    ) : (
                        // Pixel state changed, update
                        proc_vin[3] ? 2'b10 : 2'b01
                    )
                )
            ) : (pixel_basemode == BASEMODE_FAST_GREY) ? (
                // Fast grey mode
                ((pixel_stage == STAGE_DONE) || (pixel_stage == STAGE_HOLD)) ? (
                    // Currently not updating
                    (proc_vin[3:2] == pixel_prev[1:0]) ? (
                        // Pixel state did not change, no op
                        2'b00
                    ) : (
                        // Pixel state changed, update
                        proc_vin[3] ? 2'b10 : 2'b01
                    )
                ) : (pixel_stage == STAGE_MONO) ? (
                    // Fast mono stage, always drive towards input
                    proc_vin[3] ? 2'b10 : 2'b01
                ) : (
                    // Grey mode, non cancellable, drive towards old value
                    pixel_prev[1] ? 2'b01 : 2'b10
                )
            ) : 2'b00 // Unknown mode
        ) : (
            2'b00 // Unknwon state
        ));
    assign proc_bo =
        (op_state == OP_INIT) ? (
            //{MODE_FAST_MONO_NO_DITHER, 2'b0, 6'd0, 3'b0, 1'b1}
            //{MODE_FAST_GREY, STAGE_DONE, 6'd0, 2'b0, 2'b11}
            {MODE_NORMAL_LUT_NO_DITHER, 4'd0, 6'd0, 4'd15}
        ) : (op_state == OP_NORMAL) ? (
            // Normal state
            (pixel_basemode == BASEMODE_NORMAL_LUT) ? (
                // Normal LUT mode
                (pixel_framecnt != 0) ? (
                    // Currently updating, continue
                    {proc_bi[15:10], pixel_framecnt_dec, proc_bi[3:0]}
                ) : (
                    (proc_vin == pixel_prev) ? (
                        // Pixel not changed, keep
                        proc_bi
                    ) : (
                        // Pixel changed, initiate update
                        {proc_bi[15:14], pixel_prev, csr_lutframe, proc_vin}
                    )
                )
            ) : (pixel_basemode == BASEMODE_FAST_MONO) ? (
                // Fast mono mode
                (pixel_framecnt != 0) ? (
                    // Currently updating
                    // For now, just continue
                    //{proc_bi[15:10], pixel_framecnt_dec, proc_bi[3:0]}
                    // Respond to input!
                    (proc_vin[3] == pixel_prev[0]) ? (
                        // Pixel state did not change, continue
                        {proc_bi[15:10], pixel_framecnt_dec, proc_bi[3:0]}
                    ) : (
                        // Pixel state changed, update
                        proc_vin[3] ? (
                            {proc_bi[15:10], pixel_framecnt_2w, 4'd1}
                        ) : {proc_bi[15:10], pixel_framecnt_2b, 4'd0}
                    )
                ) : (
                    // Currently not updating
                    (proc_vin[3] == pixel_prev[0]) ? (
                        // Pixel state did not change, no op
                        proc_bi
                    ) : (
                        // Pixel state changed, update
                        proc_vin[3] ? (
                            {proc_bi[15:10], FASTM_B2W_FRAMES, 4'd1}
                        ) : {proc_bi[15:10], FASTM_W2B_FRAMES, 4'd0}
                    )
                )
            ) : (pixel_basemode == BASEMODE_FAST_GREY) ? (
                // Fast grey mode
                (proc_vin[3:2] == pixel_prev[1:0]) ? (
                    // Pixel didn't change, continue
                    (pixel_stage == STAGE_DONE) ? (
                        proc_bi // Stay
                    ) : (pixel_stage == STAGE_MONO) ? (
                        (pixel_framecnt == 0) ? (
                            {proc_bi[15:12], STAGE_HOLD, FASTG_HOLDOFF_FRAMES, proc_bi[3:0]}
                        ) : (
                            {proc_bi[15:10], pixel_framecnt_dec, proc_bi[3:0]}
                        )
                    ) : (pixel_stage == STAGE_HOLD) ? (
                        (pixel_framecnt == 0) ? (
                            (pixel_prev[1:0] == 2'b10) ? (
                                {proc_bi[15:12], STAGE_GREY, FASTG_W2G_FRAMES, proc_bi[3:0]}
                            ) : (pixel_prev[1:0] == 2'b01) ? (
                                {proc_bi[15:12], STAGE_GREY, FASTG_B2G_FRAMES, proc_bi[3:0]}
                            ) : (
                                {proc_bi[15:12], STAGE_DONE, 6'd0, 2'b00, proc_vin[3:2]}
                            )
                        ) : (
                            {proc_bi[15:10], pixel_framecnt_dec, proc_bi[3:0]}
                        )
                    ) : (
                        // Grey
                        (pixel_framecnt == 0) ? (
                            {proc_bi[15:12], STAGE_DONE, 6'd0, proc_bi[3:0]}
                        ) : (
                            {proc_bi[15:10], pixel_framecnt_dec, proc_bi[3:0]}
                        )
                    )
                ) : (
                    ((pixel_stage == STAGE_DONE) || (pixel_stage == STAGE_HOLD)) ? (
                        proc_vin[3] ? (
                            (pixel_prev[1:0] == 2'b10) ? (
                                {proc_bi[15:12], STAGE_MONO, FASTG_LG2W_FRAMES, 2'b00, proc_vin[3:2]}
                            ) : (pixel_prev[1:0] == 2'b01) ? (
                                {proc_bi[15:12], STAGE_MONO, FASTG_DG2W_FRAMES, 2'b00, proc_vin[3:2]}
                            ) : (
                                {proc_bi[15:12], STAGE_MONO, FASTM_B2W_FRAMES, 2'b00, proc_vin[3:2]}
                            )
                        ) : (
                            (pixel_prev[1:0] == 2'b10) ? (
                                {proc_bi[15:12], STAGE_MONO, FASTG_LG2B_FRAMES, 2'b00, proc_vin[3:2]}
                            ) : (pixel_prev[1:0] == 2'b01) ? (
                                {proc_bi[15:12], STAGE_MONO, FASTG_DG2B_FRAMES, 2'b00, proc_vin[3:2]}
                            ) : (
                                {proc_bi[15:12], STAGE_MONO, FASTM_W2B_FRAMES, 2'b00, proc_vin[3:2]}
                            )
                        )
                    ) : (pixel_stage == STAGE_MONO) ? (
                        // Pixel state changed, update
                        proc_vin[3] ? (
                            {proc_bi[15:12], STAGE_MONO, pixel_framecnt_2w, 2'b00, proc_vin[3:2]}
                        ) : (
                            {proc_bi[15:12], STAGE_MONO, pixel_framecnt_2b, 2'b00, proc_vin[3:2]}
                        )
                    ) : (
                        // Stage grey
                        /*(proc_vin[3] == pixel_prev[1]) ? (
                            // Back to previous color
                            {proc_bi[15:12], STAGE_MONO, pixel_framecnt_back, 2'b00, proc_vin[3:2]}
                        ) : (
                            // To another side
                            {proc_bi[15:12], STAGE_MONO, pixel_framecnt_oppo, 2'b00, proc_vin[3:2]}
                        )*/
                        // Non cancellable
                        (pixel_framecnt == 0) ? (
                            {proc_bi[15:12], STAGE_DONE, 6'd0, proc_bi[3:0]}
                        ) : (
                            {proc_bi[15:10], pixel_framecnt_dec, proc_bi[3:0]}
                        )
                    )
                )
            ) : 16'h00 // Unknown mode
        ) : (
            16'h00 // Unknwon state
        );

endmodule
`default_nettype wire
