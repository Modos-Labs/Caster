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
    output reg [7:0] csr_opcmd,
    output reg csr_ope
    );

    // Uses SPI mode 3: clock high on idle,
    // data driven at negedge, sample at posedge

    // RW access
    // Byte 0: address
    // Byte 1+: data

    reg last_sck;
    reg [1:0] spi_state;
    reg [2:0] bit_counter;
    reg [7:0] spi_rx;
    reg [7:0] spi_tx;

    wire [7:0] spi_rx_next = {spi_rx[6:0], spi_mosi};
    
    reg [7:0] spi_req_addr;
    reg spi_req_ren;
    reg spi_req_wen;
    wire [7:0] spi_req_rdata;
    reg [7:0] spi_req_wdata;
    wire spi_autoinc;

    localparam SPI_IDLE = 2'd0;
    localparam SPI_ADDR_PHASE = 2'd1;
    localparam SPI_DATA_PHASE = 2'd2;

    localparam CSR_LUTFRAME = 8'd0;
    localparam CSR_LUTADDR_HI = 8'd1;
    localparam CSR_LUTADDR_LO = 8'd2;
    localparam CSR_LUTWR = 8'd3;
    localparam CSR_OPLEFT_HI = 8'd4;
    localparam CSR_OPLEFT_LO = 8'd5;
    localparam CSR_OPRIGHT_HI = 8'd6;
    localparam CSR_OPRIGHT_LO = 8'd7;
    localparam CSR_OPTOP_HI = 8'd8;
    localparam CSR_OPTOP_LO = 8'd9;
    localparam CSR_OPBOTTOM_HI = 8'd10;
    localparam CSR_OPBOTTOM_LO = 8'd11;
    localparam CSR_OPPARAM = 8'd12;
    localparam CSR_OPCMD = 8'd13;

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
            spi_rx <= spi_rx_next;
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
            spi_state <= SPI_IDLE;
        end
    end

    assign spi_req_rdata = 8'h00; // Nothing to be read out yet

    always @(posedge clk) begin
        csr_lutwe <= 1'b0;
        csr_ope <= 1'b0;
        if (spi_req_wen) begin
            case (spi_req_addr)
            CSR_LUTFRAME: csr_lutframe <= spi_req_wdata[5:0];
            CSR_LUTADDR_HI: csr_lutaddr[11:8] <= spi_req_wdata[3:0];
            CSR_LUTADDR_LO: csr_lutaddr[7:0] <= spi_req_wdata;
            CSR_LUTWR: begin
                csr_lutwr <= spi_req_wdata;
                csr_lutwe <= 1'b1;
            end
            CSR_OPLEFT_HI: csr_opleft[11:8] <= spi_req_wdata[3:0];
            CSR_OPLEFT_LO: csr_opleft[7:0] <= spi_req_wdata;
            CSR_OPRIGHT_HI: csr_opright[11:8] <= spi_req_wdata[3:0];
            CSR_OPRIGHT_LO: csr_opright[7:0] <= spi_req_wdata;
            CSR_OPTOP_HI: csr_optop[11:8] <= spi_req_wdata[3:0];
            CSR_OPTOP_LO: csr_optop[7:0] <= spi_req_wdata;
            CSR_OPBOTTOM_HI: csr_opbottom[11:8] <= spi_req_wdata[3:0];
            CSR_OPBOTTOM_LO: csr_opbottom[7:0] <= spi_req_wdata;
            CSR_OPPARAM: csr_opparam <= spi_req_wdata;
            CSR_OPCMD: begin
                csr_opcmd <= spi_req_wdata;
                csr_ope <= 1'b1;
            end
            endcase
        end
        if (rst) begin
            csr_lutframe <= 6'd38; // Needs to match default waveform
            csr_lutwe <= 1'b0;
            csr_ope <= 1'b0;
        end
    end

    assign spi_autoinc = (spi_req_addr != CSR_LUTWR) && (spi_req_addr != CSR_OPCMD);

endmodule
`default_nettype wire
