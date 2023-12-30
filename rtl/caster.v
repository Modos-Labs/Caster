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
    input  wire [31:0]  vin_pixel,
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
    output wire         epd_sdce0,
    // CSR SPI interface
    input  wire         spi_cs,
    input  wire         spi_sck,
    input  wire         spi_mosi,
    output wire         spi_miso,
    // Control / Status
    input  wire         sys_ready, // Power OK, DDR calibration done, etc.
    input  wire         mig_error,
    input  wire         mif_error,
    output wire [23:0]  frame_bytes,
    output wire         global_en
    );

    parameter COLORMODE = "MONO";

    // Screen timing
    parameter SIMULATION = "TRUE";

    // Output logic
    localparam SCAN_IDLE = 2'd0;
    localparam SCAN_WAITING = 2'd1;
    localparam SCAN_RUNNING = 2'd2;

    localparam OP_INIT_LENGTH = (SIMULATION == "FALSE") ? 255 : 2;

    // Internal design specific
    localparam VS_DELAY = 8; // wait 8 clocks after VS is vaild
    localparam PIPELINE_DELAY = 4;

    // Control status registers
    wire [5:0] csr_lutframe;
    wire [11:0] csr_lutaddr;
    wire [7:0] csr_lutwr;
    wire csr_lutwe;
    wire [11:0] csr_opleft;
    wire [11:0] csr_opright;
    wire [11:0] csr_optop;
    wire [11:0] csr_opbottom;
    wire [7:0] csr_opparam;
    wire [7:0] csr_oplength;
    wire [7:0] csr_opcmd;
    wire csr_ope;
    wire [7:0] vfp;
    wire [7:0] vsync;
    wire [7:0] vbp;
    wire [11:0] vact;
    wire [7:0] hfp;
    wire [7:0] hsync;
    wire [7:0] hbp;
    wire [11:0] hact;
    csr csr (
        .clk(clk),
        .rst(rst),
        .spi_cs(spi_cs),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .csr_lutframe(csr_lutframe),
        .csr_lutaddr(csr_lutaddr),
        .csr_lutwr(csr_lutwr),
        .csr_lutwe(csr_lutwe),
        .csr_opleft(csr_opleft),
        .csr_opright(csr_opright),
        .csr_optop(csr_optop),
        .csr_opbottom(csr_opbottom),
        .csr_opparam(csr_opparam),
        .csr_oplength(csr_oplength),
        .csr_opcmd(csr_opcmd),
        .csr_ope(csr_ope),
        .csr_cfg_vfp(vfp),
        .csr_cfg_vsync(vsync),
        .csr_cfg_vbp(vbp),
        .csr_cfg_vact(vact),
        .csr_cfg_hfp(hfp),
        .csr_cfg_hsync(hsync),
        .csr_cfg_hbp(hbp),
        .csr_cfg_hact(hact),
        .csr_cfg_fbytes(frame_bytes),
        .csr_ctrl_en(global_en),
        // Status input
        .sys_ready(sys_ready),
        .mig_error(mig_error),
        .mif_error(mif_error),
        .op_busy(op_valid),
        .op_queue(op_pending)
    );

    /* verilator lint_off width */
    wire [10:0] vtotal = vfp + vsync + vbp + vact;
    wire [10:0] htotal = hfp + hsync + hbp + hact;
    /* verilator lint_on width */

    // frame operation are latched at vsync
    reg trigger_last;
    always @(posedge clk) begin
        trigger_last <= b_trigger;
    end
    wire op_trigger = !trigger_last & b_trigger;
    wire op_done;

    // When SPI write to CMDEN, a copy is first created in the pending register
    reg op_pending;
    reg [11:0] op_pending_left;
    reg [11:0] op_pending_right;
    reg [11:0] op_pending_top;
    reg [11:0] op_pending_bottom;
    reg [7:0] op_pending_param;
    reg [7:0] op_pending_cmd;

    // During Vsync, it's then copied into register to be used by processing
    reg op_valid;
    reg [11:0] op_left;
    reg [11:0] op_right;
    reg [11:0] op_top;
    reg [11:0] op_bottom;
    reg [7:0] op_param;
    reg [7:0] op_cmd;
    always @(posedge clk) begin
        if (op_trigger && op_done) begin
            op_valid <= op_pending;
            op_left <= op_pending_left;
            op_right <= op_pending_right;
            op_top <= op_pending_top;
            op_bottom <= op_pending_bottom;
            op_param <= op_pending_param;
            op_cmd <= op_pending_cmd;
            op_pending <= 1'b0;
        end
        if (csr_ope) begin
            op_pending <= 1'b1;
            op_pending_left <= csr_opleft;
            op_pending_right <= csr_opright;
            op_pending_top <= csr_optop;
            op_pending_bottom <= csr_opbottom;
            op_pending_param <= csr_opparam;
            op_pending_cmd <= csr_opcmd;
        end
        if (rst) begin
            op_valid <= 1'b0;
            op_pending <= 1'b0;
        end
    end

    reg [10:0] scan_v_cnt;
    reg [10:0] scan_h_cnt;

    reg [1:0] scan_state;
    reg [1:0] op_state;
    reg frame_valid; // Global kill signal to mask off frame output

    reg [7:0] op_framecnt; // Framecount for operation transition
    assign op_done = op_framecnt == 0;

    // Counters for auto LUT mode
    reg [5:0] al_framecnt;
    reg al_diff_reg;
    wire al_diff;

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
                        op_framecnt <= csr_oplength;
                    end
                end
                else begin
                    op_framecnt <= op_framecnt - 1;
                end
                // Update Auto LUT state
                if (al_framecnt == 0) begin
                    if (al_diff_reg) begin
                        al_framecnt <= csr_lutframe;
                    end
                end
                else begin
                    al_framecnt <= al_framecnt - 1;
                end
                al_diff_reg <= 1'b0;
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
            // Update auto LUT state
            if (al_diff)
                al_diff_reg <= 1'b1;
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
            al_diff_reg <= 0;
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
    // Stage 1: VIN fifo readout, BI fifo readout
    // Stage 2: VIN, BI->dithering unit
    // Stage 3: dithered/ vin, BI->Waveform lookup
    // Stage 4: Dithered, wvfm result->pixel processing
    // Stage 5: Writeback

    // STAGE 1
    /* verilator lint_off width */
    wire s1_hactive = (scan_state != SCAN_IDLE) ? (
        (scan_h_cnt >= (hfp + hsync + hbp - PIPELINE_DELAY)) &&
        (scan_h_cnt < (htotal - PIPELINE_DELAY))) : 1'b0;
    wire s1_hsync = (scan_state != SCAN_IDLE) ? (scan_h_cnt == 'd0) : 1'b0;
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
    generate
        for (i = 0; i < 4; i = i + 1) begin: op_valid_assign
            wire [1:0] offset = i;
            wire [12:0] h_pixel = {h_cnt_offset, offset};
            assign s1_op_valid[i] =
                op_valid &&
                (h_pixel >= {1'b0, op_left}) && (h_pixel < {1'b0, op_right}) &&
                ({1'b0, v_cnt_offset} >= op_top) && ({1'b0, v_cnt_offset} < op_bottom);
        end
    endgenerate

    // STAGE 2
    reg s2_active;
    always @(posedge clk)
        s2_active <= s1_active;

    // Image dithering
    wire [15:0] s2_pixel_ordered_dithered;
    wire [2:0] x_pos;
    wire [2:0] y_pos;

    generate
    if (COLORMODE == "DES") begin: des_counter
        reg [2:0] v_cnt_mod_6;
        reg [1:0] h_cnt_mod_3;
        wire [2:0] v_cnt_mod_6_inc = (v_cnt_mod_6 == 5) ?
                (0) : (v_cnt_mod_6 + 1);
        wire [1:0] h_cnt_mod_3_inc = (h_cnt_mod_3 == 2) ?
                (0) : (h_cnt_mod_3 + 1);
        always @(posedge clk)
            if (rst) begin
                v_cnt_mod_6 <= 0;
                h_cnt_mod_3 <= 0;
            end
            else begin
                if (scan_state == SCAN_RUNNING) begin
                    if (scan_h_cnt == htotal - 1) begin
                        if (scan_v_cnt == vtotal - 1) begin
                            v_cnt_mod_6 <= 0;
                        end
                        else begin
                            h_cnt_mod_3 <= 0;
                            v_cnt_mod_6 <= v_cnt_mod_6_inc;
                        end
                    end
                    else begin
                        h_cnt_mod_3 <= h_cnt_mod_3_inc;
                    end
                end
            end
        assign x_pos = {1'b0, h_cnt_mod_3};
        assign y_pos = v_cnt_mod_6;
    end
    else if (COLORMODE == "MONO") begin: mono_counter
        assign x_pos = scan_h_cnt[2:0];
        assign y_pos = scan_v_cnt[2:0];
    end
    endgenerate

    // Degamma
    wire [31:0] s2_pixel_linear;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: wvfm_lookup
            degamma degamma (
                .in(vin_pixel[i*8+2 +: 6]),
                .out(s2_pixel_linear[i*8 +: 8])
            );
        end
    endgenerate

    // Output dithered pixel 1 clock later
    ordered_dithering #(
        .COLORMODE(COLORMODE)
    ) ordered_dithering (
        .clk(clk),
        .rst(rst),
        .vin(s2_pixel_linear),
        .vout(s2_pixel_ordered_dithered),
        .x_pos(x_pos),
        .y_pos(y_pos)
    );

    wire [3:0] s2_pixel_ed1b_dithered;
    error_diffusion_dithering #(
        .INPUT_BITS(8),
        .OUTPUT_BITS(1),
        .PIXEL_RATE(4)
    ) ed1b_dithering (
        .clk(clk),
        .rst(rst),
        .in(s2_pixel_linear),
        .in_valid(s2_active),
        .hsync(s1_hsync),
        .vsync(scan_in_vsync),
        .out(s2_pixel_ed1b_dithered)
    );

    // Slice Y8 input downto Y4
    wire [15:0] s1_vin_pixel_y4 = {vin_pixel[31:28], vin_pixel[23:20],
            vin_pixel[15:12], vin_pixel[7:4]};

    // vin and bi pixel are duplicated for use in next stage
    reg [63:0] s2_bi_pixel;
    reg [15:0] s2_vin_pixel;
    reg [3:0] s2_op_valid;
    always @(posedge clk) begin
        s2_vin_pixel <= s1_vin_pixel_y4;
        s2_bi_pixel <= bi_pixel;
        s2_op_valid <= s1_op_valid;
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
    wire [7:0] s3_lut_rd;
    generate
        for (i = 0; i < 4; i = i + 1) begin: wvfm_lookup
            // See pixel_processing.v comments for more details
            // Only used for LUT modes.
            // Local counter (per pixel counter) is used for manual LUT modes
            // Global counter is used for auto LUT modes
            /*verilator lint_off UNUSEDSIGNAL */
            wire [15:0] wvfm_bi = s2_bi_pixel[i*16 +: 16];
            /*verilator lint_on UNUSEDSIGNAL */
            wire use_local_counter =  wvfm_bi[15];
            wire [5:0] wvfm_fcnt_global_counter = wvfm_bi[9:4];
            wire [5:0] wvfm_fcnt_local_counter = al_framecnt;
            wire [5:0] wvfm_fcnt = use_local_counter ?
                    wvfm_fcnt_local_counter : wvfm_fcnt_global_counter;
            wire [5:0] wvfm_fseq = csr_lutframe - wvfm_fcnt;
            wire [3:0] wvfm_src_global_counter = wvfm_bi[13:10];
            wire [3:0] wvfm_src_local_counter = wvfm_bi[7:4];
            wire [3:0] wvfm_src = use_local_counter ?
                    wvfm_src_local_counter : wvfm_src_global_counter;
            wire [3:0] wvfm_tgt = wvfm_bi[3:0];
            assign ram_addr_rd[i] = {wvfm_fseq, wvfm_tgt, wvfm_src};
        end
    endgenerate

    wire ram_we = csr_lutwe;
    wire [7:0] ram_wr = csr_lutwr;
    wire [11:0] ram_addr_wr = csr_lutaddr;

    wvfmlut wvfmlut1 (
        .clk(clk),
        .we(ram_we),
        .addr(ram_addr_wr),
        .din(ram_wr),
        .addra(ram_addr_rd[0]),
        .douta(s3_lut_rd[1:0]),
        .addrb(ram_addr_rd[1]),
        .doutb(s3_lut_rd[3:2])
    );

    wvfmlut wvfmlut2 (
        .clk(clk),
        .we(ram_we),
        .addr(ram_addr_wr),
        .din(ram_wr),
        .addra(ram_addr_rd[2]),
        .douta(s3_lut_rd[5:4]),
        .addrb(ram_addr_rd[3]),
        .doutb(s3_lut_rd[7:6])
    );

    reg [63:0] s3_bi_pixel;
    reg [15:0] s3_vin_pixel;
    reg [15:0] s3_pixel_ordered_dithered;
    reg [3:0] s3_pixel_ed1b_dithered;
    reg [3:0] s3_op_valid;
    always @(posedge clk) begin
        s3_vin_pixel <= s2_vin_pixel;
        s3_bi_pixel <= s2_bi_pixel;
        s3_pixel_ordered_dithered <= s2_pixel_ordered_dithered;
        s3_pixel_ed1b_dithered <= s2_pixel_ed1b_dithered;
        s3_op_valid <= s2_op_valid;
    end

    // STAGE 4
    reg s4_active;
    reg [3:0] s4_op_valid;
    always @(posedge clk) begin
        s4_active <= s3_active;
        s4_op_valid <= s3_op_valid;
    end

    wire [7:0] pixel_comb;
    wire [63:0] bo_pixel_comb;
    wire [3:0] al_diff_pixel;
    generate
        for (i = 0; i < 4; i = i + 1) begin: pix_proc
            wire [3:0] proc_p_or = s3_vin_pixel[i*4+3 : i*4];
            wire [3:0] proc_p_od = s3_pixel_ordered_dithered[i*4+3 : i*4];
            wire [3:0] proc_p_e1 = {4{s3_pixel_ed1b_dithered[i]}};
            wire [3:0] proc_p_e4 = 4'd0; // not implemented yet
            wire [15:0] proc_bi = s3_bi_pixel[i*16+15 : i*16];
            wire [15:0] proc_bo;
            wire [1:0] proc_lut_rd = s3_lut_rd[i*2+1 : i*2];
            wire [1:0] proc_output;

            pixel_processing pixel_processing(
                .csr_lutframe(csr_lutframe),
                .proc_p_or(proc_p_or),
                .proc_p_od(proc_p_od),
                .proc_p_e1(proc_p_e1),
                .proc_p_e4(proc_p_e4),
                .proc_bi(proc_bi),
                .proc_bo(proc_bo),
                .proc_lut_rd(proc_lut_rd),
                .proc_output(proc_output),
                .op_state(op_state),
                .op_valid(s4_op_valid[i]),
                .op_cmd(op_cmd),
                .op_param(op_param),
                .op_framecnt(op_framecnt),
                .al_framecnt(al_framecnt),
                .al_diff(al_diff_pixel[i])
            );

            // Output
            assign pixel_comb[i*2+1 : i*2] = frame_valid ? proc_output : 2'b00;
            assign bo_pixel_comb[i*16+15 : i*16] = frame_valid ? proc_bo : proc_bi;
        end
    endgenerate
    assign al_diff = s4_active && (|al_diff_pixel);

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

    assign b_trigger = (scan_state == SCAN_WAITING);

endmodule
`default_nettype wire
