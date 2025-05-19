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
// caster.v
// EPD controller top-level
// Note: for the top level interface, data lags behind the handshaking by 1
// cycle, to be compatible with Xilinx FIFOs.
`timescale 1ns / 1ps
`default_nettype none
`include "defines.vh"
module caster(
    input  wire         clk, // 4X/8X output clock rate
    input  wire         rst,
    // New image Input, 4 pix per clock, Y8 input
    // This input is buffered after a ASYNC FIFO
    input  wire         vin_vsync,
    /* verilator lint_off UNUSEDSIGNAL */
    // Currently only 6 MSBs per pixel is used
    input  wire [31:0]  vin_pixel,
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire         vin_valid,
    output wire         vin_ready,
    // Framebuffer input
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
    output wire [15:0]  epd_sd,
    output wire         epd_sdce0,
    // CSR SPI interface
    input  wire         spi_cs,
    input  wire         spi_sck,
    input  wire         spi_mosi,
    output wire         spi_miso,
    // Control / Status
    output wire         b_trigger, // Trigger VRAM operation
    input  wire         sys_ready, // Power OK, DDR calibration done, etc.
    input  wire         mig_error,
    input  wire         mif_error,
    output wire [23:0]  frame_bytes,
    output wire         global_en,
    // Debug output
    output wire [15:0]  dbg_wvfm_tgt,
    output wire [1:0]   dbg_scan_state,
    output wire [10:0]  dbg_scan_v_cnt,
    output wire [10:0]  dbg_scan_h_cnt,
    output wire         dbg_spi_req_wen,
    output wire [7:0]   dbg_spi_req_addr,
    output wire [7:0]   dbg_spi_req_wdata
    );

    /* verilator lint_off UNUSEDPARAM */
    // Only used if bayer dithering is selected
    parameter COLORMODE = "MONO";
    /* verilator lint_on UNUSEDPARAM */

    // Screen timing
    parameter SIMULATION = "TRUE";

    // Output logic
    localparam SCAN_IDLE = 2'd0;
    localparam SCAN_WAITING = 2'd1;
    localparam SCAN_RUNNING = 2'd2;

    /* verilator lint_off WIDTH */
    localparam OP_INIT_LENGTH = (SIMULATION == "FALSE") ? 63 : 2;
    /* verilator lint_on WIDTH */

    // Internal design specific
    localparam VS_DELAY = 8; // wait 8 clocks after VS is vaild
    localparam PIPELINE_DELAY = 4;

    // Control status registers
    wire [5:0] csr_lut_frame;
    wire [11:0] csr_lut_addr;
    wire [7:0] csr_lut_wr;
    wire csr_lut_we;
    wire csr_osd_en;
    wire [11:0] csr_osd_left;
    wire [11:0] csr_osd_right;
    wire [11:0] csr_osd_top;
    wire [11:0] csr_osd_bottom;
    wire [11:0] csr_osd_addr;
    wire [7:0] csr_osd_wr;
    wire csr_osd_we;
    wire [1:0] csr_mindrv;
    wire [11:0] csr_op_left;
    wire [11:0] csr_op_right;
    wire [11:0] csr_op_top;
    wire [11:0] csr_op_bottom;
    wire [7:0] csr_op_param;
    wire [7:0] csr_op_length;
    wire [7:0] csr_op_cmd;
    wire csr_op_en;
    wire [7:0] vfp;
    wire [7:0] vsync;
    wire [7:0] vbp;
    wire [11:0] vact;
    wire [7:0] hfp;
    wire [7:0] hsync;
    wire [7:0] hbp;
    wire [11:0] hact;
    wire mirror_en;
    csr csr (
        .clk(clk),
        .rst(rst),
        .spi_cs(spi_cs),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .csr_lut_frame(csr_lut_frame),
        .csr_lut_addr(csr_lut_addr),
        .csr_lut_wr(csr_lut_wr),
        .csr_lut_we(csr_lut_we),
        .csr_osd_en(csr_osd_en),
        .csr_osd_left(csr_osd_left),
        .csr_osd_right(csr_osd_right),
        .csr_osd_top(csr_osd_top),
        .csr_osd_bottom(csr_osd_bottom),
        .csr_osd_addr(csr_osd_addr),
        .csr_osd_wr(csr_osd_wr),
        .csr_osd_we(csr_osd_we),
        .csr_op_left(csr_op_left),
        .csr_op_right(csr_op_right),
        .csr_op_top(csr_op_top),
        .csr_op_bottom(csr_op_bottom),
        .csr_op_param(csr_op_param),
        .csr_op_length(csr_op_length),
        .csr_op_cmd(csr_op_cmd),
        .csr_op_en(csr_op_en),
        .csr_en(global_en),
        .csr_cfg_vfp(vfp),
        .csr_cfg_vsync(vsync),
        .csr_cfg_vbp(vbp),
        .csr_cfg_vact(vact),
        .csr_cfg_hfp(hfp),
        .csr_cfg_hsync(hsync),
        .csr_cfg_hbp(hbp),
        .csr_cfg_hact(hact),
        .csr_cfg_fbytes(frame_bytes),
        .csr_cfg_mindrv(csr_mindrv),
        .csr_mirror_en(mirror_en),
        // Status input
        .sys_ready(sys_ready),
        .mig_error(mig_error),
        .mif_error(mif_error),
        .op_busy(op_valid),
        .op_queue(op_pending),
        .dbg_spi_req_wen(dbg_spi_req_wen),
        .dbg_spi_req_addr(dbg_spi_req_addr),
        .dbg_spi_req_wdata(dbg_spi_req_wdata)
    );

    /* verilator lint_off width */
    wire [10:0] vtotal = vfp + vsync + vbp + vact;
    wire [10:0] htotal = hfp + hsync + hbp + hact;
    /* verilator lint_on width */

    // OSD overlay RAM
    wire [11:0] osd_rd_addr;
    wire [7:0] osd_rd;

    // Single 4KB block RAM, use port A for read and port B for write
    // Resolution is fixed 256x128 @ 1bpp
    mu_ram_2rw #(
        .AW(12),
        .DW(8)
    ) bramdp0 (
        .clka(clk),
        .wea(1'b0),
        .addra(osd_rd_addr),
        .dina(8'd0),
        .douta(osd_rd),
        .clkb(clk),
        .web(csr_osd_we),
        .addrb(csr_osd_addr),
        .dinb(csr_osd_wr),
        .doutb()
    );

    // frame operation are latched at vsync
    reg trigger_last;
    always @(posedge clk) begin
        trigger_last <= b_trigger;
    end
    wire vsync_trigger = !trigger_last & b_trigger;
    wire op_done;

    // When SPI write to CMDEN, a copy is first created in the pending register
    reg op_pending;
    reg [11:0] op_pending_left;
    reg [11:0] op_pending_right;
    reg [11:0] op_pending_top;
    reg [11:0] op_pending_bottom;
    reg [7:0] op_pending_param;
    reg [7:0] op_pending_length;
    reg [7:0] op_pending_cmd;

    // During Vsync, it's then copied into register to be used by processing
    reg op_valid;
    reg [11:0] op_left;
    reg [11:0] op_right;
    reg [11:0] op_top;
    reg [11:0] op_bottom;
    reg [7:0] op_param;
    reg [7:0] op_length;
    reg [7:0] op_cmd;
    always @(posedge clk) begin
        if (vsync_trigger && op_done) begin
            op_valid <= op_pending;
            op_left <= op_pending_left;
            op_right <= op_pending_right;
            op_top <= op_pending_top;
            op_bottom <= op_pending_bottom;
            op_param <= op_pending_param;
            op_length <= op_pending_length;
            op_cmd <= op_pending_cmd;
            op_pending <= 1'b0;
        end
        if (csr_op_en) begin
            op_pending <= 1'b1;
            op_pending_left <= csr_op_left;
            op_pending_right <= csr_op_right;
            op_pending_top <= csr_op_top;
            op_pending_bottom <= csr_op_bottom;
            op_pending_param <= csr_op_param;
            op_pending_length <= csr_op_length;
            op_pending_cmd <= csr_op_cmd;
        end
        if (rst) begin
            op_valid <= 1'b0;
            op_pending <= 1'b0;
        end
    end

    // Similarly OSD settings are buffered at Vsync to avoid tearing
    reg osd_en;
    reg [11:0] osd_left;
    reg [11:0] osd_right;
    reg [11:0] osd_top;
    reg [11:0] osd_bottom;
    always @(posedge clk) begin
        if (vsync_trigger) begin // Use the same trigger
            osd_en <= csr_osd_en;
            osd_left <= csr_osd_left;
            osd_right <= csr_osd_right;
            osd_top <= csr_osd_top;
            osd_bottom <= csr_osd_bottom;
        end
        if (rst) begin
            osd_en <= 1'b0;
        end
    end

    reg [10:0] scan_v_cnt;
    reg [10:0] scan_h_cnt;

    reg [1:0] scan_state;
    reg [1:0] op_state;
    reg frame_valid; // Global kill signal to mask off frame output

    reg [7:0] op_framecnt; // Framecount for operation transition
    assign op_done = op_framecnt == 0;

    // Counters for auto LUT mode, free running
    reg [5:0] al_framecnt;

    always @(posedge clk) begin
        case (scan_state)
        SCAN_IDLE: begin
            if (sys_ready && global_en && vin_vsync) begin
                scan_state <= SCAN_WAITING;
            end
            scan_h_cnt <= 0;
            scan_v_cnt <= 0;
        end
        SCAN_WAITING: begin
            if (scan_h_cnt == VS_DELAY) begin
                scan_state <= SCAN_RUNNING;
                frame_valid <= 1'b1;
                scan_h_cnt <= 0;
                // Set frame count limit here
                if (op_framecnt == 0) begin
                    if (op_state == `OP_INIT) begin
                        op_state <= `OP_NORMAL;
                    end
                    else if (op_valid) begin
                        op_framecnt <= op_length;
                    end
                end
                else begin
                    op_framecnt <= op_framecnt - 1;
                end
                // Update Auto LUT state
                if (al_framecnt == 0) begin
                    al_framecnt <= csr_lut_frame;
                end
                else begin
                    al_framecnt <= al_framecnt - 1;
                end
            end
            else begin
                scan_h_cnt <= scan_h_cnt + 1;
            end
        end
        SCAN_RUNNING: begin
            if (scan_h_cnt == htotal - 1) begin
                if (scan_v_cnt == vtotal - 1) begin
                    scan_state <= SCAN_IDLE;
                end
                else begin
                    scan_h_cnt <= 0;
                    scan_v_cnt <= scan_v_cnt + 1;
                end
            end
            else begin
                scan_h_cnt <= scan_h_cnt + 1;
            end
            // Kill frame output if fifo underrun is detected
            if ((vin_ready && !vin_valid) && (bi_ready && !bi_valid)) begin
                frame_valid <= 1'b0;
            end
        end
        default: begin
            // Invalid state
            $display("Scan FSM in invalid state");
            scan_state <= SCAN_IDLE;
        end
        endcase

        if (rst) begin
            scan_state <= SCAN_IDLE;
            scan_h_cnt <= 0;
            scan_v_cnt <= 0;
            op_state <= `OP_INIT;
            op_framecnt <= OP_INIT_LENGTH;
            al_framecnt <= 0;
        end
    end

    /* verilator lint_off width */
    wire scan_in_vsync = (scan_state != SCAN_IDLE) ? (
        (scan_v_cnt >= vfp) && 
        (scan_v_cnt < (vfp + vsync))) : 1'b0;
    wire scan_in_vbp = (scan_state != SCAN_IDLE) ? (
        (scan_v_cnt >= (vfp + vsync)) &&
        (scan_v_cnt < (vfp + vsync + vbp))) : 1'b0;
    wire scan_in_vact = (scan_state != SCAN_IDLE) ? (
        (scan_v_cnt >= (vfp + vsync + vbp))) : 1'b0;

    wire scan_in_hfp = (scan_state != SCAN_IDLE) ? (
        (scan_h_cnt < hfp)) : 1'b0;
    wire scan_in_hsync = (scan_state != SCAN_IDLE) ? (
        (scan_h_cnt >= hfp) &&
        (scan_h_cnt < (hfp + hsync))) : 1'b0;
    wire scan_in_hbp = (scan_state != SCAN_IDLE) ? (
        (scan_h_cnt >= (hfp + hsync)) &&
        (scan_h_cnt < (hfp + hsync + hbp))) : 1'b0;
    wire scan_in_hact = (scan_state != SCAN_IDLE) ? (
        (scan_h_cnt >= (hfp + hsync + hbp))) : 1'b0;
    /* verilator lint_on width */

    wire scan_in_act = scan_in_vact && scan_in_hact;

    // Processing pipeline: 5 stages
    // Stage 1: VIN fifo readout, BI fifo readout, OSD readout
    // Stage 2: VIN, BI->dithering unit
    // Stage 3: dithered/ vin, BI->Waveform lookup
    // Stage 4: Dithered, wvfm result->pixel processing
    // Stage 5: Writeback

    // STAGE 1
    /* verilator lint_off width */
    wire s1_hactive = (scan_state != SCAN_IDLE) ? (
        (scan_h_cnt >= (hfp + hsync + hbp - PIPELINE_DELAY)) &&
        (scan_h_cnt < (htotal - PIPELINE_DELAY))) : 1'b0;
    /* verilator lint_on width */
    wire s1_active = scan_in_vact && s1_hactive;
    // Essentially a scan_in_act but few cycles eariler.
    assign vin_ready = s1_active;
    assign bi_ready = s1_active;

    /* verilator lint_off width */
    wire [10:0] h_cnt_offset = scan_h_cnt - (hfp + hsync + hbp - PIPELINE_DELAY);
    wire [10:0] v_cnt_offset = scan_v_cnt - (vfp + vsync + vbp);
    /* verilator lint_on width */
    wire [3:0] s1_op_valid;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: gen_op_valid_assign
            wire [1:0] offset = i;
            wire [12:0] h_pixel = {h_cnt_offset, offset};
            assign s1_op_valid[i] =
                op_valid &&
                (h_pixel >= {1'b0, op_left}) && (h_pixel < {1'b0, op_right}) &&
                ({1'b0, v_cnt_offset} >= op_top) && ({1'b0, v_cnt_offset} < op_bottom);
        end
    endgenerate

    // OSD: 12 bit address, 256x128 size, each byte has 8 pixels -> 32x128
    /* verilator lint_off width */
    wire [6:0] osd_ram_y_offset = v_cnt_offset - osd_top;
    wire [4:0] osd_ram_x_offset = h_cnt_offset[10:1] - osd_left;
    /* verilator lint_on width */
    assign osd_rd_addr = {osd_ram_y_offset, osd_ram_x_offset};
    wire s1_osd_valid =
        osd_en &&
        ({1'b0, h_cnt_offset} >= osd_left) && ({1'b0, h_cnt_offset} < osd_right) &&
        ({1'b0, v_cnt_offset} >= osd_top) && ({1'b0, v_cnt_offset} < osd_bottom);

    // Move to next stage
    reg [3:0] s2_op_valid;
    reg s2_osd_valid;
    always @(posedge clk) begin
        s2_op_valid <= s1_op_valid;
        s2_osd_valid <= s1_osd_valid;
    end


    // STAGE 2
    reg s2_active;
    always @(posedge clk)
        s2_active <= s1_active;

    // OSD overlay
    wire [3:0] s2_osd_overlay = h_cnt_offset[0] ? osd_rd[7:4] : osd_rd[3:0];
    wire [31:0] s2_osd_overlay_y8 = {{8{s2_osd_overlay[3]}},
        {8{s2_osd_overlay[2]}}, {8{s2_osd_overlay[1]}}, {8{s2_osd_overlay[0]}}};
    wire [31:0] s2_vin_overlayed = s2_osd_valid ? s2_osd_overlay_y8 : vin_pixel;

    // Image dithering
    // All these processing has 1 cycle delay
    wire [3:0] s3_pixel_bayer_dithered;
    wire [3:0] s3_pixel_bn1b_dithered;
    wire [15:0] s3_pixel_bn4b_dithered;

    // Position for ordered dithering
    wire [2:0] by_x_pos;
    wire [3:0] bn_x_pos;
    wire [1:0] bn_x_pos_sel;
    wire [2:0] by_y_pos;
    wire [5:0] bn_y_pos;

    generate
    if (COLORMODE == "DES") begin: gen_des_counter
        reg [1:0] v_cnt_mod_3;
        reg [1:0] h_cnt_mod_3;
        reg [3:0] h_cnt_div_3;
        wire [2:0] v_cnt_mod_3_inc = (v_cnt_mod_3 == 2) ?
                (0) : (v_cnt_mod_3 + 1);
        wire [1:0] h_cnt_mod_3_inc = (h_cnt_mod_3 == 2) ?
                (0) : (h_cnt_mod_3 + 1);
        wire [2:0] h_cnt_div_3_inc = (h_cnt_mod_3 == 2) ?
                (h_cnt_div_3 + 1) : (h_cnt_div_3);
        always @(posedge clk)
            if (rst) begin
                v_cnt_mod_3 <= 0;
                h_cnt_mod_3 <= 0;
            end
            else begin
                if (scan_state == SCAN_RUNNING) begin
                    if (scan_h_cnt == htotal - 1) begin
                        h_cnt_mod_3 <= 0;
                        h_cnt_div_3 <= 0;
                        if (scan_v_cnt == vtotal - 1) begin
                            v_cnt_mod_3 <= 0;
                        end
                        else begin
                            v_cnt_mod_3 <= v_cnt_mod_3_inc;
                        end
                    end
                    else begin
                        h_cnt_mod_3 <= h_cnt_mod_3_inc;
                        h_cnt_div_3 <= h_cnt_div_3_inc;
                    end
                end
            end
        wire [2:0] h_cnt_bn_add = h_cnt_mod_3 + v_cnt_mod_3;
        assign by_x_pos = {1'b0, h_cnt_mod_3};
        assign bn_x_pos = h_cnt_div_3;
        assign bn_x_pos_sel =
            (h_cnt_bn_add == 3'd4) ? 2'd1 :
            (h_cnt_bn_add == 3'd3) ? 2'd0 : h_cnt_bn_add[1:0];
        assign by_y_pos = v_cnt_mod_3;
    end
    else if ((COLORMODE == "MONO") || (COLORMODE == "RGBW")) begin: gen_mono_counter
        assign by_x_pos = scan_h_cnt[2:0];
        assign bn_x_pos = scan_h_cnt[3:0];
        assign bn_x_pos_sel = 2'b0;
        assign by_y_pos = scan_v_cnt[2:0];
    end
    
    if ((COLORMODE == "DES") || (COLORMODE == "MONO")) begin: gen_mono_ypos
        assign bn_y_pos = scan_v_cnt[5:0];
    end
    else if (COLORMODE == "RGBW") begin: gen_rgbw_ypos
        assign bn_y_pos = scan_v_cnt[6:1];
    end
    endgenerate

    // Insert mirroring here
    wire [31:0] s2_vin_mirrored;
    wire [31:0] s2_vin_selected;

    line_reverse #(
        .BUFDEPTH(10), // 1024-depth
        .PIXWIDTH(32) // 4-pixel wide
    ) line_reverse (
        .clk(clk),
        .rst(vin_vsync),
        .width(hact[9:0]),
        .pix_in(s2_vin_overlayed),
        .pix_in_en(s2_active),
        // Delayed by exactly 1 line
        .pix_out_ready(s2_active),
        .pix_out(s2_vin_mirrored),
        .pix_out_valid()
    );

    assign s2_vin_selected = mirror_en ? s2_vin_mirrored : s2_vin_overlayed;

    // Slice Y8 version downto Y4
    wire [15:0] s2_vin_selected_y4 = {s2_vin_selected[31:28],
        s2_vin_selected[23:20], s2_vin_selected[15:12], s2_vin_selected[7:4]};

    // Degamma
    wire [31:0] s2_pixel_linear;
    generate
        for (i = 0; i < 4; i = i + 1) begin: gen_degamma
            degamma degamma (
                .in(s2_vin_selected[i*8+2 +: 6]),
                .out(s2_pixel_linear[i*8 +: 8])
            );
        end
    endgenerate
    //assign s2_pixel_linear = s2_vin_overlayed;

    // Output dithered pixel 1 clock later
    blue_noise_dithering #(
        .OUTPUT_BITS(1),
        .COLORMODE(COLORMODE)
    ) blue_noise_dithering_1b (
        .clk(clk),
        .vin(s2_pixel_linear),
        .vout(s3_pixel_bn1b_dithered),
        .x_pos(bn_x_pos),
        .x_pos_sel(bn_x_pos_sel),
        .y_pos(bn_y_pos)
    );

    blue_noise_dithering #(
        .OUTPUT_BITS(4),
        .COLORMODE(COLORMODE)
    ) blue_noise_dithering_4b (
        .clk(clk),
        .vin(s2_pixel_linear),
        .vout(s3_pixel_bn4b_dithered),
        .x_pos(bn_x_pos),
        .x_pos_sel(bn_x_pos_sel),
        .y_pos(bn_y_pos)
    );

    bayer_dithering #(
        .COLORMODE(COLORMODE)
    ) bayer_dithering (
        .clk(clk),
        .vin(s2_pixel_linear),
        .vout(s3_pixel_bayer_dithered),
        .x_pos(by_x_pos),
        .y_pos(by_y_pos)
    );

    // Move to next stage
    reg [63:0] s3_bi_pixel;
    reg [15:0] s3_vin_pixel;
    reg [3:0] s3_op_valid;
    always @(posedge clk) begin
        s3_vin_pixel <= s2_vin_selected_y4;
        s3_bi_pixel <= bi_pixel;
        s3_op_valid <= s2_op_valid;
    end

    // STAGE 3
    reg s3_active;
    always @(posedge clk)
        s3_active <= s2_active;

    // Waveform lookup here
    // Waveform structure:
    // 14 bit address input
    //   6 bit sequence ID
    //   4 bit source grayscale
    //   4 bit destination grayscale
    // 2 bit data output
    // 32 Kb
    wire [13:0] ram_addr_rd [0:3];
    wire [7:0] s4_lut_rd; // 1 cycle latency
    generate
        for (i = 0; i < 4; i = i + 1) begin: gen_wvfm_lookup
            // See pixel_processing.v comments for more details
            // Only used for LUT modes.
            // Local counter (per pixel counter) is used for manual LUT modes
            // Global counter is used for auto LUT modes
            /*verilator lint_off UNUSEDSIGNAL */
            wire [15:0] wvfm_bi = s3_bi_pixel[i*16 +: 16];
            /*verilator lint_on UNUSEDSIGNAL */
            wire use_local_counter =  wvfm_bi[15];
            wire [5:0] wvfm_fcnt_global_counter = wvfm_bi[9:4];
            wire [5:0] wvfm_fcnt_local_counter = al_framecnt;
            wire [5:0] wvfm_fcnt = use_local_counter ?
                    wvfm_fcnt_local_counter : wvfm_fcnt_global_counter;
            wire [5:0] wvfm_fseq = csr_lut_frame - wvfm_fcnt;
            wire [3:0] wvfm_src_global_counter = wvfm_bi[13:10];
            wire [3:0] wvfm_src_local_counter = wvfm_bi[7:4];
            wire [3:0] wvfm_src = use_local_counter ?
                    wvfm_src_local_counter : wvfm_src_global_counter;
            wire [3:0] wvfm_tgt = wvfm_bi[3:0];
            assign ram_addr_rd[i] = {wvfm_fseq, wvfm_tgt, wvfm_src};
            assign dbg_wvfm_tgt[i*4+:4] = wvfm_tgt;
        end
    endgenerate

    wire ram_we = csr_lut_we;
    wire [7:0] ram_wr = csr_lut_wr;
    wire [11:0] ram_addr_wr = csr_lut_addr;

    wvfmlut wvfmlut1 (
        .clk(clk),
        .we(ram_we),
        .addr(ram_addr_wr),
        .din(ram_wr),
        .addra(ram_addr_rd[0]),
        .douta(s4_lut_rd[1:0]),
        .addrb(ram_addr_rd[1]),
        .doutb(s4_lut_rd[3:2])
    );

    wvfmlut wvfmlut2 (
        .clk(clk),
        .we(ram_we),
        .addr(ram_addr_wr),
        .din(ram_wr),
        .addra(ram_addr_rd[2]),
        .douta(s4_lut_rd[5:4]),
        .addrb(ram_addr_rd[3]),
        .doutb(s4_lut_rd[7:6])
    );

    // Move to next stage
    reg [63:0] s4_bi_pixel;
    reg [15:0] s4_vin_pixel;
    reg [3:0] s4_pixel_bayer_dithered;
    reg [3:0] s4_pixel_bn1b_dithered;
    reg [15:0] s4_pixel_bn4b_dithered;
    reg [3:0] s4_op_valid;
    
    always @(posedge clk) begin
        s4_vin_pixel <= s3_vin_pixel;
        s4_bi_pixel <= s3_bi_pixel;
        // For 1 bit dithering, only pick MSB of each pixel
        s4_pixel_bayer_dithered <= s3_pixel_bayer_dithered;
        s4_pixel_bn1b_dithered <= s3_pixel_bn1b_dithered;
        s4_pixel_bn4b_dithered <= s3_pixel_bn4b_dithered;
        s4_op_valid <= s3_op_valid;
    end

    // STAGE 4
    reg s4_active;
    always @(posedge clk) begin
        s4_active <= s3_active;
    end

    wire [7:0] pixel_comb;
    wire [63:0] bo_pixel_comb;
    generate
        for (i = 0; i < 4; i = i + 1) begin: gen_pix_proc
            wire [3:0] proc_p_or = s4_vin_pixel[i*4+:4];
            wire proc_p_bd = s4_pixel_bayer_dithered[i];
            wire proc_p_n1 = s4_pixel_bn1b_dithered[i];
            wire [3:0] proc_p_n4 = s4_pixel_bn4b_dithered[i*4+:4];
            wire [15:0] proc_bi = s4_bi_pixel[i*16+:16];
            wire [15:0] proc_bo;
            wire [1:0] proc_lut_rd = s4_lut_rd[i*2+:2];
            wire [1:0] proc_output;

            pixel_processing pixel_processing(
                .csr_lutframe(csr_lut_frame),
                .csr_mindrv(csr_mindrv),
                .proc_p_or(proc_p_or),
                .proc_p_bd(proc_p_bd),
                .proc_p_n1(proc_p_n1),
                .proc_p_n4(proc_p_n4),
                .proc_bi(proc_bi),
                .proc_bo(proc_bo),
                .proc_lut_rd(proc_lut_rd),
                .proc_output(proc_output),
                .op_state(op_state),
                .op_valid(s4_op_valid[i]),
                .op_cmd(op_cmd),
                .op_param(op_param),
                .op_framecnt(op_framecnt),
                .al_framecnt(al_framecnt)
            );

            // Output
            assign pixel_comb[i*2+:2] = frame_valid ? proc_output : 2'b00;
            assign bo_pixel_comb[i*16+:16] = frame_valid ? proc_bo : proc_bi;
        end
    endgenerate

    reg [7:0] current_pixel;
    always @(posedge clk) begin
        current_pixel <= (s4_active) ? pixel_comb : 8'h00;
        bo_pixel <= bo_pixel_comb;
    end

    // Stage 5: WB
    reg s5_active;
    always @(posedge clk)
        s5_active <= s4_active;
    assign bo_valid = s5_active;

    // End of pipeline
    wire clk_en = (scan_in_hfp || scan_in_hsync || scan_in_hact);

`ifdef OUTPUT_16B
    reg out_clk;
    reg [7:0] last_pix;
    reg [15:0] out_sd;
    reg out_sdce;
    always @(posedge clk) begin
        if (clk_en) begin
            out_clk <= ~out_clk;
        end
        else begin
            out_clk <= 1'b0;
        end
        if (out_clk) begin
            // next edge is falling edge, output data
            out_sd <= {last_pix, current_pixel};
            out_sdce <= !scan_in_act;
        end
        else begin
            // next edge is rising edge, buffer data
            last_pix <= current_pixel;
        end
    end
    assign epd_sdclk = out_clk;
    assign epd_sd = out_sd;
    assign epd_sdce0 = out_sdce;
`else
    // Clock output
    `ifdef SIMULATION
        assign epd_sdclk = ~clk;
    `else
        // SPARTAN-6 specific output
        ODDR2 #(
            .DDR_ALIGNMENT("NONE"),
            .INIT(1'b0),
            .SRTYPE("SYNC")
        ) sdclk_oddr (
            .Q(epd_sdclk),
            .C0(clk),
            .C1(!clk),
            .CE(1'b1),
            .D0(1'b0),
            .D1(1'b1),
            .R(1'b0),
            .S(1'b0)
        );
    `endif

    assign epd_sd = {8'd0, current_pixel}; // In 8-bit mode, only use lower 8-bit
    assign epd_sdce0 = (scan_in_act) ? 1'b0 : 1'b1;
`endif

    // mode
    //assign epd_gdoe = (scan_in_vsync || scan_in_vbp || scan_in_vact) ? 1'b1 : 1'b0;
    assign epd_gdoe = 1'b1;
    // ckv
    wire epd_gdclk_pre = (scan_in_hsync || scan_in_hbp || scan_in_hact) ? 1'b1 : 1'b0;
    reg epd_gdclk_delay;
    always @(posedge clk)
        epd_gdclk_delay <= epd_gdclk_pre;
    assign epd_gdclk = epd_gdclk_delay;

    // spv
    assign epd_gdsp = (scan_in_vsync) ? 1'b0 : 1'b1;
    //assign epd_sdoe = epd_gdoe;
    assign epd_sdoe = 1'b1;
    
    // stl
    
    assign epd_sdle = (scan_in_hsync) ? 1'b1 : 1'b0;

    assign b_trigger = (scan_state == SCAN_WAITING);

    assign dbg_scan_state = scan_state;
    assign dbg_scan_h_cnt = scan_h_cnt;
    //assign dbg_scan_v_cnt = scan_v_cnt;
    assign dbg_scan_v_cnt[0] = op_pending;
    assign dbg_scan_v_cnt[1] = op_valid;
    assign dbg_scan_v_cnt[2] = vsync_trigger;
    assign dbg_scan_v_cnt[3] = b_trigger;
    assign dbg_scan_v_cnt[4] = osd_en;
    assign dbg_scan_v_cnt[5] = csr_osd_en;
    assign dbg_scan_v_cnt[7:6] = scan_state;
    assign dbg_scan_v_cnt[10:8] = 'd0;

endmodule
`default_nettype wire
