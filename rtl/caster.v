`timescale 1ns / 1ps
`default_nettype none
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

    parameter COLORMODE = "MONO";

    // Screen timing
    // Timing starts when VS is detected
    parameter V_FP = 3; // Lines before sync with SDOE / GDOE low, GDSP high (inactive)
    parameter V_SYNC = 1; // Lines at sync with SDOE / GDOE high, GDSP low (active)
    parameter V_BP = 2; // Lines before data becomes active
    parameter V_ACT = 120;
    localparam V_TOTAL = V_FP + V_SYNC + V_BP + V_ACT;
    parameter H_FP = 2; // SDLE low (inactive), SDCE0 high (inactive), clock active
    parameter H_SYNC = 1; // SDLE high (active), SDCE0 high (inactive), GDCLK lags by 1 clock, clock active
    parameter H_BP = 2; // SDLE low (inactive), SDCE0 high (inactive), no clock
    parameter H_ACT = 40; // Active pixels / 4, SDCE0 low (active)
    localparam H_TOTAL = H_FP + H_SYNC + H_BP + H_ACT;

    parameter SIMULATION = "TRUE";

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
    localparam PIPELINE_DELAY = 4;

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

    // Processing pipeline: 5 stages
    // Stage 1: VIN fifo readout, BI fifo readout
    // Stage 2: VIN, BI->dithering unit
    // Stage 3: dithered/ vin, BI->Waveform lookup
    // Stage 4: Dithered, wvfm result->pixel processing
    // Stage 5: Writeback

    // STAGE 1
    wire s1_hactive = (scan_state != SCAN_IDLE) ? (
        (scan_h_cnt >= (H_FP + H_SYNC + H_BP - PIPELINE_DELAY)) &&
        (scan_h_cnt < (H_TOTAL - PIPELINE_DELAY))) : 1'b0;
    wire s1_active = scan_in_vact && s1_hactive;
    // Essentially a scan_in_act but few cycles eariler.
    assign vin_ready = s1_active;
    assign bi_ready = s1_active;

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
                    if (scan_h_cnt == H_TOTAL - 1) begin
                        if (scan_v_cnt == V_TOTAL - 1) begin
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
    else if (COLORMODE == "MONO") begin
        assign x_pos = scan_h_cnt[2:0];
        assign y_pos = scan_v_cnt[2:0];
    end
    endgenerate

    // Output dithered pixel 1 clock later
    ordered_dithering #(
        .COLORMODE(COLORMODE)
    ) ordered_dithering (
        .clk(clk),
        .rst(rst),
        .vin(vin_pixel),
        .vout(s2_pixel_ordered_dithered),
        .x_pos(x_pos),
        .y_pos(y_pos)
    );

    // vin and bi pixel are duplicated for use in next stage
    reg [63:0] s2_bi_pixel;
    reg [15:0] s2_vin_pixel;
    always @(posedge clk) begin
        s2_vin_pixel <= vin_pixel;
        s2_bi_pixel <= bi_pixel;
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
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: wvfm_lookup
            wire [3:0] wvfm_vin = s2_vin_pixel[i*4+3 : i*4];
            wire [15:0] wvfm_bi = s2_bi_pixel[i*16+15 : i*16];
            wire [5:0] wvfm_fcnt = wvfm_bi[9:4];
            wire [3:0] wvfm_prev = wvfm_bi[3:0];
            assign ram_addr_rd[i] = {wvfm_fcnt, wvfm_prev, wvfm_vin};
        end
    endgenerate

    wire ram_we;
    wire [1:0] ram_wr;
    wire [13:0] ram_addr_wr;

    bramdp bramdp0 (
        .clka(clk),
        .wea(ram_we),
        .addra(ram_we ? ram_addr_wr : ram_addr_rd[0]),
        .dina(ram_wr),
        .douta(s3_lut_rd[1:0]),
        .clkb(clk),
        .web(1'b0),
        .addrb(ram_addr_rd[1]),
        .dinb(2'b0),
        .doutb(s3_lut_rd[3:2])
    );

    bramdp bramdp1 (
        .clka(clk),
        .wea(ram_we),
        .addra(ram_we ? ram_addr_wr : ram_addr_rd[2]),
        .dina(ram_wr),
        .douta(s3_lut_rd[5:4]),
        .clkb(clk),
        .web(1'b0),
        .addrb(ram_addr_rd[3]),
        .dinb(2'b0),
        .doutb(s3_lut_rd[7:6])
    );

    reg [63:0] s3_bi_pixel;
    reg [15:0] s3_vin_pixel;
    reg [15:0] s3_pixel_ordered_dithered;
    always @(posedge clk) begin
        s3_vin_pixel <= s2_vin_pixel;
        s3_bi_pixel <= s2_bi_pixel;
        s3_pixel_ordered_dithered <= s2_pixel_ordered_dithered;
    end

    // STAGE 4
    reg s4_active;
    always @(posedge clk)
        s4_active <= s3_active;

    wire [7:0] pixel_comb;
    wire [63:0] bo_pixel_comb;
    generate
        for (i = 0; i < 4; i = i + 1) begin: pix_proc
            wire [3:0] proc_p_or = s3_vin_pixel[i*4+3 : i*4];
            wire [3:0] proc_p_od = s3_pixel_ordered_dithered[i*4+3 : i*4];
            wire [3:0] proc_p_e1 = 4'd0; // not implemented yet
            wire [3:0] proc_p_e4 = 4'd0; // not implemented yet
            wire [15:0] proc_bi = s3_bi_pixel[i*16+15 : i*16];
            wire [15:0] proc_bo;
            wire [1:0] proc_lut_rd = s3_lut_rd[i*2+1 : i*2];
            wire [1:0] proc_output;

            pixel_processing pixel_processing(
                .proc_p_or(proc_p_or),
                .proc_p_od(proc_p_od),
                .proc_p_e1(proc_p_e1),
                .proc_p_e4(proc_p_e4),
                .proc_bi(proc_bi),
                .proc_bo(proc_bo),
                .proc_lut_rd(proc_lut_rd),
                .proc_output(proc_output),
                .op_state(op_state),
                .op_framecount(op_framecount)
            );

            // Output
            assign pixel_comb[i*2+1 : i*2] = proc_output;
            assign bo_pixel_comb[i*16+15 : i*16] = proc_bo;
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

    // TODO: CSR interface
    assign ram_we = 1'b0;
    assign ram_wr = 2'd0;
    assign ram_addr_wr = 14'd0;

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
