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
    output reg          bi_ready,
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

    parameter COLORMODE = "DES";

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
    localparam PIPELINE_DELAY = 3;

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

    // Image dithering
    wire [15:0] pixel_dithered;
    wire [2:0] x_pos;
    wire [2:0] y_pos;

    generate
    if (COLORMODE == "DES") begin: des_counter
        reg [2:0] v_cnt_mod_6;
        reg [1:0] h_cnt_mod_3;
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
                            if (v_cnt_mod_6 == 5)
                                v_cnt_mod_6 <= 0;
                            else
                                v_cnt_mod_6 <= v_cnt_mod_6 + 1;
                        end
                    end
                    else begin
                        if (h_cnt_mod_3 == 2)
                            h_cnt_mod_3 <= 0;
                        else
                            h_cnt_mod_3 <= h_cnt_mod_3 + 1;
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
    dithering #(
        .COLORMODE(COLORMODE)
    ) dithering (
        .clk(clk),
        .rst(rst),
        .vin(vin_pixel),
        .vout(pixel_dithered),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .mode(1'd1)
    );

    wire [7:0] pixel_comb;
    wire [63:0] bo_pixel_comb;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: pix_proc
            wire [3:0] proc_vin = pixel_dithered[i*4+3 : i*4];
            wire [15:0] proc_bi = bi_pixel[i*16+15 : i*16];
            wire [15:0] proc_bo;
            wire [1:0] proc_output;

            pixel_processing pixel_processing(
                .proc_vin(proc_vin),
                .proc_bi(proc_bi),
                .proc_bo(proc_bo),
                .proc_output(proc_output),
                .op_state(op_state),
                .op_framecount(op_framecount)
            );

            // Output
            assign pixel_comb[i*2+1 : i*2] = proc_output;
            assign bo_pixel_comb[i*16+15 : i*16] = proc_bo;
        end
    endgenerate

    wire mask_in_hact = (scan_state != SCAN_IDLE) ? (
        (scan_h_cnt >= (H_FP + H_SYNC + H_BP - 1)) &&
        (scan_h_cnt < (H_TOTAL - 1))) : 1'b0;
    wire mask_in_act = scan_in_vact && mask_in_hact;

    reg [7:0] current_pixel;
    always @(posedge clk) begin
        current_pixel <= (mask_in_act) ? pixel_comb : 8'h00;
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

    always @(posedge clk)
        bi_ready <= vin_ready; // bi_ready lags vin_ready for 1 cycle for dithering
    assign bo_valid = scan_in_act;

    assign b_trigger = (scan_state == SCAN_WAITING);

endmodule
