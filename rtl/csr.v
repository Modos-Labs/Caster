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
// csr.v
// Control/ status register over SPI
`default_nettype none
`timescale 1ns / 1ps
`include "defines.vh"
module csr(
    input wire clk,
    input wire rst,
    // SPI interface, already synced to clk domain
    input wire spi_cs,
    input wire spi_sck,
    input wire spi_mosi,
    output reg spi_miso,
    // CSR io
    output reg [5:0] csr_lut_frame,
    output reg [11:0] csr_lut_addr,
    output reg [7:0] csr_lut_wr,
    output reg csr_lut_we,
    output reg csr_osd_en,
    output reg [11:0] csr_osd_left,
    output reg [11:0] csr_osd_right,
    output reg [11:0] csr_osd_top,
    output reg [11:0] csr_osd_bottom,
    output reg [11:0] csr_osd_addr,
    output reg [7:0] csr_osd_wr,
    output reg csr_osd_we,
    output reg [11:0] csr_op_left,
    output reg [11:0] csr_op_right,
    output reg [11:0] csr_op_top,
    output reg [11:0] csr_op_bottom,
    output reg [7:0] csr_op_param,
    output reg [7:0] csr_op_length,
    output reg [7:0] csr_op_cmd,
    output reg csr_op_en,
    output reg csr_en,
    output reg [7:0] csr_cfg_vfp,
    output reg [7:0] csr_cfg_vsync,
    output reg [7:0] csr_cfg_vbp,
    output reg [11:0] csr_cfg_vact,
    output reg [7:0] csr_cfg_hfp,
    output reg [7:0] csr_cfg_hsync,
    output reg [7:0] csr_cfg_hbp,
    output reg [11:0] csr_cfg_hact,
    output reg [23:0] csr_cfg_fbytes,
    output reg [1:0] csr_cfg_mindrv,
    // Status input
    input wire sys_ready,
    input wire mig_error,
    input wire mif_error,
    input wire op_busy,
    input wire op_queue,
    // Debug
    output wire dbg_spi_req_wen,
    output wire [7:0] dbg_spi_req_addr,
    output wire [7:0] dbg_spi_req_wdata
    );

    // Uses SPI mode 3: clock high on idle,
    // data driven at negedge, sample at posedge

    // RW access
    // Byte 0: address
    // Byte 1+: data

    reg last_sck;
    reg [0:0] spi_state;
    reg [2:0] bit_counter;
    reg [6:0] spi_rx;
    reg [7:0] spi_tx;

    wire [7:0] spi_rx_next = {spi_rx[6:0], spi_mosi};

    reg [7:0] spi_req_addr;
    reg spi_req_ren;
    reg spi_req_wen;
    wire [7:0] spi_req_rdata;
    reg [7:0] spi_req_wdata;
    wire spi_autoinc;
    
    assign dbg_spi_req_wen = spi_req_wen;
    assign dbg_spi_req_addr = spi_req_addr;
    assign dbg_spi_req_wdata = spi_req_wdata;

    localparam SPI_ADDR_PHASE = 1'd0;
    localparam SPI_DATA_PHASE = 1'd1;

    always @(posedge clk) begin
        last_sck <= spi_sck;
        // Requested a read before, clear request and latch readout value
        if (spi_req_ren) begin
            spi_tx <= spi_req_rdata;
        end
        if (spi_req_wen && spi_autoinc) begin
            spi_req_addr <= spi_req_addr + 1;
        end
        spi_req_ren <= 1'b0;
        spi_req_wen <= 1'b0;
        if (spi_cs == 1'b1) begin
            // Not selected, reset
            bit_counter <= 3'd0;
            spi_state <= SPI_ADDR_PHASE;
            spi_tx <= 8'hff;
        end
        else if (!last_sck && spi_sck) begin
            // SCK posedge
            spi_rx <= spi_rx_next[6:0];
            bit_counter <= bit_counter + 1;
            if (bit_counter == 3'd7) begin
                case (spi_state)
                SPI_ADDR_PHASE: begin
                    spi_req_addr <= spi_rx_next;
                    spi_req_ren <= 1'b1;
                    spi_state <= SPI_DATA_PHASE;
                end
                SPI_DATA_PHASE: begin
                    spi_req_wdata <= spi_rx_next;
                    spi_req_wen <= 1'b1;
                end
                endcase
            end
        end
        else if (last_sck && !spi_sck) begin
            // SCK negedge
            spi_miso <= spi_tx[7];
            spi_tx <= {spi_tx[6:0], 1'b0};
        end

        if (rst) begin
            last_sck <= 1'b0;
            spi_req_ren <= 1'b0;
            spi_req_wen <= 1'b0;
            spi_state <= SPI_ADDR_PHASE;
        end
    end

    assign spi_req_rdata =
        (spi_req_addr == `CSR_STATUS) ?
            {mig_error, mif_error, sys_ready, op_busy, op_queue, 2'd0, csr_en} :
        (spi_req_addr == `CSR_ID0) ? 8'h35 :
        8'd0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            csr_lut_frame <= 6'd38; // Needs to match default waveform
            csr_lut_we <= 1'b0;
            csr_op_en <= 1'b0;
            csr_osd_en <= 1'b0;
            `ifdef CSR_SELFBOOT
            csr_en <= 1'b1;
            csr_cfg_vfp <= `DEFAULT_VFP;
            csr_cfg_vsync <= `DEFAULT_VSYNC;
            csr_cfg_vbp <= `DEFAULT_VBP;
            csr_cfg_vact <= `DEFAULT_VACT;
            csr_cfg_hfp <= `DEFAULT_HFP;
            csr_cfg_hsync <= `DEFAULT_HSYNC;
            csr_cfg_hbp <= `DEFAULT_HBP;
            csr_cfg_hact <= `DEFAULT_HACT;
            csr_cfg_fbytes <= `DEFAULT_FBYTES;
            csr_cfg_mindrv <= `DEFAULT_MINDRV;
            `else
            csr_en <= 1'b0;
            `endif
        end
        else begin
            // External write address increment
            if (csr_lut_we) begin
                csr_lut_we <= 1'b0;
                csr_lut_addr <= csr_lut_addr + 'd1;
            end
            if (csr_osd_we) begin
                csr_osd_we <= 1'b0;
                csr_osd_addr <= csr_osd_addr + 'd1;
            end
            csr_op_en <= 1'b0;
            if (spi_req_wen) begin
                case (spi_req_addr)
                `CSR_LUT_FRAME: csr_lut_frame <= spi_req_wdata[5:0];
                `CSR_LUT_ADDR_HI: csr_lut_addr[11:8] <= spi_req_wdata[3:0];
                `CSR_LUT_ADDR_LO: csr_lut_addr[7:0] <= spi_req_wdata;
                `CSR_LUT_WR: begin
                    csr_lut_wr <= spi_req_wdata;
                    csr_lut_we <= 1'b1;
                end
                `CSR_OP_LEFT_HI: csr_op_left[11:8] <= spi_req_wdata[3:0];
                `CSR_OP_LEFT_LO: csr_op_left[7:0] <= spi_req_wdata;
                `CSR_OP_RIGHT_HI: csr_op_right[11:8] <= spi_req_wdata[3:0];
                `CSR_OP_RIGHT_LO: csr_op_right[7:0] <= spi_req_wdata;
                `CSR_OP_TOP_HI: csr_op_top[11:8] <= spi_req_wdata[3:0];
                `CSR_OP_TOP_LO: csr_op_top[7:0] <= spi_req_wdata;
                `CSR_OP_BOTTOM_HI: csr_op_bottom[11:8] <= spi_req_wdata[3:0];
                `CSR_OP_BOTTOM_LO: csr_op_bottom[7:0] <= spi_req_wdata;
                `CSR_OP_PARAM: csr_op_param <= spi_req_wdata;
                `CSR_OP_LENGTH: csr_op_length <= spi_req_wdata;
                `CSR_OP_CMD: begin
                    csr_op_cmd <= spi_req_wdata;
                    csr_op_en <= 1'b1;
                end
                `CSR_ENABLE: csr_en <= spi_req_wdata[0];
                `CSR_CFG_V_FP: csr_cfg_vfp <= spi_req_wdata;
                `CSR_CFG_V_SYNC: csr_cfg_vsync <= spi_req_wdata;
                `CSR_CFG_V_BP: csr_cfg_vbp <= spi_req_wdata;
                `CSR_CFG_V_ACT_HI: csr_cfg_vact[11:8] <= spi_req_wdata[3:0];
                `CSR_CFG_V_ACT_LO: csr_cfg_vact[7:0] <= spi_req_wdata;
                `CSR_CFG_H_FP: csr_cfg_hfp <= spi_req_wdata;
                `CSR_CFG_H_SYNC: csr_cfg_hsync <= spi_req_wdata;
                `CSR_CFG_H_BP: csr_cfg_hbp <= spi_req_wdata;
                `CSR_CFG_H_ACT_HI: csr_cfg_hact[11:8] <= spi_req_wdata[3:0];
                `CSR_CFG_H_ACT_LO: csr_cfg_hact[7:0] <= spi_req_wdata;
                `CSR_CFG_FBYTES_B2: csr_cfg_fbytes[23:16] <= spi_req_wdata;
                `CSR_CFG_FBYTES_B1: csr_cfg_fbytes[15:8] <= spi_req_wdata;
                `CSR_CFG_FBYTES_B0: csr_cfg_fbytes[7:0] <= spi_req_wdata;
                `CSR_CFG_MINDRV: csr_cfg_mindrv <= spi_req_wdata[1:0];
                `CSR_OSD_EN: csr_osd_en <= spi_req_wdata[0];
                `CSR_OSD_LEFT_HI: csr_osd_left[11:8] <= spi_req_wdata[3:0];
                `CSR_OSD_LEFT_LO: csr_osd_left[7:0] <= spi_req_wdata;
                `CSR_OSD_RIGHT_HI: csr_osd_right[11:8] <= spi_req_wdata[3:0];
                `CSR_OSD_RIGHT_LO: csr_osd_right[7:0] <= spi_req_wdata;
                `CSR_OSD_TOP_HI: csr_osd_top[11:8] <= spi_req_wdata[3:0];
                `CSR_OSD_TOP_LO: csr_osd_top[7:0] <= spi_req_wdata;
                `CSR_OSD_BOTTOM_HI: csr_osd_bottom[11:8] <= spi_req_wdata[3:0];
                `CSR_OSD_BOTTOM_LO: csr_osd_bottom[7:0] <= spi_req_wdata;
                `CSR_OSD_ADDR_HI: csr_osd_addr[11:8] <= spi_req_wdata[3:0];
                `CSR_OSD_ADDR_LO: csr_osd_addr[7:0] <= spi_req_wdata;
                `CSR_OSD_WR: begin
                    csr_osd_wr <= spi_req_wdata;
                    csr_osd_we <= 1'b1;
                end
                default: begin
                    // no op
                end
                endcase
            end
        end
    end

    assign spi_autoinc =
        (spi_req_addr != `CSR_LUT_WR) &&
        (spi_req_addr != `CSR_OSD_WR) &&
        (spi_req_addr != `CSR_OP_CMD);

endmodule
`default_nettype wire
