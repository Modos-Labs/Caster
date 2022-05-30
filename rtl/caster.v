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
    input  wire         pok,
    // New image Input, 4 pix per clock, Y4 input
    // This input is buffered after a ASYNC FIFO
    input  wire         vin_vsync,
    input  wire [15:0]  vin_pixel,
    input  wire         vin_valid,
    output wire         vin_ready,
    // Framebuffer input
    // 16 bit per pixel for state
    input  wire [63:0]  bi_pixel,
    input  wire         bi_valid,
    output wire         bi_ready,
    // Framebuffer output
    output wire [63:0]  bo_pixel,
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
    output wire         epd_sdce0
    );

    // Pixel state: 16bits
    // Bit 15-14: Mode
    //   Mode 0: Normal LUT mode
    //   Mode 1: Fast mono mode
    //   Mode 2: Reserved (Fast greyscale mode)
    //   Mode 3: Reserved
    
    // In normal LUT mode:
    // Bit 13: LUT ID
    //   The following is just a suggestion.
    //   Only up to 2 are allowed due to limited LUT RAM size
    //   ID 0: DU / A2
    //   ID 1: GC16
    // Bit 12-10: Reserved
    // Bit 9-4: Frame counter (up to 64 frames)
    // Bit 3-0: Previous frame pixel value
    
    // In fast mono mode:
    // Bit 13-10: Reserved
    // Bit 9-4: Frame counter
    // Bit 3-0: Reserved
    always @(posedge clk) begin
       
    end
    
    // Screen timing
    // 800x600 timing
    localparam V_FP = 4; // Lines before sync with SDOE / GDOE low, GDSP high (inactive)
    localparam V_SYNC = 1; // Lines at sync with SDOE / GDOE high, GDSP low (active)
    localparam V_BP = 3; // Lines before data becomes active
    localparam V_ACTIVE = 1200;
    localparam V_TOTAL = V_FP + V_SYNC + V_BP + V_ACTIVE;
    localparam H_FP = 10; // SDLE low (inactive), SDCE0 high (inactive), clock active
    localparam H_SYNC = 10; // SDLE high (active), SDCE0 high (inactive), GDCLK lags by 1 clock, clock active
    localparam H_BP = 4; // SDLE low (inactive), SDCE0 high (inactive), no clock
    localparam H_ACTIVE = 400; // Active pixels / 4, SDCE0 low (active)
    localparam H_TOTAL = H_FP + H_SYNC + H_BP + H_ACTIVE;

    // Output logic
    localparam SCAN_IDLE = 1'b0;
    localparam SCAN_RUNNING = 1'b1;
    
    reg [10:0] scan_v_cnt;
    reg [10:0] scan_h_cnt;
    
    // Temp
    reg [7:0] frame_counter;

    reg scan_state;
    always @(posedge clk)
        if (rst) begin
            scan_state <= SCAN_IDLE;
            scan_h_cnt <= 0;
            scan_v_cnt <= 0;
            frame_counter <= 0;
        end
        else begin
            case (scan_state)
            SCAN_IDLE: begin
                if ((pok) && (frame_counter < 8'd50)) begin
                    scan_state <= SCAN_RUNNING;
                    frame_counter <= frame_counter + 1;
                end
                scan_h_cnt <= 0;
                scan_v_cnt <= 0;
            end
            SCAN_RUNNING: begin
                if (scan_h_cnt == H_TOTAL - 1) begin
                    if (scan_v_cnt == V_TOTAL - 1) begin
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

    // image gen
    wire [7:0] current_pixel = (frame_counter < 8'd10) ? 8'h55 : //
        ((frame_counter < 8'd20) ? 8'haa : (
        ((frame_counter < 8'd30) ? 8'h55 : (
        ((frame_counter < 8'd40) ? 8'haa : (//
        (scan_h_cnt[1] ^ scan_v_cnt[3]) ? 8'h55 : 8'h00))))));

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
            
    /*assign epd_sd = (frame_counter < 8'd40) ? 16'h0055 : //
        ((frame_counter < 8'd80) ? 16'h00aa : ( //
        (scan_h_cnt[1] ^ scan_v_cnt[3]) ? 16'h0055 : 16'h00aa)); // pattern*/
    /*assign epd_sd = (frame_counter[2]) ? 16'h0055 : 16'h00aa;*/
    assign epd_sd = {8'd0, current_pixel};
    // stl
    assign epd_sdce0 = (scan_in_act) ? 1'b0 : 1'b1;
    assign epd_sdle = (scan_in_hsync) ? 1'b1 : 1'b0;
    assign epd_sdclk = (scan_in_hfp || scan_in_hsync || scan_in_hact) ? clk : 1'b0;
    
    assign bi_ready = 0;
    assign bo_pixel = 0;
    assign bo_valid = 0;
    
endmodule
