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
    // New image Input, 2 pix per clock
    input  wire         vin_vsync,
    input  wire         vin_hsync,
    input  wire         vin_de,
    input  wire [31:0]  vin_pixel,
    // Framebuffer input
    // 16 bit per pixel for state
    input  wire [31:0]  bi_pixel,
    input  wire         bi_valid,
    output wire         bi_ready,
    // Framebuffer output
    output wire [31:0]  bo_pixel,
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
    localparam PRESCAN = 47;
    localparam V_ACTIVE = 600;
    localparam V_OVERSCAN = 1;
    localparam V_TOTAL = V_ACTIVE + V_OVERSCAN;
    localparam H_FP = 2;
    localparam H_ACTIVE = 800;
    localparam H_BP = 2;
    localparam H_TOTAL = H_FP + H_ACTIVE + H_BP;
    localparam H_DUTY = 800;

    // Output logic
    localparam SCAN_IDLE = 3'd0;
    localparam SCAN_START = 3'd1;
    localparam SCAN_ROW_START = 3'd2;
    localparam SCAN_ROW_DATA = 3'd3;
    localparam SCAN_ROW_END = 3'd4;
    
    reg [1:0] pixclk_div;
    always @(posedge clk)
        pixclk_div <= pixclk_div + 2'd1;
    wire pclk = pixclk_div == 2'b11;

    reg [10:0] scan_v_cnt;
    reg [10:0] scan_h_cnt;
    
    // Temp
    reg [5:0] frame_counter;

    reg [2:0] scan_state;
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
                if (frame_counter <= 6'd20) begin
                    scan_state <= SCAN_START;
                    frame_counter <= frame_counter + 1;
                end
                scan_h_cnt <= 0;
                scan_v_cnt <= 0;
            end
            SCAN_START: begin
                if (scan_h_cnt == PRESCAN) begin
                    scan_state <= SCAN_ROW_START;
                    scan_h_cnt <= 0;
                end
                else begin
                    scan_h_cnt <= scan_h_cnt + 1;
                end
            end
            SCAN_ROW_START: begin
                if (scan_h_cnt == H_FP) begin
                    scan_state <= SCAN_ROW_DATA;
                    scan_h_cnt <= 0;
                end
                else begin
                    scan_h_cnt <= scan_h_cnt + 1;
                end 
            end
            SCAN_ROW_DATA: begin
                if (scan_h_cnt == H_ACTIVE) begin
                    scan_state <= SCAN_ROW_END;
                    scan_h_cnt <= 0;
                end
                else begin
                    scan_h_cnt <= scan_h_cnt + 1;
                end 
            end
            SCAN_ROW_END: begin
                if (scan_h_cnt == H_BP) begin
                    if (scan_v_cnt == V_TOTAL) begin
                        scan_state <= SCAN_IDLE;
                    end
                    else begin
                        scan_state <= SCAN_ROW_START;
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
    
    // mode
    assign epd_gdoe = (scan_state == SCAN_IDLE) ? 1'b0 : 1'b1;
    // ckv
    assign epd_gdclk = 
            (scan_state == SCAN_START) ? (scan_h_cnt[3]) : (
            (scan_state == SCAN_ROW_END) ? (scan_h_cnt[1]) : (
            (scan_state == SCAN_IDLE) ? (1'b0) : (1'b1)));
    // spv
    assign epd_gdsp =
            (scan_state == SCAN_START) ? (!scan_h_cnt[4]) : (1'b1);
    assign epd_sdoe = (scan_state == SCAN_ROW_DATA) ? 
            (scan_h_cnt < H_DUTY) : (1'b0);
    assign epd_sd = 16'h00aa;
    // stl
    assign epd_sdce0 = (scan_state == SCAN_ROW_DATA) ? 1'b0 : 1'b1;
    assign epd_sdle = (scan_state == SCAN_ROW_START) ? (!scan_h_cnt[1]) : (1'b0);
    assign epd_sdclk = pixclk_div[1];
    
    assign bi_ready = 0;
    assign bo_pixel = 0;
    assign bo_valid = 0;
    
endmodule
