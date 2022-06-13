`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting
// 
// Create Date:    20:44:53 12/04/2021 
// Design Name:    caster
// Module Name:    epd_output 
// Project Name: 
// Target Devices: spartan 6
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
module caster(
    input  wire         clk, // 4X/8X output clock rate
    input  wire         rst,
    input  wire         sys_ready, // Power OK, DDR calibration done, etc.
    // New image Input, 4 pix per clock, Y4 input
    // This input is buffered after a ASYNC FIFO
    input  wire         vin_vsync,
    input  wire [15:0]  vin_pixel,
    input  wire         vin_valid,
    output wire         vin_ready,
    // Framebuffer input
    output wire         b_trigger, // Trigger VRAM operation
    // 16 bit per pixel for state
    input  wire [63:0]  bi_pixel,
    input  wire         bi_valid,
    output wire         bi_ready,
    // Framebuffer output
    output reg  [63:0]  bo_pixel,
    output wire         bo_valid,
    // output interface couldn't handle FIFO overrun
    // EPD signals
    output wire         epd_gdoe,
    output wire         epd_gdclk,
    output wire         epd_gdsp,
    output wire         epd_sdclk,
    output wire         epd_sdle,
    output wire         epd_sdoe,
    output wire [7:0]   epd_sd,
    output wire         epd_sdce0
    );

    // Screen timing
    // Timing starts when VS is detected
    parameter V_FP = 3; // Lines before sync with SDOE / GDOE low, GDSP high (inactive)
    parameter V_SYNC = 1; // Lines at sync with SDOE / GDOE high, GDSP low (active)
    parameter V_BP = 2; // Lines before data becomes active
    parameter V_ACT = 120;
    localparam V_TOTAL = V_FP + V_SYNC + V_BP + V_ACT;
    parameter H_FP = 1; // SDLE low (inactive), SDCE0 high (inactive), clock active
    parameter H_SYNC = 1; // SDLE high (active), SDCE0 high (inactive), GDCLK lags by 1 clock, clock active
    parameter H_BP = 2; // SDLE low (inactive), SDCE0 high (inactive), no clock
    parameter H_ACT = 40; // Active pixels / 4, SDCE0 low (active)
    localparam H_TOTAL = H_FP + H_SYNC + H_BP + H_ACT;
    
    parameter SIMULATION = "FALSE";

    // Output logic
    localparam SCAN_IDLE = 2'd0;
    localparam SCAN_WAITING = 2'd1;
    localparam SCAN_RUNNING = 2'd2;

    localparam OP_INIT = 2'd0; // Initial power up
    localparam OP_NORMAL = 2'd1; // Normal operation
    localparam OP_CLEAR_NORMAL = 2'd2; // In place screen clear

    localparam OP_INIT_LENGTH = (SIMULATION == "FALSE") ? 340 : 2; // 240 frames, (black, white)x4

    // Internal design specific
    localparam VS_DELAY = 8; // wait 8 clocks after VS is vaild
    localparam PIPELINE_DELAY = 2;

    reg [10:0] scan_v_cnt;
    reg [10:0] scan_h_cnt;

    reg [1:0] scan_state;
    reg [1:0] op_state;

    reg [10:0] op_framecount; // Framecount for operation transition

    always @(posedge clk)
        if (rst) begin
            scan_state <= SCAN_IDLE;
            scan_h_cnt <= 0;
            scan_v_cnt <= 0;
            op_state <= OP_INIT;
            op_framecount <= 0;
        end
        else begin
            case (scan_state)
            SCAN_IDLE: begin
                if ((sys_ready) && (vin_vsync)) begin
                    scan_state <= SCAN_WAITING;
                end
                scan_h_cnt <= 0;
                scan_v_cnt <= 0;
            end
            SCAN_WAITING: begin
                if (scan_h_cnt == VS_DELAY) begin
                    scan_state <= SCAN_RUNNING;
                    scan_h_cnt <= 0;
                end
                else begin
                    scan_h_cnt <= scan_h_cnt + 1;
                end
            end
            SCAN_RUNNING: begin
                if (scan_h_cnt == H_TOTAL - 1) begin
                    if (scan_v_cnt == V_TOTAL - 1) begin
                        scan_state <= SCAN_IDLE;
                        // OP state machine here
                        case (op_state)
                        OP_INIT: begin
                            if (op_framecount == OP_INIT_LENGTH - 1) begin
                                op_state <= OP_NORMAL;
                                op_framecount <= 0;
                            end
                            else begin
                                op_framecount <= op_framecount + 1;
                            end
                        end
                        endcase
                    end
                    else begin
                        scan_h_cnt <= 0;
                        scan_v_cnt <= scan_v_cnt + 1;
                    end
                end
                else begin
                    scan_h_cnt <= scan_h_cnt + 1;
                end
            end
            endcase
        end

    wire scan_in_vfp = (scan_state != SCAN_IDLE) ? (
        (scan_v_cnt < V_FP)) : 1'b0;
    wire scan_in_vsync = (scan_state != SCAN_IDLE) ? (
        (scan_v_cnt >= V_FP) && 
        (scan_v_cnt < (V_FP + V_SYNC))) : 1'b0;
    wire scan_in_vbp = (scan_state != SCAN_IDLE) ? (
        (scan_v_cnt >= (V_FP + V_SYNC)) &&
        (scan_v_cnt < (V_FP + V_SYNC + V_BP))) : 1'b0;
    wire scan_in_vact = (scan_state != SCAN_IDLE) ? (
        (scan_v_cnt >= (V_FP + V_SYNC + V_BP))) : 1'b0;

    wire scan_in_hfp = (scan_state != SCAN_IDLE) ? (
        (scan_h_cnt < H_FP)) : 1'b0;
    wire scan_in_hsync = (scan_state != SCAN_IDLE) ? (
        (scan_h_cnt >= H_FP) &&
        (scan_h_cnt < (H_FP + H_SYNC))) : 1'b0;
    wire scan_in_hbp = (scan_state != SCAN_IDLE) ? (
        (scan_h_cnt >= (H_FP + H_SYNC)) &&
        (scan_h_cnt < (H_FP + H_SYNC + H_BP))) : 1'b0;
    wire scan_in_hact = (scan_state != SCAN_IDLE) ? (
        (scan_h_cnt >= (H_FP + H_SYNC + H_BP))) : 1'b0;

    wire scan_in_act = scan_in_vact && scan_in_hact;

    // Pixel state: 16bits
    // Bit 15-14: Mode
    localparam MODE_NORMAL_LUT = 2'b00;
    localparam MODE_FAST_MONO = 2'b01;
    localparam MODE_FAST_GREY = 2'b10;
    localparam MODE_RESERVED = 2'b11;

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
    // Bit 13: LUT ID
    //   Only up to 2 are allowed due to limited LUT RAM size
    //   The naming is just a suggestion. Host might reload waveform at runtime
    localparam LUTID_DU = 1'b0;
    localparam LUTID_GC16 = 1'b1;

    // Bit 12-10: Reserved
    // Bit 9-4: Frame counter (up to 64 frames)
    // Bit 3-0: Previous frame pixel value

    // In fast mono mode:
    // Bit 13-10: Reserved
    // Bit 9-4: Frame counter
    // Bit 3-1: Must be 0
    // Bit 0: Previous frame pixel value (0 black 1 white)

    // In fast grey 4-level mode:
    // Bit 13-12: Reserved
    // Bit 11-10: Stage
    // Bit 9-4: Frame counter
    // Bit 3-2: Must be 0
    // Bit 1-0: Previous frame pixel value
    // It matches, continue the current operation:
    localparam STAGE_DONE = 2'd0; // Screen already settled. No operation
    localparam STAGE_MONO = 2'd1; // Driving to mono (same as fast mono mode)
    localparam STAGE_HOLD = 2'd2; // Hold off (wait before start driving greyscale)
    localparam STAGE_GREY = 2'd3; // Driving to greyscale (non-cancellable)

    wire [7:0] pixel_comb;
    wire [63:0] bo_pixel_comb;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: pixel_processing
            wire [3:0] proc_vin = vin_pixel[i*4+3 : i*4];
            wire [15:0] proc_bi = bi_pixel[i*16+15 : i*16];
            wire [15:0] proc_bo;
            wire [1:0] proc_output;
            // Pixel processing
            wire [1:0] pixel_mode = proc_bi[15:14];
            wire pixel_lutid = proc_bi[13];
            wire [1:0] pixel_stage = proc_bi[11:10];
            wire [5:0] pixel_framecnt = proc_bi[9:4];
            wire [3:0] pixel_prev = proc_bi[3:0];
            wire [5:0] pixel_framecnt_dec = pixel_framecnt - 1;
            // Specific to fast mono mode
            wire [5:0] pixel_framecnt_2w = FASTM_B2W_FRAMES - pixel_framecnt + 2;
            wire [5:0] pixel_framecnt_2b = FASTM_W2B_FRAMES - pixel_framecnt + 2;
            wire [5:0] pixel_framecnt_back = FASTG_B2G_FRAMES - pixel_framecnt + 1;
            wire [5:0] pixel_framecnt_oppo = FASTM_B2W_FRAMES - FASTG_B2G_FRAMES + pixel_framecnt;

            assign proc_output =
                (op_state == OP_INIT) ? (
                    // Init state
                    (op_framecount < 11'd48) ? 2'b01 :
                    (op_framecount < 11'd50) ? 2'b00 :
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
                    (pixel_mode == MODE_NORMAL_LUT) ? (
                        // Normal LUT mode
                        2'b00 // Not supported yet
                    ) : (pixel_mode == MODE_FAST_MONO) ? (
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
                    ) : (pixel_mode == MODE_FAST_GREY) ? (
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
                    {MODE_FAST_MONO, 4'b0, 6'd0, 3'b0, 1'b1}
                    //{MODE_FAST_GREY, 4'b0, 6'd0, 2'b0, 2'b11}
                ) : (op_state == OP_NORMAL) ? (
                    // Normal state
                    (pixel_mode == MODE_NORMAL_LUT) ? (
                        // Normal LUT mode
                        16'h00 // Not supported yet
                    ) : (pixel_mode == MODE_FAST_MONO) ? (
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
                    ) : (pixel_mode == MODE_FAST_GREY) ? (
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
            // Output
            assign pixel_comb[i*2+1 : i*2] = proc_output;
            assign bo_pixel_comb[i*16+15 : i*16] = proc_bo;
        end
    endgenerate

    reg [7:0] current_pixel;
    reg output_mask;
    always @(posedge clk) begin
        output_mask <= proc_in_act;
        current_pixel <= (output_mask) ? pixel_comb : 8'h00;
        bo_pixel <= bo_pixel_comb;
    end

    // image gen
    wire proc_in_hact = (scan_state != SCAN_IDLE) ? (
        (scan_h_cnt >= (H_FP + H_SYNC + H_BP - PIPELINE_DELAY)) &&
        (scan_h_cnt < (H_TOTAL - PIPELINE_DELAY))) : 1'b0;
    wire proc_in_act = scan_in_vact && proc_in_hact;
    // Essentially a scan_in_act but few cycles eariler.
    assign vin_ready = proc_in_act;

    // mode
    assign epd_gdoe = (scan_in_vsync || scan_in_vbp || scan_in_vact) ? 1'b1 : 1'b0;
    // ckv
    wire epd_gdclk_pre = (scan_in_hsync || scan_in_hbp || scan_in_hact) ? 1'b1 : 1'b0;
    reg epd_gdclk_delay;
    always @(posedge clk)
        epd_gdclk_delay <= epd_gdclk_pre;
    assign epd_gdclk = epd_gdclk_delay;

    // spv
    assign epd_gdsp = (scan_in_vsync) ? 1'b0 : 1'b1;
    assign epd_sdoe = epd_gdoe;

    assign epd_sd = current_pixel;
    // stl
    assign epd_sdce0 = (scan_in_act) ? 1'b0 : 1'b1;
    assign epd_sdle = (scan_in_hsync) ? 1'b1 : 1'b0;
    assign epd_sdclk = (scan_in_hfp || scan_in_hsync || scan_in_hact) ? ~clk : 1'b0;

    assign bi_ready = proc_in_act;
    assign bo_valid = scan_in_act;

    assign b_trigger = (scan_state == SCAN_WAITING);

endmodule
