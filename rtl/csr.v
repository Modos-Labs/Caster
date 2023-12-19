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
    output reg [5:0] csr_lutframe,
    output reg [11:0] csr_lutaddr,
    output reg [7:0] csr_lutwr,
    output reg csr_lutwe,
    output reg [11:0] csr_opleft,
    output reg [11:0] csr_opright,
    output reg [11:0] csr_optop,
    output reg [11:0] csr_opbottom,
    output reg [7:0] csr_opparam,
    output reg [7:0] csr_oplength,
    output reg [7:0] csr_opcmd,
    output reg csr_ope,
    output reg [7:0] csr_cfg_vfp,
    output reg [7:0] csr_cfg_vsync,
    output reg [7:0] csr_cfg_vbp,
    output reg [11:0] csr_cfg_vact,
    output reg [7:0] csr_cfg_hfp,
    output reg [7:0] csr_cfg_hsync,
    output reg [7:0] csr_cfg_hbp,
    output reg [11:0] csr_cfg_hact,
    output reg [23:0] csr_cfg_fbytes,
    output reg csr_ctrl_en,
    // Status input
    input wire sys_ready,
    input wire mig_error,
    input wire mif_error,
    input wire op_busy,
    input wire op_queue
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
        (spi_req_addr == `CSR_CONTROL) ?
            {mig_error, mif_error, sys_ready, op_busy, op_queue, 2'd0, csr_ctrl_en} :
        8'd0;

    always @(posedge clk) begin
        csr_lutwe <= 1'b0;
        csr_ope <= 1'b0;
        if (spi_req_wen) begin
            case (spi_req_addr)
            `CSR_LUT_FRAME: csr_lutframe <= spi_req_wdata[5:0];
            `CSR_LUT_ADDR_HI: csr_lutaddr[11:8] <= spi_req_wdata[3:0];
            `CSR_LUT_ADDR_LO: csr_lutaddr[7:0] <= spi_req_wdata;
            `CSR_LUT_WR: begin
                csr_lutwr <= spi_req_wdata;
                csr_lutwe <= 1'b1;
            end
            `CSR_OP_LEFT_HI: csr_opleft[11:8] <= spi_req_wdata[3:0];
            `CSR_OP_LEFT_LO: csr_opleft[7:0] <= spi_req_wdata;
            `CSR_OP_RIGHT_HI: csr_opright[11:8] <= spi_req_wdata[3:0];
            `CSR_OP_RIGHT_LO: csr_opright[7:0] <= spi_req_wdata;
            `CSR_OP_TOP_HI: csr_optop[11:8] <= spi_req_wdata[3:0];
            `CSR_OP_TOP_LO: csr_optop[7:0] <= spi_req_wdata;
            `CSR_OP_BOTTOM_HI: csr_opbottom[11:8] <= spi_req_wdata[3:0];
            `CSR_OP_BOTTOM_LO: csr_opbottom[7:0] <= spi_req_wdata;
            `CSR_OP_PARAM: csr_opparam <= spi_req_wdata;
            `CSR_OP_LENGTH: csr_oplength <= spi_req_wdata;
            `CSR_OP_CMD: begin
                csr_opcmd <= spi_req_wdata;
                csr_ope <= 1'b1;
            end
            `CSR_CONTROL: begin
                csr_ctrl_en <= 1'b1;
            end
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
            default: begin
                // no op
            end
            endcase
        end
        if (rst) begin
            csr_lutframe <= 6'd38; // Needs to match default waveform
            csr_lutwe <= 1'b0;
            csr_ope <= 1'b0;
            csr_ctrl_en <= 1'b0;
        end
    end

    assign spi_autoinc = (spi_req_addr != `CSR_LUT_WR) && (spi_req_addr != `CSR_OP_CMD);

endmodule
`default_nettype wire
